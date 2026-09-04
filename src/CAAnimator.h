//
//  CAAnimator.h
//  MulleCA
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
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
#import "import.h"


#import "CAAnimationStorage.h"

//
// The CAAnimator stores CAAnimations (via CAAnimationStorageObject) and when 
// asked to animate, animates them. CAAnimationGroups are CAAnimations, that 
// get created by CATransactions.
//
//                          .-------------.
//                          | CAAnimator  |
//                       0  .-------------.
//                    .-----| _animations |  (CAAnimationStorageObject)
//                    |     '-------------'
//                    v           | 1
//          .------------------.  |    .-------------.
//        .-| CAAnimationGroup |  '--->| CAAnimation |
//        | '------------------'       '-------------'
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
// We use the CAAnimationStorageObject for the storage of the animationGroups
// as they are based on CAAnimation. You could also put animations without
// animationGroups into the CAAnimator
//
@interface CAAnimator : NSObject < CAAnimationStorageObject>
{
   struct CAAnimationStorage   _animationStorage;
}

- (struct CAAnimationStorage *) animationStorage;

// -getAnimations:maxCount:animationID:animationObject: is inherited from
// the CAAnimationStorageObject mixin.

- (NSUInteger) numberOfActiveAnimations;
- (NSUInteger) numberOfRunningAnimations;
- (NSUInteger) numberOfFinishedAnimations;

@end
