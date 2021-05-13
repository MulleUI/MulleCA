//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "import.h"

#import "CATime.h"


@class MulleAnimationDelegate;


//
// for technical reasons (compatibility with UIView) we have this protocol
// to pass the animation parameters
//
struct CAAnimationParameters
{
   CARelativeTime   animationDelay;
   CARelativeTime   animationDuration;
   float            animationRepeatCount;
   NSUInteger       animationCurve;
   BOOL             animationAutoreverses;
};


@protocol CAImplicitlyAnimatableObject

- (void) commitImplicitAnimationsWithID:(char *) animationsID
                               delegate:(MulleAnimationDelegate *) animationDelegate
                             parameters:(struct CAAnimationParameters *) info; // either UIView class or CATransaction

@end


enum CATransactionState
{
   CATransactionIdle,
   CATransactionStarted,
   CATransactionCommitting
};


//
// Create a CATransaction, then start with -begin.
// Now object should add themselves with -addAnimatableObject: on animatable
// property changes. This stops when you issue -commit.
//
// Now all the animatable objects are sent a -commitImplicitAnimationsWithID:
// delegate:parameters: method. A CALayer will then create CABasicAnimations
// on its own behalf. That's all CATransaction does. The actual animation
// is done with -animateWithAbsoluteTime: on each CALayer.
//
// The orginal CATransaction operates with class methods and the it is stored
// is thread local. Here you have to do create the transaction yourself,
// it is still thread local though. Don't operate on layers from multiple
// threads though (at the same time).
//
@interface CATransaction : NSObject
{
   // mutable state
   struct mulle_pointerarray   _animatedObjects;

   char                        *_animationID;
}

@property( assign, readonly) enum CATransactionState  state;

@property( assign) void             *context;

@property( assign) id               animationDelegate;
@property( assign) SEL              animationWillStartSelector;
@property( assign) SEL              animationDidStopSelector;

// keep in order of CAAnimationParameters
@property( assign) CARelativeTime   animationDelay;
@property( assign) CARelativeTime   animationDuration;
@property( assign) float            animationRepeatCount;
@property( assign) NSUInteger       animationCurve;
@property( assign) BOOL             animationAutoreverses;

// will be strcpy
- (void) setAnimationID:(char *) s;
- (char *) animationID;

- (BOOL) areAnimationsEnabled;

- (void) addAnimatableObject:(id <CAImplicitlyAnimatableObject>) object;

//
// Transactions are short lived things, don't retain or copy them
//

- (void) begin;
- (void) commit;
- (void) cancel;

@end

//
// on a per-thread basis
//
id     CATransactionGetCurrentTransactionManager( void);
void   CATransactionSetCurrentTransactionManager( id);
