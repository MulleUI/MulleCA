//
//  CAImplicitlyAnimatableObject.h
//  MulleCA
//
//  Copyright (c) 2022 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
