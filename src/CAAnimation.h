#import "import.h"

//
// Usually the CAAnimatableObject is a "CALayer", so there..
//
@protocol CAAnimatableObject

// returns YES as long as animation is running
- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) time
                   animationRate:(mulle_relativetime_t) animationRate;
@end



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
enum CAAnimationBits
{
   // internal state, can't be set from outside
   // this will be cleaned on reset
   CAAnimationStarted     = 0x1,    // animation active, but possibly delayed
   CAAnimationAnimating   = 0x2,    // passed delay, now doing something
   CAAnimationScrubbing   = 0x4,    // future
   CAAnimationHasReversed = 0x8,
   CAAnimationIsReverse   = 0x10,
   CAAnimationFinalized   = 0x20,   // only used with animationRate
   CAAnimationEnded       = 0x40,
   CAAnimationPreempt     = 0x80,   // signal preemption

   CAAnimationDelegateDidStartNotified = 0x100,


   // user options, wont be reset
   CAAnimationReverses    = 0x10000,
   CAAnimationAdditive    = 0x20000,    // first value will be set, others will be added
   CAAnimationCumulative  = 0x40000,    // first value will be added, if additive

   // other options, wont be reset

   CAAnimationHasIntegerRepeat = 0x100000,
};


char  *CAAnimationBitsUTF8String( NSUInteger bits);

//
// If this were iOS and you would set CAAnimationReverses, the repeatCount
// would be implicitly doubled. (e.g. a 0.2s autoreverses CAAnimation on iOS
// takes 0.4s). Here CAAnimationReverses won't happen if the repeatCount is
// 1.
//
struct CAAnimationOptions
{
   struct mulle_relativetimerange    timeRange;
   CGFloat                           repeatCount;
   NSUInteger                        bits;  // reverse flag mainly
};


static inline struct CAAnimationOptions
   CAAnimationOptionsMake( struct mulle_relativetimerange timeRange,
                           CGFloat repeatCount,
                           NSUInteger bits)
{
   return( (struct CAAnimationOptions)
           {
              .timeRange   = timeRange,
              .repeatCount = repeatCount,
              .bits        = bits
            });
}


char  *CAAnimationOptionsUTF8String( struct CAAnimationOptions *options);


@class CAAnimation;


static inline mulle_relativetime_t   CAFrameCountToRelativeTime( NSUInteger frames,
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
                 finished:(BOOL)flag;
@end



@class CAAnimation;
@class CAAnimationGroup;

//
// return values for animateObject:
// You will not necessarily see "CAAnimationStateFinalAnimation" during the
// animation steps. It's there to properly chain animations, waiting for a
// an animation being done or just having finished to setup a seemless
// transition.
//
enum CAAnimationState
{
   CAAnimationStateDone           = 0x0,   // animation is done
   CAAnimationStateActive         = 0x1,   // animation is active but waiting
   CAAnimationStateAnimating      = 0x2,   // animation is animating
   CAAnimationStateFinalAnimation = 0x8    // animation has just done the final value
};


static inline char   *CAAnimationStateUTF8String( enum CAAnimationState state)
{
   switch( state)
   {
   case CAAnimationStateDone           : return( "CAAnimationStateDone");
   case CAAnimationStateActive         : return( "CAAnimationStateActive");
   case CAAnimationStateAnimating      : return( "CAAnimationStateAnimating");
   case CAAnimationStateFinalAnimation : return( "CAAnimationStateFinalAnimation");
   }
}


typedef void   CAAnimationFunction( CAAnimation *animation,
                                    id object,
                                    double normalizedRelativeTime,
                                    mulle_relativetime_t elapsedTime);


struct CAAnimationMutableState
{
  // mutating state
   NSUInteger             bits;        // options and more

   mulle_absolutetime_t   start;
   mulle_relativetime_t   duration;

   mulle_absolutetime_t   previousFrameTimestamp;
   NSUInteger             previousAnimationIndex;
   double                 previousNormalizedRelativeTime;
};

//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly alternative
//
@interface CAAnimation : NSObject <NSCopying>
{
   struct mulle_relativetimerange   _relative;  // delay, copied from initialRenderdelay
   CGFloat                          _repeatCount;

   // mutating state
   struct CAAnimationMutableState   _state;
}

// contrary to Apple CoreAnimation, the delegate is not retained
@property( assign) id <CAAnimationDelegate>   delegate;

// if there is an animationGroup it will retain us
@property( assign) CAAnimationFunction        *animationFunction;
@property( getter=isRemovedOnCompletion) BOOL removedOnCompletion;

// used, if part of a CAAnimationGroup, not used if animation is a
// CALayer "private" animation
// This does not need to be a <CAAnimatableObject>, it just needs properties
@property( retain) id    animationObject;

//
// Objects have to be CAAnimatableObjects for this to be used
// if you use an animationRate != 0.0 and the repeatCount is an integer,
// CAAnimation will ensure that the endValue is placed into the animatable
// objects and the end of the animation
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


// returns enum CAAnimationState
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate;

//
// subclass must override this method, to do their special effect
// t: >= 0.0 <= 1.0
// time:
- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(mulle_relativetime_t) time;


// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
- (void) reverse;

// animation will start again with values as given
- (void) reset;

// animation has passed a duration boundary
- (void) animationIndexWillChange;
- (void) animationIndexDidChange;

- (BOOL) hasEnded;

@end


