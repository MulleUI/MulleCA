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


NS_OPTIONS_TABLE( CAAnimationBits, 19) =
{
   NS_OPTIONS_ITEM( CAAnimationStarted),
   NS_OPTIONS_ITEM( CAAnimationAnimating),
   NS_OPTIONS_ITEM( CAAnimationScrubbing),
   NS_OPTIONS_ITEM( CAAnimationHasReversed),
   NS_OPTIONS_ITEM( CAAnimationIsReverse),
   NS_OPTIONS_ITEM( CAAnimationFinalized),
   NS_OPTIONS_ITEM( CAAnimationEnded),
   NS_OPTIONS_ITEM( CAAnimationInterruptSignal),
   NS_OPTIONS_ITEM( CAAnimationFinishSignal),
// 9
   NS_OPTIONS_ITEM( CAAnimationDelegateWillStartNotified),
   NS_OPTIONS_ITEM( CAAnimationDelegateDidStartNotified),

// 11
   NS_OPTIONS_ITEM( CAAnimationReverses),
   NS_OPTIONS_ITEM( CAAnimationQuantize),
   NS_OPTIONS_ITEM( CAAnimationAdditive),
   NS_OPTIONS_ITEM( CAAnimationCumulative),
   NS_OPTIONS_ITEM( CAAnimationRateCorrect),

// 16
   NS_OPTIONS_ITEM( CAAnimationHasIntegerRepeat),
   NS_OPTIONS_ITEM( CAAnimationStickyArrayCenter),
   NS_OPTIONS_ITEM( CAAnimationStickyArrayEnd)
};


static char   *skip_prefix_if_present( char *s, char *prefix)
{
   size_t   len;

   len = strlen( prefix);
   if( ! strncmp( s, prefix, len))
      s += len;
   return( s);
}


char  *CAAnimationBitsUTF8String( CAAnimationBits bits)
{
   NSUInteger   bit;
   char         *desc;
   char         *s;

   mulle_buffer_do_autoreleased_string( buffer, NULL, s)
   {
      bit = 0x1;
      while( bits)
      {
         if( bits & bit)
         {
            desc = NS_OPTIONS_LOOKUP( CAAnimationBits, bit);
            desc = desc ? desc : "???";
            desc = skip_prefix_if_present( desc, "CAAnimation");
            mulle_buffer_add_string_if_not_empty( buffer, "|");
            mulle_buffer_add_string( buffer, desc);

            bits &= ~bit;
         }
         bit <<= 1;
      }
      mulle_buffer_add_string_if_empty( buffer, "0");
   }
   return( s);
}


char  *CAAnimationBitsDiffUTF8String( CAAnimationBits old, CAAnimationBits bits)
{
   CAAnimationBits   set;
   CAAnimationBits   cleared;
   char              *s;
                              // old     bits       ~      =
   set     = bits & ~old;     // 0x05 -> 0x0C  :   0xFA   0x8
   cleared = old  & ~bits;    //               :   0xF3   0x1

   mulle_buffer_do_autoreleased_string( buffer, NULL, s)
   {
      if( cleared)
      {
         mulle_buffer_add_string( buffer, "-");
         mulle_buffer_add_string( buffer, CAAnimationBitsUTF8String( cleared));
      }

      if( set)
      {
         mulle_buffer_add_string_if_not_empty( buffer, ",");
         mulle_buffer_add_string( buffer, "+");
         mulle_buffer_add_string( buffer, CAAnimationBitsUTF8String( set));
      }
   }
   return( s);
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

- (BOOL) __isCAAnimation
{
   return( YES);
}


static struct
{
   NSUInteger   _debugEnabled;
} Self;


// this will be called for subclasses as well, does it matter ?
+ (void) initialize
{
   char   *s;

   // don't run again for subclass
   if( MulleObjCClassGetID( self) != @selector( CAAnimation))
      return;

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
//   self->_state.previousNormalizedRelativeTime = 0.0;
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
   self->_offset = fmod( options->offset, 1.0);
   if( self->_offset < 0.0)
      self->_offset += 1.0;

   self->_repeatCount = options->repeatCount <= 0.0 ? 1.0 : options->repeatCount;
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

   _debugEnabled        = Self._debugEnabled;
   _removedOnCompletion = YES;

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


- (void) finish
{
   if( self->_state.bits & CAAnimationEnded)
      return;

   self->_state.bits |= CAAnimationFinishSignal;

   // -> Finalized
   [self animateObject:[self animationObject]
          absoluteTime:0.0
         animationRate:0.0];
   // -> Ended
   [self animateObject:[self animationObject]
          absoluteTime:0.0
         animationRate:0.0];
}


- (void) interrupt
{
   self->_state.bits |= CAAnimationInterruptSignal;
}


- (void) willStartAnimating
{
   CAAnimationLog("");
}


// returns YES, if really ended (reverse flag is confusing to me)
- (BOOL) didEnd
{
   BOOL  finished;

   CAAnimationLog("");

   finished = (self->_state.bits & CAAnimationInterruptSignal) ? NO : YES;
   // don't call callbacks if we are "scrubbing" (future)
   // also don't really end
   if( finished && self->_state.bits & CAAnimationScrubbing)
      return( NO);

   [_delegate animationDidStop:self
                      finished:finished];
   return( YES);
}


#if ! defined( CA_ANIMATION_DEBUG_DISABLED)

#define CAAnimationReturnStateLogDo( text)                                          \
   for( NSUInteger loop__state = 0, old__bits = self->_state.bits;            \
        loop__state == 0;                                                     \
        ( ((old__bits != self->_state.bits &&                                 \
            self->_debugEnabled & CAAnimationDebugState)                      \
           ? ( mulleui_log( "<%s %p>: '%s' %s",                               \
                       MulleObjCInstanceGetClassNameUTF8String( self),        \
                       self,                                                  \
                       (text),                                                \
                       CAAnimationBitsDiffUTF8String( old__bits,              \
                                                      self->_state.bits)), 0) \
           : 0),                                                              \
          loop__state = 1)                                                    \
      )                                                                       \
      for( int  break_protect ## __j = 0;    /* break protection */           \
           break_protect ## __j < 1;                                          \
           break_protect ## __j++)

#else

#define CAAnimationReturnStateLogDo( text)    do {} while( 0)

#endif


void   CAAnimationStart( CAAnimation *self,
                         mulle_absolutetime_t now,
                         mulle_relativetime_t animationRate)
{
   CAAnimationReturnStateLogDo( "Start")
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
   mulle_relativetime_t          end;
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
      CAAnimationReturnStateLogDo( "End")
      {
         self->_state.bits |= CAAnimationFinalized;
         nextState          = CAAnimationReturnStateFinalAnimation;
         d                  = e;

         // need to correct this in case we are finishing and now is infinity
         // also it's more in tune with 't'
         end                = self->_state.start + e;
         delta              = end - (isinf( self->_state.previousFrameTimestamp)
                                    ? end
                                    : self->_state.previousFrameTimestamp);
      }
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
         CAAnimationReturnStateLogDo( "Reverse")
         {
            if( ! (self->_state.bits & CAAnimationHasReversed))
               self->_state.bits |= CAAnimationHasReversed;

            self->_state.bits ^= CAAnimationIsReverse;
         }
      }
   }

   //
   // now compute t from 'f'
   //
   if( nextState == CAAnimationReturnStateFinalAnimation &&
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
//   self->_state.previousNormalizedRelativeTime = info.t;

   if( ! (self->_state.bits & CAAnimationDelegateDidStartNotified))
   {
      CAAnimationReturnStateLogDo( "StartNotify")
      {
         self->_state.bits |= CAAnimationDelegateDidStartNotified;
      }
      return( YES);
   }
   return( NO);
}


static inline CAAnimationReturnState  stateReturn( CAAnimation *self,
                                             CAAnimationReturnState state)
{
   CAAnimationLogVerbose( "%s", CAAnimationReturnStateUTF8String( state));
   return( state);
}



// b animateObject:absoluteTime:animationRate:
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
   struct CAAnimationFrameInfo   info;

   CAAnimationLogVerbose( "_bits=%s; object=%#@ now=%.6f start=%.6f animationRate=%.6f",
                  CAAnimationBitsUTF8String( self->_state.bits), object, now, self->_state.start, animationRate);

   if( self->_state.bits & CAAnimationEnded)
   {
      return( stateReturn( self, CAAnimationReturnStateDone));
   }

   if( self->_state.bits & CAAnimationInterruptSignal)
   {
      CAAnimationReturnStateLogDo( "InterruptSignal")
      {
         self->_state.bits &= ~CAAnimationInterruptSignal;
         self->_state.bits |= CAAnimationFinalized;
      }
   }

   if( self->_state.bits & CAAnimationFinalized)
   {
      CAAnimationReturnStateLogDo( "Finalized")
      {
         if( [self didEnd])
         {
            self->_state.bits |= CAAnimationEnded;
            self->_state.bits &= ~CAAnimationAnimating|CAAnimationStarted;
            return( stateReturn( self, CAAnimationReturnStateDone));
         }

         self->_state.bits &= ~CAAnimationFinalized;
      }
   }


   if( self->_state.bits & CAAnimationFinishSignal)
   {
      CAAnimationReturnStateLogDo( "FinishSignal")
      {
         now                = INFINITY;  // finish up for sure
         animationRate      = 0.0;
         self->_state.bits |= CAAnimationAnimating \
                              | CAAnimationStarted \
                              | CAAnimationDelegateDidStartNotified \
                              | CAAnimationDelegateWillStartNotified;
         self->_state.bits &= ~CAAnimationFinishSignal;
      }
   }

   if( ! (self->_state.bits & CAAnimationStarted))
   {
      CAAnimationStart( self, now, animationRate);
   }

   if( now < self->_state.start)
      return( stateReturn( self, CAAnimationReturnStateActive));

   if( self->_state.duration == 0.0f)
   {
      [self didEnd]; // ignore scrubbing
      self->_state.bits |= CAAnimationEnded;
      self->_state.bits &= ~CAAnimationAnimating|CAAnimationStarted;
      return( stateReturn( self, CAAnimationReturnStateDone));
   }

   if( ! (self->_state.bits & CAAnimationAnimating))
   {
      CAAnimationReturnStateLogDo( "Animating")
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
   id     object;
   BOOL   flag;

   flag = NO;
   mulle_pointerarray_for( objects, object)
   {
      flag |= (NSUInteger) MulleObjCObjectPerformSelectorDoubleArgument2( object,
                                                                           sel,
                                                                           renderTime,
                                                                           animationRate);
   }

   return( flag);
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


- (char *) UTF8String
{
   char   *s;

   s = MulleObjC_asprintf( "<%s %p: %s>",
                           MulleObjCInstanceGetClassNameUTF8String( self),
                           self,
                           CAAnimationBitsUTF8String( self->_state.bits & 0xFF));
   return( s);
}

@end
