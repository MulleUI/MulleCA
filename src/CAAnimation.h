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

extern NS_OPTIONS_TABLE( CAAnimationBits, 19);

MULLE_CA_EXTERN_GLOBAL
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

// returns CAAnimationReturnState
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate;


// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
// will be called in addition to -animationIndexDidChange when animation
// bounces
- (void) reverse;

// reset to start values
- (void) reset;

// keep at current values (and stop animating)
- (void) interrupt;

// set to end values (and stop animating)
- (void) finish;

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
