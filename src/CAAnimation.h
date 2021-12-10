#import "import.h"

//
// Usually the CAAnimatableObject is a "CALayer", so there..
//
@protocol CAAnimatableObject

// returns YES as long as animation is running
- (BOOL) animateWithAbsoluteTime:(CAAbsoluteTime) time;

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
   struct CARelativeTimeRange    timeRange;
   CGFloat                       repeatCount;
   NSUInteger                    bits;  // reverse flag mainly
};


static inline struct CAAnimationOptions
   CAAnimationOptionsMake( struct CARelativeTimeRange timeRange,
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


@class CALayer;
@class CAAnimation;


static inline CARelativeTime   CAFrameCountToRelativeTime( NSUInteger frames,
                                                           CGFloat frameRate)
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


typedef void   CAAnimationFunction( CAAnimation *animation,
                                    id object,
                                    double normalizedRelativeTime,
                                    CARelativeTime elapsedTime);

//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly alternative
//
@interface CAAnimation : NSObject <NSCopying>
{
   struct CARelativeTimeRange   _relative;  // delay, copied from initialRenderdelay
   CGFloat                      _originalRepeatCount;

   // mutating state
   struct CAAbsoluteTimeRange   _absolute;
   CGFloat                      _repeatCount; // original state will be lost
   NSUInteger                   _bits;        // options and more
   NSUInteger                   _frames;
   CAAbsoluteTime               _lastFrame;
   CAAbsoluteTime               _currentFrame;
}

// contrary to Apple CoreAnimation, the delegate is not retained
@property( assign) id <CAAnimationDelegate>   delegate;

// if there is an animationGroup it will retain us
@property( assign) CAAnimationFunction        *animationFunction;
@property( getter=isRemovedOnCompletion) BOOL removedOnCompletion;

// used, if part of a CAAnimationGroup, not used if animation is a
// CALayer "private" animation
@property( retain) id <CAAnimatableObject>    animationObject;

// objects have to be CAAnimatableObjects for this to be used
+ (void) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(CAAbsoluteTime) renderTime;


//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
+ (instancetype) animationWithAnimationOptions:(struct CAAnimationOptions *) options;
- (instancetype) initWithAnimationOptions:(struct CAAnimationOptions *) options;


// returns NO if animation ended
- (BOOL) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now;

//
// subclass must override this method, to do their special effect
// t: >= 0.0 <= 1.0
// time:
- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(CARelativeTime) time;


// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
- (void) reverse;

// animation will start again with values as given
- (void) reset;

- (BOOL) hasEnded;

@end


