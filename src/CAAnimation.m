#define _GNU_SOURCE

#import "CAAnimation.h"

#import "CAAnimation+DebugPrivate.h"
#import "CAAnimationGroup.h"

#import "import-private.h"
#include <assert.h>


//#define ANIMATION_DEBUG


@interface CAAnimationGroup( Private)
// kinda private
- (void) animationWillStart:(CAAnimation *) animation;
- (void) animationDidStop:(CAAnimation *) animation;

@end


NS_OPTIONS_TABLE( CAAnimationBits, 18) =
{
   NS_OPTIONS_ITEM( CAAnimationStarted),
   NS_OPTIONS_ITEM( CAAnimationAnimating),
   NS_OPTIONS_ITEM( CAAnimationScrubbing),
   NS_OPTIONS_ITEM( CAAnimationHasReversed),
   NS_OPTIONS_ITEM( CAAnimationIsReverse),
   NS_OPTIONS_ITEM( CAAnimationFinalized),
   NS_OPTIONS_ITEM( CAAnimationEnded),
   NS_OPTIONS_ITEM( CAAnimationPreempt),
// 8
   NS_OPTIONS_ITEM( CAAnimationDelegateWillStartNotified),
   NS_OPTIONS_ITEM( CAAnimationDelegateDidStartNotified),

// 10
   NS_OPTIONS_ITEM( CAAnimationReverses),
   NS_OPTIONS_ITEM( CAAnimationQuantize),
   NS_OPTIONS_ITEM( CAAnimationAdditive),
   NS_OPTIONS_ITEM( CAAnimationCumulative),
   NS_OPTIONS_ITEM( CAAnimationRateCorrect),

// 15
   NS_OPTIONS_ITEM( CAAnimationHasIntegerRepeat),
   NS_OPTIONS_ITEM( CAAnimationStickyArrayCenter),
   NS_OPTIONS_ITEM( CAAnimationStickyArrayEnd)
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

- (BOOL) __isCAAnimation
{
   return( YES);
}


static struct
{
   NSUInteger   _debugEnabled;
} Self;


+ (void) initialize
{
   char   *s;

   s = getenv( "CAAnimationDebugEnabled");
   if( s)
      Self._debugEnabled = strtol( s, NULL, 0);
   else
   {
#ifdef CA_ANIMATION_DEBUG_ENABLED
      Self._debugEnabled = CA_ANIMATION_DEBUG_ENABLED;
#endif
   }
}


+ (void) deinitialize
{
}


+ (void) setDebugEnabled:(NSUInteger) flag
{
   Self._debugEnabled = flag;
}


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

   // use INFINITY for repeatCount
   assert( ! isinf( self->_relative.duration));

   self->_relative            = options->timeRange;
   self->_state.bits          = options->bits & ~0xFFFF;  // mask off our internal state bits
   self->_removedOnCompletion = YES;

   //
   // an offset of 1.0 is just wrapping to zero, if negative make positive
   //
   self->_offset              = fmod( options->offset, 1.0);
   if( self->_offset < 0.0)
      self->_offset += 1.0;

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

   _debugEnabled = Self._debugEnabled;

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
   // will have been retained by NSCopyObject, but we don't want it
   // (still in alloc/init) here so release is fine
   [clone->_animationObject release];
   clone->_animationObject = nil;  // or what ?
   return( clone);
}



- (void) animationIndexDidChange
{
   // do nuthin
}


- (void) reverse
{
}


- (void) reset
{
   resetAnimation( self);
}


- (BOOL) changesLayout
{
   return( NO);
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
   CAAnimationLog("");
}


// returns YES, if really ended (reverse flag is confusing to me)
- (BOOL) didEnd
{
   CAAnimationLog("");

   // don't call callbacks if we are "scrubbing" (future)
   // also don't really end
   if( self->_state.bits & CAAnimationScrubbing)
      return( NO);

   self->_state.bits |= CAAnimationEnded;
   [_delegate animationDidStop:self
                      finished:YES];
   return( YES);
}


static inline CAAnimationState  stateReturn( CAAnimation *self, CAAnimationState state)
{
   CAAnimationLogVerbose( "%s", CAAnimationStateUTF8String( state));

   return( state);
}



void   CAAnimationStart( CAAnimation *self,
                         mulle_absolutetime_t now,
                         mulle_relativetime_t animationRate)
{
   //
   // Should we start animating if not yet ? We round down here, so we may
   // start a/ little early in absolute time! This will happen if there is a
   // delay to hit the animationRate better. (All this is a nop if 0.0)
   //
   self->_state.start    = mulle_timeinterval_add( now, self->_relative.delay)
                           - (animationRate / 2.0);
   self->_state.duration = self->_relative.duration;

   // if we are starting immediately fix start back to actual start
   // (tests better)
   if( now >= self->_state.start)
      self->_state.start = now;  // sic!

   self->_state.bits |= CAAnimationStarted;
}


//
// this function just does "math" and no callbacks, which makes it a little
// easier to debug
//
struct CAAnimationFrameInfo
   CAAnimationComputeFrameInfo( CAAnimation *self,
                                mulle_absolutetime_t now,
                                mulle_relativetime_t animationRate)
{
   double                        d;
   double                        e;
   double                        f;
   double                        maxValue;
   double                        midpoint;
   double                        minValue;
   double                        value;
   double                        t;
   int                           edge;
   mulle_relativetime_t          delta;
   mulle_relativetime_t          elapsedTime;
   mulle_relativetime_t          nextMidpoint;
   NSUInteger                    frameIndex;
   NSUInteger                    i;
   NSUInteger                    nextState;
   struct CAAnimationFrameInfo   info;

   nextState   = CAAnimationAnimating;
   delta       = now - (isinf( self->_state.previousFrameTimestamp)
                       ? now
                       : self->_state.previousFrameTimestamp);
   elapsedTime = mulle_timeinterval_subtract( now, self->_state.start);

   // READ: dox/indepth/CAAnimation-in-depth.html before dicking around with
   //       this code

   //
   // if we got a "animationRate" we always quantize, otherwise we
   // quantize it to the last delta (could filter that)
   //
   if( self->_state.bits & CAAnimationQuantize)
      animationRate = (animationRate == 0.0f) ? delta : animationRate;
   if( animationRate != 0.0)
   {
      //
      // instead of the true elapsed time, we "jitter" correct it
      // and to get a stable midpoint, by calculating off the ideal
      // frame elapsedTime
      //
      // 0     0.20         0.61      1.0         1.6
      //     elapsedTime elapsedTime elapsedTime elapsedTime
      //       x            x         x           x
      // |........|........|........|........|........
      // 0       0.3      0.6      0.9      1.2
      //       animRate
      //

      //                   elapsedTime
      //                     x
      //  frame:  #0             #1             #2
      // ................|........_.......|...............
      //                0.3       |      0.6
      //                          v
      //                        midPoint
      //

      // which frame are we in ?
      frameIndex = (NSUInteger) round( elapsedTime / animationRate);
      // midpoint in the frame in seconds (like elapsedTime)
      midpoint   = (frameIndex * animationRate) + (animationRate / 2.0);

      if( elapsedTime > midpoint)
         elapsedTime = midpoint + (animationRate / 2.0);
      else
         elapsedTime = midpoint - (animationRate / 2.0);
   }

   d            = self->_offset + elapsedTime;
   e            = (self->_repeatCount * self->_state.duration) + self->_offset;
   nextMidpoint = fmax( delta, animationRate) / 2.0;

   // when should we finish the animation ? The delta or animationRate give
   // a clue, when the next frame will hit. If we are close to the end, we
   // check if we should round up to end this. If yes, we set 'd' to exactly
   // the value, we would get if we ran the animation through
   if( d + nextMidpoint >= e)
   {
      self->_state.bits |= CAAnimationFinalized;
      nextState          = CAAnimationStateFinalAnimation;
      d                  = e;
   }

   //
   // now scale 'd' down to self->_state.duration (that way then
   // i is the integer part, and f the fractional part)
   // edge is when there just has been a transition to another repeatCount
   //

   //
   // correct 'f' (see CAAnimation-in-depth.html)
   // has no effect if animationRate is 0.0
   //
   if( self->_state.bits & CAAnimationRateCorrect)
   {
      minValue = animationRate / 2 / self->_state.duration;
      maxValue = 1.0 - minValue;

      midpoint = d + (animationRate / 2.0);
      value    = fmod( midpoint / self->_state.duration, 1.0);
      f        = value + ((value - 0.5) / (maxValue - 0.5)) * minValue;
      if( f < minValue)
         f = 0.0f;
      if( f > maxValue)
         f = 1.0;
   }
   else
   {
      f = fmod( d / self->_state.duration, 1.0);
   }

   i = (NSUInteger) floor( d / self->_state.duration);
   // do not use `d` or `e` past this point
   edge = i > self->_state.previousAnimationIndex;
   if( edge)
   {
      if( self->_state.bits & CAAnimationReverses)
      {
         if( ! (self->_state.bits & CAAnimationHasReversed))
            self->_state.bits |= CAAnimationHasReversed;

         self->_state.bits ^= CAAnimationIsReverse;
      }
   }

   //
   // now compute t from 'f'
   //
   if( nextState == CAAnimationStateFinalAnimation &&
       (self->_state.bits & CAAnimationHasIntegerRepeat))
   {
      // the CAAnimationIsReverse meaning is reversed here
      t = (f == 0.0 && i != 0)
          ? (((self->_state.bits & (CAAnimationReverses|CAAnimationIsReverse)) == CAAnimationReverses)
             ? 0.0
             : 1.0
            )
          : f;
   }
   else
   {
      t = f;
      if( self->_state.bits & CAAnimationIsReverse)
         t = 1.0 - t;
   }

   info.nextState = nextState;
   info.t         = t;
   info.i         = i;
   info.delta     = delta;

   return( info);
}


BOOL   CAAnimationDidAnimate( CAAnimation *self,
                              mulle_relativetime_t now,
                              struct CAAnimationFrameInfo info)
{
   self->_state.previousFrameTimestamp         = now;
   self->_state.previousAnimationIndex         = info.i;
   self->_state.previousNormalizedRelativeTime = info.t;

   if( ! (self->_state.bits & CAAnimationDelegateDidStartNotified))
   {
      self->_state.bits |= CAAnimationDelegateDidStartNotified;
      return( YES);
   }
   return( NO);
}


// b animateObject:absoluteTime:animationRate:
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
   struct CAAnimationFrameInfo   info;

   CAAnimationLogVerbose( "_bits=%s; object=%#@ now=%.6f start=%.6f animationRate=%.6f",
                  CAAnimationBitsUTF8String( self->_state.bits), object, now, self->_state.start, animationRate);

   if( self->_state.bits & CAAnimationFinalized)
   {
      if( [self didEnd])
         return( stateReturn( self, CAAnimationStateDone));

      self->_state.bits &= ~CAAnimationFinalized;
   }

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
      CAAnimationStart( self, now, animationRate);
   }

   if( now < self->_state.start)
      return( CAAnimationStateActive);

   if( self->_state.duration == 0.0f)
   {
      [self didEnd]; // ignore scrubbing
      return( stateReturn( self, CAAnimationStateDone));
   }

   if( ! (self->_state.bits & CAAnimationAnimating))
   {
      [self willStartAnimating];
      self->_state.bits |= CAAnimationAnimating;

      // kinda superflous check or ?
      if( ! (self->_state.bits & CAAnimationDelegateWillStartNotified))
      {
         self->_state.bits |= CAAnimationDelegateWillStartNotified;
         [_delegate animationWillStart:self];
      }
   }

   info = CAAnimationComputeFrameInfo( self, now, animationRate);

   if( info.i > self->_state.previousAnimationIndex)
   {
      // used by CABasicAnimation to free some stuff
      [self animationIndexDidChange];

      if( self->_state.bits & CAAnimationReverses)
      {
         [self reverse];
      }
   }

   [self animateObject:object
normalizedRelativeTime:info.t
           elapsedTime:info.delta];

   if( CAAnimationDidAnimate( self, now, info))
      [_delegate animationDidStart:self];

   return( stateReturn( self, info.nextState));
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
   id           object;
   NSUInteger   state;

   state = CAAnimationStateDone;
   assert( ! state);

   mulle_pointerarray_for( objects, object)
   {
      state |= (NSUInteger) MulleObjCObjectPerformSelectorDoubleArgument2( object,
                                                                           sel,
                                                                           renderTime,
                                                                           animationRate);
   }

   return( state != CAAnimationStateDone);
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
