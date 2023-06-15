#define _GNU_SOURCE

#import "CAAnimation.h"

#import "CAAnimationGroup.h"

#import "import-private.h"
#include <assert.h>


#define ANIMATION_DEBUG


@interface CAAnimationGroup( Private)
// kinda private
- (void) animationWillStart:(CAAnimation *) animation;
- (void) animationDidStop:(CAAnimation *) animation;

@end


NS_OPTIONS_TABLE( CAAnimationBits, 15) = 
{
   NS_OPTIONS_ITEM( CAAnimationStarted),
   NS_OPTIONS_ITEM( CAAnimationAnimating),
   NS_OPTIONS_ITEM( CAAnimationScrubbing),
   NS_OPTIONS_ITEM( CAAnimationHasReversed),
   NS_OPTIONS_ITEM( CAAnimationIsReverse),
   NS_OPTIONS_ITEM( CAAnimationFinalized),
   NS_OPTIONS_ITEM( CAAnimationEnded),
   NS_OPTIONS_ITEM( CAAnimationPreempt),

   NS_OPTIONS_ITEM( CAAnimationDelegateDidStartNotified),

   NS_OPTIONS_ITEM( CAAnimationReverses),
   NS_OPTIONS_ITEM( CAAnimationReversesLate),
   NS_OPTIONS_ITEM( CAAnimationAdditive),
   NS_OPTIONS_ITEM( CAAnimationCumulative),
   NS_OPTIONS_ITEM( CAAnimationWrapToZero),

   NS_OPTIONS_ITEM( CAAnimationHasIntegerRepeat)
};



char  *CAAnimationOptionsUTF8String( struct CAAnimationOptions *options)
{
   if( ! options)
      return( "NULL");

   return( MulleObjC_asprintf( "{ timeRange: %s; repeatCount: %.1f bits: %s }",
               mulle_relativetimerange_utf8string( options->timeRange),
               options->repeatCount,
               CAAnimationBitsUTF8String( options->bits)));
}



@implementation CAAnimation

const struct CAAnimationOptions   CAAnimationDefaultOptions =
{
   { 0, 1 },      // 1 second starting immediately
   1.0,
   0
};


static inline void   resetAnimation( CAAnimation *self)
{
   self->_state.bits                          &= ~0xFFFF;
   self->_state.previousFrameTimestamp         = -INFINITY;
   self->_state.previousAnimationIndex         = 0;
   self->_state.previousNormalizedRelativeTime = 0.0;
}


- (void) setAnimationOptions:(struct CAAnimationOptions *) options
{
   // no need for super coz NSObject based
   if( ! options)
      options = (struct CAAnimationOptions *) &CAAnimationDefaultOptions;

   // reverses is only used if repeats is set
   assert( ! (options->bits & 0xFFFF));

   // standalone cumulative makes no sense
   assert( (options->bits & (CAAnimationAdditive|CAAnimationCumulative)) !=
           CAAnimationCumulative);

   self->_relative            = options->timeRange;
   self->_state.bits          = options->bits & ~0xFFFF;  // mask off our internal state bits
   self->_removedOnCompletion = YES;

   self->_repeatCount         = options->repeatCount <= 0.0 ? 1.0 : options->repeatCount;
   if( (NSInteger) self->_repeatCount == self->_repeatCount)
      self->_state.bits |= CAAnimationHasIntegerRepeat;
}


+ (instancetype) animationWithAnimationOptions:(struct CAAnimationOptions *) options
{
   return( [[[self alloc] initWithAnimationOptions:options] autorelease]);
}

// separated into two parameters, so animations can live without
// a group
- (id) initWithAnimationOptions:(struct CAAnimationOptions *) options
{
   if( options && options->timeRange.duration <= 0.0)
   {
      [self release];
      return( nil);
   }

   [self setAnimationOptions:options];
   resetAnimation( self);

   return( self);
}


- (id) init
{
   return( [self initWithAnimationOptions:NULL]);
}


- (id) copy
{
   CAAnimation  *clone;

   clone = NSCopyObject( self, 0, NULL);
   clone->_animationObject = nil;  // or what ?
   return( clone);
}


- (void) reverse
{
   if( ! (self->_state.bits & CAAnimationHasReversed))
      self->_state.bits |= CAAnimationHasReversed;

   self->_state.bits ^= CAAnimationIsReverse;
}


- (void) reset
{
   resetAnimation( self);
}


//
// this is called by the layer (ahem) animatableObject
// which does the animation now
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(mulle_relativetime_t) elapsed
{
   if( _animationFunction)
      (*_animationFunction)( self, object, t, elapsed);
}


// at the moment, if you call this
- (void) wasPreempted
{
   self->_state.bits |= CAAnimationEnded;
   [_delegate animationDidStop:self
                      finished:NO];
}


- (void) willStartAnimating
{
#ifdef ANIMATION_DEBUG
   MulleUILogThisMethod();
#endif
   self->_state.bits |= CAAnimationAnimating;
}


// returns YES, if really ended (reverse flag is confusing to me)
- (BOOL) didEnd
{
#ifdef ANIMATION_DEBUG
   MulleUILogThisMethod();
#endif

   // don't call callbacks if we are "scrubbing" (future)
   // also don't really end
   if( self->_state.bits & CAAnimationScrubbing)
      return( NO);

   self->_state.bits |= CAAnimationEnded;
   [_delegate animationDidStop:self
                      finished:YES];
   return( YES);
}


static inline CAAnimationState  stateReturn( CAAnimationState state)
{
#ifdef ANIMATION_DEBUG
   MulleUICLog( CAAnimationStateUTF8String( state));
#endif
   return( state);
}


- (NSUInteger) isAnimatingAtAbsoluteTime:(mulle_absolutetime_t) now
                           animationRate:(mulle_relativetime_t) animationRate
{
   if( self->_state.bits & CAAnimationEnded)
   {
      return( CAAnimationStateDone);
   }

   if( self->_state.bits & CAAnimationPreempt)
   {
      [self wasPreempted];
      return( CAAnimationStateDone);
   }

   if( ! (self->_state.bits & CAAnimationStarted))
   {
      if( animationRate == 0.0)
      {
         self->_state.start    = mulle_timeinterval_add( now, self->_relative.delay);
         self->_state.duration = self->_relative.duration;
      }
      else
      {
   // Should we start animating if not yet ? We round down here, so we may
   // start a/ little early in absolute time! if there is a delay
         self->_state.start    = mulle_timeinterval_add( now, self->_relative.delay) - (animationRate / 2.0);
         self->_state.duration = self->_relative.duration; // mulle_timeinterval_quantize( self->_relative.duration,
                                                           //   animationRate);
      }
      self->_state.bits       |= CAAnimationStarted;
   }

   if( now < self->_state.start)
      return( NO);

   if( ! (self->_state.bits & CAAnimationAnimating))
   {
      if( animationRate != 0.0)
         self->_state.start = now;  // set actual start to now
      [self willStartAnimating]; // will set CAAnimationAnimating
   }

   return( YES);
}




- (void) animationIndexDidChange
{
   // do nuthin
}


- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
   BOOL                   reverseIfNeeded;
   double                 corrected;
   double                 d;
   double                 maxValue;
   double                 midpoint;
   double                 minValue;
   double                 t;
   double                 value;
   mulle_relativetime_t   delta;
   mulle_relativetime_t   elapsedTime;
   NSUInteger             animationIndex;
   NSUInteger             frameIndex;
   NSUInteger             nextState;
   NSUInteger             reverseBits;

#ifdef ANIMATION_DEBUG
   MulleUILog( "_bits=%s; object=%#@ now=%.6f start=%.6f animationRate=%.6f",
                  CAAnimationBitsUTF8String( self->_state.bits), object, now, self->_state.start, animationRate);
#endif

   if( self->_state.bits & CAAnimationFinalized)
   {
      if( [self didEnd])
         return( stateReturn( CAAnimationStateDone));

      self->_state.bits &= ~CAAnimationFinalized;
   }

   // active but not yet animating ?
   if( ! [self isAnimatingAtAbsoluteTime:now
                           animationRate:animationRate])
      return( stateReturn( CAAnimationStateActive));

   // just some paranoia, in case someone messes with the clock
   if( now < self->_state.start)
      self->_state.start = now;

   elapsedTime = mulle_timeinterval_subtract( now, self->_state.start);

   // d is the number of animation cycles we are in (a float)
   d           = elapsedTime / self->_state.duration;
   nextState   = CAAnimationAnimating;

   // we need to reversecheck, if we crossed the duration boundary
   if( animationRate == 0.0)
   {
      corrected = fmod( d, 1.0);
//      if( d != 0.0 && corrected == 0.0 && ! (self->_state.bits & CAAnimationWrapToZero))
//         corrected = 1.0;
      assert( corrected >= 0.0 && corrected <= 1.0);

      if( d >= self->_repeatCount)
      {
         self->_state.bits |= CAAnimationFinalized;
         if( d > self->_repeatCount)
         {
            if( [self didEnd])
               return( stateReturn( CAAnimationStateDone));
         }
         nextState = CAAnimationStateFinalAnimation;
      }
   }
   else
   {
      minValue  = animationRate / 2 / self->_state.duration;
      assert( minValue >= 0.0 && minValue <= 1.0);
      maxValue  = 1.0 - minValue;

      //
      // instead of the true elapsed time, we "jitter" correct it
      // and to get a stable midpoint, by calculating off the ideal
      // frame elapsedTime
      //
      frameIndex = (NSUInteger) floor( elapsedTime / animationRate);
      midpoint   = (frameIndex * animationRate) + (animationRate / 2.0);
      value      = fmod( midpoint / self->_state.duration, 1.0);

      if( maxValue != 0.5)
         corrected = value + ((value - 0.5) / (maxValue - 0.5)) * minValue;
      else
         corrected = value;

      if( corrected < minValue)
         corrected = 0.0;
      if( corrected > maxValue)
         corrected = 1.0;
      assert( corrected >= 0.0 && corrected <= 1.0);

      if( ! (self->_state.bits & CAAnimationFinalized))
      {
         // check if we are in the last to be displayed frame
         if( (midpoint / self->_state.duration) >= self->_repeatCount)
         {
            self->_state.bits |= CAAnimationFinalized;
            nextState = CAAnimationStateFinalAnimation;
         }
      }
   }

   assert( nextState != CAAnimationStateDone);

   animationIndex  = (NSUInteger) floor( d);
   reverseIfNeeded = NO;

   if( nextState == CAAnimationStateFinalAnimation)
   {
      if( self->_state.bits & CAAnimationHasIntegerRepeat)
         corrected = 1.0; // round( corrected);  // down to 0 or up
      else
         corrected = fmod( self->_repeatCount, 1.0);
   }
   else
   {
      reverseBits     = self->_state.bits & (CAAnimationReversesLate|CAAnimationReverses);
      reverseIfNeeded = (animationIndex > self->_state.previousAnimationIndex);

      if( reverseIfNeeded)
      {
   //         [self animationIndexWillChange];
         if( reverseBits == CAAnimationReverses)
            [self reverse];
      }
   }

   if( animationIndex > self->_state.previousAnimationIndex)
      [self animationIndexDidChange];

   t     = (self->_state.bits & CAAnimationIsReverse)
               ? 1.0 - corrected
               : corrected;
   delta = now - (isinf( self->_state.previousFrameTimestamp)
                        ? now
                        : self->_state.previousFrameTimestamp
                       );

   [self animateObject:object
normalizedRelativeTime:t
           elapsedTime:delta];

   if( reverseIfNeeded)
   {
      if( reverseBits == (CAAnimationReversesLate|CAAnimationReverses))
         [self reverse];
   }

   self->_state.previousFrameTimestamp         = now;
   self->_state.previousAnimationIndex         = animationIndex;
   self->_state.previousNormalizedRelativeTime = t;

#ifdef ANIMATION_DEBUG
   MulleUILog( "d=%.6f t=%.6f elapsedTime=%.6f", d, t, elapsedTime);
#endif

   if( ! (self->_state.bits & CAAnimationDelegateDidStartNotified))
   {
      self->_state.bits |= CAAnimationDelegateDidStartNotified;
      [_delegate animationDidStart:self];
   }

   return( stateReturn( nextState));
}


- (BOOL) hasEnded
{
   return( (_state.bits & CAAnimationEnded) ? YES : NO);
}


static BOOL   performSelectorOnObjects( struct mulle_pointerarray *objects,
                                        SEL sel,
                                        mulle_absolutetime_t renderTime,
                                        mulle_absolutetime_t animationRate)
{
   struct mulle_pointerarrayenumerator   rover;
   id                                    object;
   NSUInteger                            state;

   state = CAAnimationStateDone;
   assert( ! state);

   rover = mulle_pointerarray_enumerate( objects);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &object))
      state |= (NSUInteger) MulleObjCObjectPerformSelectorDoubleArgument2( object,
                                                                           sel,
                                                                           renderTime,
                                                                           animationRate);
   mulle_pointerarrayenumerator_done( &rover);

   return (state != CAAnimationStateDone);
}


+ (BOOL) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(mulle_absolutetime_t) renderTime
          animationRate:(mulle_relativetime_t) animationRate
{
   BOOL   flag;

   flag = performSelectorOnObjects( objects,
                                    @selector( animateWithAbsoluteTime:animationRate:),
                                    renderTime,
                                    animationRate);
   return( flag);
}

@end
