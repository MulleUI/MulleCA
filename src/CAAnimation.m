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

static char  *CAAnimationBitCString( NSUInteger bit)
{
   switch( bit)
   {
   case CAAnimationStarted     : return( "CAAnimationStarted");
   case CAAnimationAnimating   : return( "CAAnimationAnimating");
   case CAAnimationScrubbing   : return( "CAAnimationScrubbing");
   case CAAnimationHasReversed : return( "CAAnimationHasReversed");
   case CAAnimationIsReverse   : return( "CAAnimationIsReverse");
   case CAAnimationEnded       : return( "CAAnimationEnded");
   case CAAnimationPreempt     : return( "CAAnimationPreempt");
   case CAAnimationDelegateDidStartNotified : return( "CAAnimationDelegateDidStartNotified");
   case CAAnimationReverses    : return( "CAAnimationReverses");
   case CAAnimationAdditive    : return( "CAAnimationAdditive");
   case CAAnimationCumulative  : return( "CAAnimationCumulative");
   case CAAnimationHasIntegerRepeat : return( "CAAnimationHasIntegerRepeat");
   }
   return( "???");
}


static NSUInteger  CAAnimationBits[] =
{
   // internal state, can't be set
   CAAnimationStarted,    // animation active, but possibly delayed
   CAAnimationAnimating,    // passed delay, now doing something
   CAAnimationScrubbing,    // future
   CAAnimationHasReversed,
   CAAnimationIsReverse,
   CAAnimationEnded,
   CAAnimationPreempt,   // signal preemption
   CAAnimationDelegateDidStartNotified,

   // user options
   CAAnimationReverses,
   CAAnimationAdditive,
   CAAnimationCumulative,

   CAAnimationHasIntegerRepeat
};


char   *CAAnimationBitsUTF8String( NSUInteger bits)
{
   struct mulle_buffer   buffer;
   char                  *s;
   NSUInteger            i;
   auto char             tmp[ 256];

   mulle_buffer_init_with_static_bytes( &buffer, tmp, sizeof( tmp), NULL);

   for( i = 0; i < sizeof( CAAnimationBits) / sizeof( NSUInteger); i++)
   {
      if( bits & CAAnimationBits[ i])
      {
         mulle_buffer_add_string_if_not_empty( &buffer, "|");
         mulle_buffer_add_string( &buffer, CAAnimationBitCString( CAAnimationBits[ i]));
      }
   }

   mulle_buffer_add_string_if_empty( &buffer, "0");

   s = mulle_buffer_extract_string( &buffer);
   mulle_buffer_done( &buffer);

   return( MulleObjCAutoreleaseAllocation( s, NULL));
}


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


static inline enum CAAnimationState  stateReturn( enum CAAnimationState state)
{
#ifdef ANIMATION_DEBUG
   MulleUICLog( CAAnimationStateUTF8String( state));
#endif
   return( state);
}

static inline double   elapsedAnimations( mulle_absolutetime_t now,
                                          mulle_absolutetime_t start,
                                          mulle_relativetime_t duration)
{
   mulle_relativetime_t   diff;
   double                 t;

   diff = mulle_timeinterval_subtract( now, start);
   t    = diff / duration;  // can be larger than 1 here
   return( t);
}


static inline double   normalizedAnimationTime( double d)
{
   double   t;

   assert( d >= 0.0);

   t = fmod( d, 1.0);

   // don't "mod" to 0.0 but to 1.0 instead, except if we are at the start
   if( d != 0.0 && t == 0.0)
      return( 1.0);

   return( t);
}


- (NSUInteger) isAnimatingAtAbsoluteTime:(mulle_absolutetime_t) now
                           animationRate:(mulle_relativetime_t) animationRate
{
   mulle_relativetime_t   t;
   mulle_relativetime_t   diff;
   mulle_relativetime_t   duration;
   NSUInteger             nFrames;

   if( self->_state.bits & CAAnimationEnded)
   {
      return( CAAnimationStateDone);
   }

   if( self->_state.bits & CAAnimationPreempt)
   {
      [self wasPreempted];
      return( CAAnimationStateDone);
   }

   // turn animation time into absolute
   //
   // So lets say we want a duration of 0.5s for our animation, but the animation
   // rate is 3Hz (1/3) that means we stop at 0.3333s and then 0.6666s actually.
   // Question: should duration be rounded up, down or should there even be
   // a dither to sometimes round up and sometimes round down, so durations
   // statistically even out ?
   // Use mulle_timeinterval_quantize to find nearest spot.

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
         self->_state.duration = mulle_timeinterval_quantize( self->_relative.duration,
                                                              animationRate);
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


- (NSUInteger) animationStateForElapsedAnimations:(double) d
                                    animationRate:(mulle_relativetime_t) animationRate
{
   double   lower;

   if( animationRate == 0.0)
   {
      if( d <= self->_repeatCount)
         return( CAAnimationAnimating);
   }
   else
   {
      // a_2  r d
      // |    | |
      if( d < self->_repeatCount)
         return( CAAnimationAnimating);

      if( ! (self->_state.bits & CAAnimationFinalized))
      {
         self->_state.bits |= CAAnimationFinalized;
         return( CAAnimationStateFinalAnimation);
      }
   }

   // common code for the end of the animation
   return( [self didEnd] ? CAAnimationStateDone
                         : CAAnimationStateFinalAnimation);
}


- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
   double                 d;
   mulle_relativetime_t   t;
   mulle_relativetime_t   elapsedTime;
   mulle_absolutetime_t   previousFrameTimestamp;
   NSUInteger             animationIndex;
   NSUInteger             nextState;

#ifdef ANIMATION_DEBUG
   MulleUILog( "_bits=%s; object=%#@ now=%.6f start=%.6f animationRate=%.6f",
                  CAAnimationBitsUTF8String( self->_state.bits), object, now, self->_state.start, animationRate);
#endif

   if( ! [self isAnimatingAtAbsoluteTime:now
                           animationRate:animationRate])
      return( stateReturn( CAAnimationStateActive));

   d = elapsedAnimations( now, self->_state.start, self->_state.duration);

   // figure out if we are past the last animation, or that we should
   // animate one more time, or we are just in the thick of things
   nextState = [self animationStateForElapsedAnimations:d
                                          animationRate:animationRate];
   if( nextState == CAAnimationStateDone)
      return( stateReturn( nextState));

   t = normalizedAnimationTime( d);
      // if we passed a "duration" boundary, we might need to reverse.
   animationIndex = (NSUInteger) d;

   if( nextState == CAAnimationStateFinalAnimation)
   {
      //
      // we really want to hit 1.0, if we are within half of the animationRate
      // If animationRate is 0.0, this will rarely happen, which is OK
      //
      if( (self->_state.bits & CAAnimationHasIntegerRepeat) &&
           d + animationRate / 2 >= self->_repeatCount)
      {
         t = 1.0;
      }
   }
   else
   {
      if( animationIndex > self->_state.previousAnimationIndex)
      {
         if( self->_state.bits & CAAnimationReverses)
         {
            [self reverse];

            // this irks me but fixes a test :/
            if( t == 1.0)
               t = 0.0;
         }
      }
   }

   if( self->_state.bits & CAAnimationIsReverse)
      t = 1.0 - t;

   elapsedTime = now - (isinf( self->_state.previousFrameTimestamp)
                        ? now
                        : self->_state.previousFrameTimestamp
                       );

   [self animateObject:object
normalizedRelativeTime:t // must be 0.0 to 1.0
           elapsedTime:elapsedTime];

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


