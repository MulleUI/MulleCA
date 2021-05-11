//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

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
// The orginal CATransaction operates with class methods and the storage
// is thread local. Here you have to do the storage of the transaction
// yourself.
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
