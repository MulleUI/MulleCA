//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "import.h"


@class CAAnimationGroup;


// A high level view of the state of a CATransaction. The CATransaction
// doesn't generate CAAnimations by itself. It just collects animatable objects
// and provides them with a CAAnimationGroup. The objects (CALayers)
// themselves generate their animations. See further below for a bit more
// detail.
//
//             .---------------.
//             | CATransaction |
//             '---------------'
//                     |
//                     v
//           .------------------.
//         .-| CAAnimationGroup |
//         | '------------------'
//         v           |
//  .-------------.    |     .-------------.
//  | CAAnimation |    '---->| CAAnimation |
//  '-------------'          '-------------'
//         |                        |
//         v                        v
//    .--------.               .---------.
//    | UIView |               | CALayer |
//    '--------'               '---------'
//
//
// Create a CATransaction, then start with -begin.
// Now layers should add themselves with -addAnimatableObject: on animatable
// property (observable) changes. This stops when you issue -commit.
//
// Now all the animatable objects are sent a -commitImplicitAnimations: method.
// An object will then create CABasicAnimations on its own behalf.
// That's all CATransaction does. When you do a "commit", you get the setup
// animations back in a animation group.
//
// A problem of this setup is, the inheritance of values in a CAAnimationGroup
// to constituent CAAnimations. Example: is the delay additive ?
//

@protocol CAImplicitlyAnimatableObject

- (void) commitImplicitAnimations:(CAAnimationGroup *) animationGroup; // either UIView class or CATransaction

@end


enum CATransactionState
{
   CATransactionIdle,
   CATransactionStarted,
   CATransactionCommitting
};


// A simplified sketch of a simple animation of a CALayer moving from
// "fromR" to "toR". First the initial value is set outside of the transaction.
// Then the transaction is started and the destination value is set. The
// CALayer notices it's in a transaction and saves the previous value in a
// snapshot. The layer also adds itself to the transaction. When the
// transaction ends, the layer produces an animation for the frame and resets
// the frame to the initial value.
//
//
//       -[CALayer setFrame:fromR]  .---------------.-------------.
//                 |                | CALayer       | -setFrame:  |
//                 |                |               '-------------'
//                 |                '---------------'
//                 v
//       -[CATransaction begin]
//                 |                .---------------.-------------.
//                 |                | CALayer       | -willChange |
//                 |                |               .-------------.
//                 v                '---------------| -snapshot   |
//       -[CALayer setFrame:toR]                    .-------------.
//                 |                                | -setFrame:  |
//                 |                                '-------------'
//                 |
//                 v
//       -[CATransaction commit]    .---------------.----------------.
//                                  | CALayer       | -addAnimation: |
//                                  |               '----------------'
//                                  '---------------| -setFrame:     |
//                                                  '----------------'
//
//
// The orginal CATransaction operates globally with class methods, on a thread
// local basis.
// Here you have to create the transaction yourself, it is still thread local
// though. Don't operate on layers from multiple threads though (at the
// same time).
//
// Note: this mechanism doesn't work just with layers but can work with all
//       objects that implement CAImplicitlyAnimatableObject.
//
@interface CATransaction : NSObject
{
   // mutable state
   struct mulle_pointerarray   _animatedObjects;
   CAAnimationGroup            *_animationGroup;
}

@property( assign, readonly) enum CATransactionState  state;

- (BOOL) areAnimationsEnabled;
- (void) addAnimatableObject:(id <CAImplicitlyAnimatableObject>) object;

//
// Transactions are short lived things, don't retain or copy them
//

- (void) begin;
- (CAAnimationGroup *) commit;

//
- (void) reset;

@end


//
// forwarded to the animationGroup. These properties will not be work until a
// -begin and will stop working after -commit or -cancel
//
@interface CATransaction( CAAnimationGroupForwarding)

@property( assign, dynamic) void     *context;
@property( assign, dynamic) id       animationDelegate;
@property( assign, dynamic) SEL      animationWillStartSelector;
@property( assign, dynamic) SEL      animationDidStopSelector;
@property( assign, dynamic) char     *animationID;

// keep in order of CAAnimationParameters
@property( assign, dynamic) mulle_relativetime_t     animationDelay;
@property( assign, dynamic) mulle_relativetime_t     animationDuration;
@property( assign, dynamic) float                    animationRepeatCount;
@property( assign, dynamic) NSUInteger               animationCurve;
@property( assign, dynamic) CATweenFunction         *animationTweenFunction;
@property( assign, dynamic) BOOL                     animationAutoreverses;

//
// For CALayer, implicit additive animations are "added" to the layer.
// If not additive, all animations are removed prior. An addirtive animation
// does not use "fixed" values, but rather interpolates from the current value.
//
@property( assign, dynamic) BOOL                     animationIsAdditive;

// will be strcpy
- (void) setAnimationID:(char *) s;
- (char *) animationID;

@end

//
// on a per-thread basis
//
id     CATransactionGetCurrentTransaction( void);
void   CATransactionSetCurrentTransaction( id);
