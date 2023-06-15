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

// this class might soon die though and be replaced by a protocolclass


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


// if you can subclass from this you have it easier, otherwise copy the code
// into your class.

@interface CAImplicitlyAnimatableObject : NSObject < NSCopying, CAImplicitlyAnimatableObject>
{
   id   _snapshot;
}

- (void) commitImplicitAnimations:(CAAnimationGroup *) group; // either UIView class or CATransaction
- (void) forgetImplicitAnimations;

@end
