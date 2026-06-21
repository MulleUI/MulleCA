//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "CAAnimationSequence.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CAAnimation+DebugPrivate.h"


@interface CAAnimation( Private)

- (void) willStartAnimating;
- (BOOL) didEnd;

- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) time
                   animationRate:(mulle_relativetime_t) animationRate;

- (struct mulle_relativetimerange *) relativeTimeRange;
- (float) repeatCount;

@end


static inline mulle_relativetime_t
   CAAnimationSequenceTotalDuration( CAAnimation *animation)
{
   struct mulle_relativetimerange   *relative;

   relative = [animation relativeTimeRange];
   return( relative->duration * [animation repeatCount]);
}


static inline mulle_relativetime_t
   CAAnimationSequenceEndTime( CAAnimation *animation)
{
   struct mulle_relativetimerange   *relative;

   relative = [animation relativeTimeRange];
   return( relative->delay + relative->duration * [animation repeatCount]);
}


@implementation CAAnimationSequence

+ (instancetype) sequenceAnimation
{
   return( [[[self alloc] initWithAnimationOptions:NULL] autorelease]);
}


- (id) initWithAnimationOptions:(struct CAAnimationOptions *) options
{
   self = [super initWithAnimationOptions:options];
   if( self)
      [self initAnimationStorage];
   return( self);
}


- (void) dealloc
{
   [self removeAllAnimations];
   [self deallocAnimationStorage];

   MulleObjCObjectSetDuplicatedUTF8String( self, &_animationID, NULL);
   [super dealloc];
}


- (struct CAAnimationStorage *) animationStorage
{
   return( &_animationStorage);
}


- (void) setAnimationID:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_animationID, s);
}


- (char *) animationID
{
   return( _animationID);
}


- (BOOL) changesLayout
{
   return( [self hasLayoutChangingAnimations]);
}


- (mulle_relativetime_t) sequenceDuration
{
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;
   mulle_relativetime_t        maxEnd;
   mulle_relativetime_t        end;

   storage = [self animationStorage];
   maxEnd  = 0.0;

   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( ! animation)
         continue;
      end = CAAnimationSequenceEndTime( animation);
      if( end > maxEnd)
         maxEnd = end;
   }
   return( maxEnd);
}


- (void) addAnimation:(id <CAAnimation>) animation
{
    mulle_relativetime_t        sequenceEnd;
    struct CAAnimationStorage   *storage;

    sequenceEnd = [self sequenceDuration];

    [(CAAnimation *) animation relativeTimeRange]->delay = sequenceEnd;
    [(id) animation setRemovedOnCompletion:NO];

    storage = [self animationStorage];
    _mulle_pointerarray_add( &storage->_animations, [(id) animation retain]);
    storage->_numberOfAnimations++;

    CAAnimationLog( "addAnimation: delay=%.3f duration=%.3f seqDuration=%.3f",
                    sequenceEnd,
                    [(CAAnimation *) animation relativeTimeRange]->duration,
                    [self sequenceDuration]);
}


- (void) addPause:(mulle_relativetime_t) duration
{
   CAAnimation   *pause;

   pause = [[[CAAnimation alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, duration }, 0, 1.0, 0 }] autorelease];
   [self addAnimation:pause];
}


- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) now
                    animationRate:(mulle_relativetime_t) animationRate
{
    BOOL   flag;

    flag = [super animateWithAbsoluteTime:now
                          animationRate:animationRate];

    CAAnimationLogVerbose( "animateChildren: hasAnimations=%d", flag);

    return( flag);
}


- (void) insertAnimation:(id <CAAnimation>) animation
         beforeAnimation:(CAAnimation *) reference
{
   mulle_relativetime_t        insertionPoint;
   mulle_relativetime_t        shiftAmount;
   CAAnimation                 *other;
   struct CAAnimationStorage   *storage;

   insertionPoint = [reference relativeTimeRange]->delay;
   shiftAmount    = CAAnimationSequenceTotalDuration( (CAAnimation *) animation);

   // shift reference and everything at or after insertion point
   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, other)
   {
      if( [other relativeTimeRange]->delay >= insertionPoint)
         [other relativeTimeRange]->delay += shiftAmount;
   }

   // place new animation at insertion point
   [(CAAnimation *) animation relativeTimeRange]->delay = insertionPoint;

   _mulle_pointerarray_add( &storage->_animations, [(id) animation retain]);
   storage->_numberOfAnimations++;
}


- (void) insertAnimation:(id <CAAnimation>) animation
          afterAnimation:(CAAnimation *) reference
{
   mulle_relativetime_t        insertionPoint;
   mulle_relativetime_t        shiftAmount;
   CAAnimation                 *other;
   struct CAAnimationStorage   *storage;

   insertionPoint = CAAnimationSequenceEndTime( reference);
   shiftAmount    = CAAnimationSequenceTotalDuration( (CAAnimation *) animation);

   // shift everything after insertion point
   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, other)
   {
      if( [other relativeTimeRange]->delay >= insertionPoint)
         [other relativeTimeRange]->delay += shiftAmount;
   }

   // place new animation at insertion point
   [(CAAnimation *) animation relativeTimeRange]->delay = insertionPoint;

   _mulle_pointerarray_add( &storage->_animations, [(id) animation retain]);
   storage->_numberOfAnimations++;
}


- (void) removeAnimation:(id <CAAnimation>) animation
{
    struct CAAnimationStorage   *storage;
    uintptr_t                   index;
    unsigned int                n;
    mulle_relativetime_t        removedEnd;
    mulle_relativetime_t        shiftAmount;
    CAAnimation                 *other;

    storage = [self animationStorage];
    index   = _mulle_pointerarray_find( &storage->_animations, animation);
    if( index == mulle_not_found_e)
       return;

    // Close the gap: shift animations at or after removed animation's end
    removedEnd  = CAAnimationSequenceEndTime( (CAAnimation *) animation);
    shiftAmount = CAAnimationSequenceTotalDuration( (CAAnimation *) animation);

    mulle_pointerarray_for( &storage->_animations, other)
    {
       if( other && other != (CAAnimation *) animation)
          if( [other relativeTimeRange]->delay >= removedEnd)
             [other relativeTimeRange]->delay -= shiftAmount;
    }

    CAAnimationLog( "removeAnimation: %p remaining=%ld",
                    animation, (long) storage->_numberOfAnimations - 1);

    if( ! --storage->_numberOfAnimations)
       [self removeAllAnimations];
    else
    {
       [(id) animation autorelease];
       mulle_pointerarray_set( &storage->_animations, (unsigned int) index, NULL);

       n = _mulle_pointerarray_get_count( &storage->_animations);
       if( n >= 8 && n >= storage->_numberOfAnimations * 2)
          mulle_pointerarray_compact( &storage->_animations, NULL);
    }
}


#pragma mark - Animation driving


- (void) finish
{
   id <CAAnimation>            animation;
   struct CAAnimationStorage   *storage;

   [super finish];

   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      [animation finish];
   }
}


- (void) interrupt
{
   id <CAAnimation>            animation;
   struct CAAnimationStorage   *storage;

   [super interrupt];

   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      [animation interrupt];
   }
}


- (void) cancel
{
   id <CAAnimation>            animation;
   struct CAAnimationStorage   *storage;

   // cancel children in reverse order
   storage = [self animationStorage];
   mulle_pointerarray_for_reverse( &storage->_animations, animation)
   {
      if( animation)
         [animation cancel];
   }

   [super cancel];
}


- (void) animateObject:(id) object
    animationFrameInfo:(struct CAAnimationFrameInfo *) info
{
   MULLE_C_UNUSED( object);
   MULLE_C_UNUSED( info);
}


- (void) willStartAnimating
{
   [super willStartAnimating];

   if( isinf( _state.duration))
      _state.duration = [self sequenceDuration];
}


- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
    NSUInteger                  state;
    NSUInteger                  prevBits;
    NSUInteger                  prevIndex;
    mulle_absolutetime_t        virtualNow;
    mulle_relativetime_t        elapsed;
    id <CAAnimationDelegate>   savedDelegate;

    //
    // Suppress delegate during super call so we control ordering:
    //   willStart: group first, then children
    //   didStop:   children first, then group
    //
    savedDelegate = _delegate;
    _delegate     = nil;
    prevBits      = _state.bits;
    prevIndex     = _state.previousAnimationIndex;

    CAAnimationLogVerbose( "animate: now=%.3f bits=%lx", now, _state.bits);

    state = [super animateObject:self
                    absoluteTime:now
                   animationRate:animationRate];

    _delegate = savedDelegate;

    // Don't drive children if we haven't started yet (delay not reached)
    if( state == CAAnimationReturnStateActive)
       return( state);

    // Fire willStart BEFORE children (if it just transitioned)
    if( (prevBits ^ _state.bits) & CAAnimationDelegateWillStartNotified)
    {
       CAAnimationLog( "delegate willStart: %p", savedDelegate);
       [savedDelegate animationWillStart:self];
    }

    // On repeat edge, reset all children so they replay
    if( _repeatCount > 1.0 && _state.previousAnimationIndex > prevIndex)
       [self resetAllAnimations];

    // Compute virtual time within current cycle for children
    if( _repeatCount > 1.0 && _state.duration > 0 && ! isinf( _state.duration))
    {
       elapsed    = now - _state.start;
       virtualNow = _state.start + fmod( elapsed, _state.duration);
    }
    else
       virtualNow = now;

    // Drive children with virtual (wrapped) time
    [self animateWithAbsoluteTime:virtualNow
                    animationRate:animationRate];

    // Fire didStop AFTER children are done
    if( state == CAAnimationReturnStateDone)
    {
       CAAnimationLog( "delegate didStop: %p finished=%d",
                       savedDelegate,
                       (_state.bits & CAAnimationInterruptSignal) ? NO : YES);
       [savedDelegate animationDidStop:self
                              finished:(_state.bits & CAAnimationInterruptSignal) ? NO : YES];
    }

    return( state);
}


- (void) reset
{
   [self resetAllAnimations];
   [super reset];
}


- (void) mulleGainAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   [super mulleGainAccessWithUniquingSet:uniquing];
   [self mulleGainAccessToAnimationsWithUniquingSet:uniquing];
}


- (void) mulleRelinquishAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   [self mulleRelinquishAccessToAnimationsWithUniquingSet:uniquing];
   [super mulleRelinquishAccessWithUniquingSet:uniquing];
}

@end
