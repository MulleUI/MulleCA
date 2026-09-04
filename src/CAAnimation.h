//
//  CAAnimation.h
//  MulleCA
//
//  Copyright (c) 2019 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "import.h"

// CALayer "private" animations just stick to the CALayer.
//
//
//  .---------.    .-------------.
//  | CALayer |--->| CAAnimation |
//  '---------'    '-------------'
//       |         .-------------.
//       '-------->| CAAnimation |
//                 '-------------'
//
// Otherwise CAAnimation are part of a CAAnimator, which is usually a component
// of UIWindow.
//
//                          .------------.
//                    .-----| CAAnimator |-----------------------.
//                    |     '------------'                       |
//                    v           |                              v
//          .------------------.  |    .-------------.  .------------------.
//        .-| CAAnimationGroup |  '--->| CAAnimation |  | CAAnimationGroup |
//        | '------------------'       '-------------'  '------------------'
//        v           |
// .-------------.    |     .-------------.
// | CAAnimation |    '---->| CAAnimation |
// '-------------'          '-------------'
//        |                        |
//        v                        v
//   .--------.               .---------.
//   | UIView |               | CALayer |
//   '--------'               '---------'
//
//

// TODO: split into two enums

typedef NS_OPTIONS( NSUInteger, CAAnimationBits)
{
   // internal state, can't be set from outside
   // this will be cleaned on reset
   CAAnimationStarted          = 0x1,    // animation active, but possibly delayed
   CAAnimationAnimating        = 0x2,    // passed delay, now doing something
   CAAnimationScrubbing        = 0x4,    // future
   CAAnimationHasReversed      = 0x8,
   CAAnimationIsReverse        = 0x10,
   CAAnimationFinalized        = 0x20,   // only used with animationRate
   CAAnimationEnded            = 0x40,
   CAAnimationInterruptSignal  = 0x100,   // signal preemption
   CAAnimationFinishSignal     = 0x200,   // signal quick finish

// 9
   CAAnimationDelegateWillStartNotified = 0x1000,
   CAAnimationDelegateDidStartNotified  = 0x2000,

// 11
   // user options, wont be reset
   CAAnimationReverses      = 0x10000,
//   CAAnimationReversesLate  = 0x20000,    // no longer supported
   CAAnimationQuantize      = 0x20000,   // scale according to Indepth2
   CAAnimationAdditive      = 0x40000,    // values will be added
   CAAnimationCumulative    = 0x80000,    // valid with additive, values will not be reset on repeat
   CAAnimationRateCorrect   = 0x100000,   // scale according to Indepth2

// 16
   // other options, wont be reset

   CAAnimationHasIntegerRepeat  = 0x200000,
//   CAAnimationStickyArrayFront  = 0x0,        // default
   CAAnimationStickyArrayCenter = 0x400000,
   CAAnimationStickyArrayEnd    = 0x800000
// 19
};


MULLE_CA_GLOBAL
NS_OPTIONS_TABLE( CAAnimationBits, 19);


MULLE_CA_GLOBAL
char  *CAAnimationBitsUTF8String( CAAnimationBits bits);


// used during animation, so the animation code knows where it is
// in temporal space so to speak
struct CAAnimationFrameInfo
{
   double                 t;     // 0.0 - 1.0
   NSUInteger             i;
   NSUInteger             nextState;
   mulle_relativetime_t   delta;
   mulle_relativetime_t   elapsedTime;
};



//
// If this were iOS and you would set CAAnimationReverses, the repeatCount
// would be implicitly doubled. (e.g. a 0.2s autoreverses CAAnimation on iOS
// takes 0.4s). Here CAAnimationReverses won't happen if the repeatCount is
// 1. An animation with a repeatCount of <= 0.0 is corrected to 1.0, as 0.0
// makes no sense!
//
struct CAAnimationOptions
{
   struct mulle_relativetimerange    timeRange;
   float                             offset;  // 0 - 1 (1 is same as 0)
   float                             repeatCount;
   NSUInteger                        bits;  // reverse flag mainly
};


#define CA_ANIMATION_OPTIONS_DATA( delay, duration, offset, repeat, bits)  \
   ((struct CAAnimationOptions)                                            \
   {                                                                       \
      MULLE_RELATIVETIMERANGE_DATA( (delay), (duration)),                  \
      (offset),                                                            \
      (repeat),                                                            \
      (bits)                                                               \
   })
   

static inline struct CAAnimationOptions
   CAAnimationOptionsMake( struct mulle_relativetimerange timeRange,
                           mulle_relativetime_t  offset,
                           float repeatCount,
                           NSUInteger bits)
{
   return( (struct CAAnimationOptions)
           {
              .timeRange   = timeRange,
              .offset      = offset,
              .repeatCount = repeatCount,
              .bits        = bits
            });
}


// these options are not in the constructors, because they are reasonably
// rare and remembering the order as well as the meaning of the constants
// gets some
static inline void
   CAAnimationOptionsSetTimeRange( struct CAAnimationOptions *options,
                                   struct mulle_relativetimerange timeRange)
{
   if( ! options)
      return;
   options->timeRange = timeRange;
}


static inline void
   CAAnimationOptionsSetOffset( struct CAAnimationOptions *options,
                                float offset)
{
   if( ! options)
      return;
   options->offset = offset;
}

static inline void
   CAAnimationOptionsSetRepeatCount( struct CAAnimationOptions *options,
                                     float repeatCount)
{
   if( ! options)
      return;
   options->repeatCount = repeatCount;
}


static inline void
   CAAnimationOptionsSetBit( struct CAAnimationOptions *options,
                             NSUInteger bit)
{
   if( ! options)
      return;
   options->bits |= bit;
}


static inline void
   CAAnimationOptionsClearBit( struct CAAnimationOptions *options,
                               NSUInteger bit)
{
   if( ! options)
      return;
   options->bits &= ~bit;
}


char  *CAAnimationOptionsUTF8String( struct CAAnimationOptions *options);


@class CAAnimation;


static inline mulle_relativetime_t
   CAFrameCountToRelativeTime( NSUInteger frames,
                               mulle_relativetime_t frameRate)
{
   return( frames * frameRate);
}


//
// All animations in one UIView beginAnimations:context: have the
// same duration and start and repeatCount
//
@protocol CAAnimationDelegate

- (void) animationWillStart:(CAAnimation *) animation;
- (void) animationDidStart:(CAAnimation *) animation;
- (void) animationDidStop:(CAAnimation *) animation
                 finished:(BOOL) flag;
@end



@class CAAnimation;
@class CAAnimationGroup;

//
// This enum is _not_ stored in CAAnimation. Its the possible 
// return values for -animateObject:absoluteTime:animationRate:
//
// You will not necessarily see "CAAnimationReturnStateFinalAnimation" during the
// animation steps. It's there to properly chain animations, waiting for a
// an animation being done or just having finished to setup a seamless
// transition.
//
typedef NS_OPTIONS( NSUInteger, CAAnimationReturnState)
{
   CAAnimationReturnStateDone           = 0x0,   // animation is done
   CAAnimationReturnStateActive         = 0x1,   // animation is active but waiting
   CAAnimationReturnStateStarted        = 0x2,   // animation just started
   CAAnimationReturnStateAnimating      = 0x4,   // animation is animating
   CAAnimationReturnStateFinalAnimation = 0x8    // animation has just done the final value
};


static inline char   *CAAnimationReturnStateUTF8String( CAAnimationReturnState state)
{
   switch( state)
   {
   case CAAnimationReturnStateDone           : return( "CAAnimationReturnStateDone");
   case CAAnimationReturnStateActive         : return( "CAAnimationReturnStateActive");
   case CAAnimationReturnStateStarted        : return( "CAAnimationReturnStateStarted");
   case CAAnimationReturnStateAnimating      : return( "CAAnimationReturnStateAnimating");
   case CAAnimationReturnStateFinalAnimation : return( "CAAnimationReturnStateFinalAnimation");
   default                                   : return( "???");
   }
}

static inline char   *CAAnimationShortStateUTF8String( CAAnimationReturnState state)
{
   switch( state)
   {
   case CAAnimationReturnStateDone           : return( "Done");
   case CAAnimationReturnStateActive         : return( "Active");
   case CAAnimationReturnStateStarted        : return( "Started");
   case CAAnimationReturnStateAnimating      : return( "Animating");
   case CAAnimationReturnStateFinalAnimation : return( "FinalAnimation");
   default                                   : return( "???");
   }
}



typedef void   CAAnimationFunction_t( CAAnimation *animation,
                                      id object,
                                      struct CAAnimationFrameInfo *info);


struct CAAnimationMutableState
{
  // mutating state
   mulle_absolutetime_t   start;
   mulle_relativetime_t   duration;

   NSUInteger             bits;        // options and more

   NSUInteger             previousAnimationIndex;
   mulle_absolutetime_t   previousFrameTimestamp;
//   mulle_relativetime_t   previousNormalizedRelativeTime;
};


@protocol CAAnimation < NSObject>

@property( getter=isRemovedOnCompletion) BOOL removedOnCompletion;

//
// Used, if part of a CAAnimationGroup. Not used, if animation is a
// CALayer "private" animation. Return self, if you want to animate your
// custom class, that implements CAAnimation so it can be removed by
// CAAnimationStorage
//
@property( retain) id    animationObject;

// used to identify a "kind" of animation independent of what object it
// targets (animationObject), so a later transition can find and -finish
// only the animations belonging to a prior, same-purpose transition.
// Base CAAnimation always returns NULL; CAAnimationSequence/Group store
// and forward an actual value (see -setAnimationID:).
- (char *) animationID;

// returns CAAnimationReturnState
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate;


//
// Stopping animations mid-flight:
//
//   -interrupt  Stop immediately, leave the animated property at its current
//              interpolated value. The delegate receives
//              animationDidStop:finished:NO. Use this when the user cancels
//              an action and the current visual state is acceptable.
//
//   -finish    Stop immediately, jump the animated property to its final end
//              value. The delegate receives animationDidStop:finished:YES.
//              Use this when you want the animation's intended result without
//              waiting (e.g. a view is being removed and must reach its
//              destination).
//
//   -cancel    Stop immediately, revert the animated property to its start
//              value (interpolate at t=0). The delegate receives
//              animationDidStop:finished:NO. For sequences and groups,
//              children are cancelled in reverse order. Use this to undo
//              an animation and snap back to the original state.
//
//   -reset     Reset the animation's internal timing state so it can be
//              replayed from the beginning. Does NOT write to the animated
//              object — the property keeps whatever value it currently has.
//              No delegate callback. Use this to re-run an animation that
//              has already completed (with removedOnCompletion == NO).
//
// These methods work on CAAnimation, CAAnimationSequence, and
// CAAnimationGroup. For sequences and groups, the operation is forwarded
// to all contained child animations.
//

// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
// will be called in addition to -animationIndexDidChange when animation
// bounces
- (void) reverse;

- (void) reset;
- (void) interrupt;
- (void) finish;
- (void) cancel;

// if an animation touches a UIView frame or bounds, default: NO
- (BOOL) changesLayout;

@end

//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly alternative
//

// if there is an animationGroup it will retain us
@interface CAAnimation : NSObject <CAAnimation>
{
   struct mulle_relativetimerange   _relative;  // delay, copied from initialRenderdelay
   // mutating state
   struct CAAnimationMutableState   _state;
   mulle_relativetime_t             _offset;
   float                            _repeatCount;
}

@property( assign) NSUInteger  debuggingFlags   MULLE_OBJC_THREADSAFE_PROPERTY;

// MEMO: these properties are used by CABasicAnimation, maybe they should be
// moved there
@property( getter=isRemovedOnCompletion) BOOL   removedOnCompletion;
@property( retain) id                           animationObject;

// contrary to Apple CoreAnimation, the delegate is not retained
@property( assign) id <CAAnimationDelegate>     delegate;

// this invocation is triggered when the animation is finished
// it's a convenience where you just want to have a small inline code 
// @invocation and not a delegate. We could enforce, that the first argument
// of the invocation must be this CAAnimation so we can set it when we call
// back and also pass the state. We could check the target selector for
// a known delegate type and if yes, set the invocation properly. The negative
// would be that the caller cant pass "aux" state again.
//
@property( retain) NSInvocation                 *finishedInvocation;

@property( assign) CAAnimationFunction_t        *animationFunction;


//
// If the repeatCount is an integer, CAAnimation will ensure that the
// endValue is placed into the animatable objects at the end of the animation.
//
+ (BOOL) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(mulle_absolutetime_t) renderTime
          animationRate:(mulle_relativetime_t) animationRate;

//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
+ (instancetype) animationWithAnimationOptions:(struct CAAnimationOptions *) options;
- (instancetype) initWithAnimationOptions:(struct CAAnimationOptions *) options;


// returns CAAnimationReturnState
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate;

//
// subclass must override this method, to do their special effect
// t: >= 0.0 <= 1.0
// time:
- (void) animateObject:(id) object
    animationFrameInfo:(struct CAAnimationFrameInfo *) info;

// animation passes a duration boundary
//- (void) animationIndexWillChange;
- (void) animationIndexDidChange;

- (BOOL) hasEnded;

@end


void   CAAnimationStart( CAAnimation *self,
                         mulle_absolutetime_t now,
                         mulle_relativetime_t animationRate);

//
// this function just does "math" and no callbacks, which makes it a little
// easier to debug
//
struct CAAnimationFrameInfo
   CAAnimationComputeFrameInfo( CAAnimation *self,
                                mulle_absolutetime_t now,
                                mulle_relativetime_t animationRate);


BOOL   CAAnimationDidAnimate( CAAnimation *self,
                              mulle_relativetime_t now,
                              struct CAAnimationFrameInfo info);
