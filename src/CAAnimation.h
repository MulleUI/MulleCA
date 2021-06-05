#import "import.h"

#import "CATime.h"


@protocol CAAnimatableObject

// returns YES as long as animation is running
- (void) animateWithAbsoluteTime:(CAAbsoluteTime) time;

@end


// Usually the CAAnimatableObject is a "CALayer", so there..
//
// This is how animations look like  "in flight", they stick to a layer and
// they share an animation group. The CAAnimationGroup is fairly boring
// and unimportant though and may even be missing for animations, that are not
// created during a CATransaction.
//
//  .---------.    .-------------.    .------------------.
//  | CALayer |--->| CAAnimation |--->| CAAnimationGroup |
//  '---------'    '-------------'    '------------------'
//       |         .-------------.              ^
//       '-------->| CAAnimation |--------------'
//                 '-------------'
//

enum CAAnimationBits
{
   // internal state, can't be set
   CAAnimationStarted     = 0x1,
   CAAnimationHasReversed = 0x2,
   CAAnimationEnded       = 0x4,
   CAAnimationStateless   = 0x8,
   CAAnimationPreempt     = 0x10,   // signal preemption

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

@property( retain) CAAnimationGroup           *animationGroup;
@property( assign) CAAnimationFunction        *animationFunction;
@property( getter=isRemovedOnCompletion) BOOL removedOnCompletion;
//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
- (id) initWithOptions:(struct CAAnimationOptions *) options;

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

// objects have to be CAAnimatableObjects for this to be used
+ (void) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(CAAbsoluteTime) renderTime;

// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
- (void) reverse;

// animation will start again with values as given
- (void) reset;

- (BOOL) hasEnded;

@end


