#import "import.h"

//
// Usually the CAAnimatableObject is a "CALayer", so there..
//
@protocol CAAnimatableObject

// returns YES as long as animation is running
- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) time;

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
   // internal state, can't be set
   CAAnimationStarted     = 0x1,    // animation active, but possibly delayed
   CAAnimationAnimating   = 0x2,    // passed delay, now doing something
   CAAnimationScrubbing   = 0x4,    // future
   CAAnimationHasReversed = 0x8,
   CAAnimationEnded       = 0x10,
   CAAnimationPreempt     = 0x20,   // signal preemption

   // user options
   CAAnimationReverses    = 0x10000,
   CAAnimationAdditive    = 0x20000
};


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

// return values for animateObject:
enum CAAnimationState
{
   CAAnimationStateDone           = 0x0,   // animation is done
   CAAnimationStateActive         = 0x1,   // animation is active but waitring
   CAAnimationStateAnimating      = 0x2,   // animation is animating
   CAAnimationStateFinalAnimation = 0x4    // animation has just done the final value
};



typedef void   CAAnimationFunction( CAAnimation *animation,
                                    id object,
                                    double normalizedRelativeTime,
                                    mulle_relativetime_t elapsedTime);

//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly alternative
//
@interface CAAnimation : NSObject <NSCopying>
{
   struct mulle_relativetimerange   _relative;  // delay, copied from initialRenderdelay
   CGFloat                          _originalRepeatCount;

   // mutating state
   struct mulle_absolutetimerange   _absolute;
   CGFloat                          _repeatCount; // original state will be lost
   NSUInteger                       _bits;        // options and more
   NSUInteger                       _frames;
   mulle_absolutetime_t             _lastFrame;
   mulle_absolutetime_t             _currentFrame;
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

// objects have to be CAAnimatableObjects for this to be used
+ (BOOL) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(mulle_absolutetime_t) renderTime;


//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
+ (instancetype) animationWithAnimationOptions:(struct CAAnimationOptions *) options;
- (instancetype) initWithAnimationOptions:(struct CAAnimationOptions *) options;


// returns enum CAAnimationState
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now;

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

- (BOOL) hasEnded;

@end


