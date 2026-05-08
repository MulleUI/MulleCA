//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

#import "CATransaction.h"
#import "CAAnimationStorage.h"


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
// WARNING: you can implicitly animate only properties of types:
//
//          id
//          NSInteger
//          CGFloat
//          CGPoint
//          CGRect
//          CGSize
//          CAPolarPoint
//          CACircle
//          MulleCornerInsets
//          MulleEdgeInsets
//          NSRange
//          mulle_range
//
// specifically not working currently: BOOL, unsigned <type>, short, int,
//                                     char, long, long long, long double
//                                     <type> *, union {} ...
//
@mixin CAImplicitlyAnimatableObject < MullePropertyObserving>

@property( dynamic, retain) id   snapshot;

@required
- (void) generateAnimationsForPropertiesWithSnapshot:(id) snapshot
                                      animationGroup:(CAAnimationGroup *) group;

@optional
- (id) observablePropertiesSnapshot;

- (void) willChange; // MullePropertyObserving
- (void) commitImplicitAnimations:(CAAnimationGroup *) animationGroup; // either UIView class or CATransaction
- (void) forgetImplicitAnimations;

@end


#define CAImplicitlyAnimatableObjectIvars       \
   id   _snapshot

#define CAImplicitlyAnimatableObjectInterface   \
   @property( retain) id   snapshot

#define CAImplicitlyAnimatableObjectImplementation                   \
extern void   CAImplicitlyAnimatableObjectDummyNotActuallyPresent( void)
