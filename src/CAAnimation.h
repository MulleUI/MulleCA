#import "import.h"

#import "CATime.h"


enum CAAnimationBits
{
   CAAnimationStarted     = 0x1,
   CAAnimationHasReversed = 0x2,
   CAAnimationEnded       = 0x4,
   CAAnimationStateless   = 0x8,
   // options
   CAAnimationReverses    = 0x10000
};



struct CAAnimationOptions
{
   struct CARelativeTimeRange    timeRange;
   CGFloat                       repeatCount;
   NSUInteger                    bits;  // reverse flag mainly
};


@class CALayer;

// All animations in one UIView beginAnimations:context: have the
// same duration and start and repeatCount

@interface MulleAnimationDelegate : NSObject

@property( assign) id     delegate;
@property( assign) SEL    animationWillStartSelector;
@property( assign) SEL    animationDidStopSelector;
@property( assign) void   *context;
@property( assign) char   *identifier;

@property( assign) NSUInteger  startedCount;
@property( assign) NSUInteger  endedCount;

- (void) willStart;
- (void) didPreempt;
- (void) didEnd;

@end


@protocol CAAnimatableObject

- (void) animateWithAbsoluteTime:(CAAbsoluteTime) time;

@end


@class CAAnimation;


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
}

//@property( retain) CAAnimationGroup        *animationGroup;
@property( retain) MulleAnimationDelegate  *animationDelegate;
@property( assign) CAAnimationFunction     *animationFunction;
//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
- (id) initWithOptions:(struct CAAnimationOptions *) options;

- (void) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now;

//
// subclass must override this method, to do their special effect
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) x
          elapsedTime:(CARelativeTime) time;

+ (void) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(CAAbsoluteTime) renderTime;

// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
- (void) reverse;

// animation will start again with values as given
- (void) reset;

@end

