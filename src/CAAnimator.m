//
//  CAAnimator.m
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
#import "CAAnimator.h"

#import "import-private.h"


// everything is done by CAAnimationStorageObject for us
@implementation CAAnimator

- (struct CAAnimationStorage *) animationStorage
{
   return( &_animationStorage);
}


- (id) init
{
   self = [self initAnimationStorage];
   return( self);
}

// - (void) finalize
// {
//    [self removeAllAnimations];
//    [super finalize];
// }


- (void) dealloc
{
   [self removeAllAnimations];
   [self deallocAnimationStorage];
   [super dealloc];
}


//
// if maxCount is zero, nothing will be written, but the number of
// animations matching will be returned.
//
// (moved to CAAnimationStorage's mixin implementation, so every
// CAAnimationStorageObject conformer — not just CAAnimator — gets this
// for free)


- (NSUInteger) numberOfActiveAnimations
{
   return( [self _numberOfAnimationsWithStateBitsSet:CAAnimationStarted
                                    stateBitsCleared:CAAnimationEnded]);
}


- (NSUInteger) numberOfRunningAnimations
{
   return( [self _numberOfAnimationsWithStateBitsSet:CAAnimationAnimating
                                    stateBitsCleared:0]);
}


- (NSUInteger) numberOfFinishedAnimations
{
   return( [self _numberOfAnimationsWithStateBitsSet:CAAnimationEnded
                                    stateBitsCleared:0]);
}

- (void) mulleGainAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   [super mulleGainAccessWithUniquingSet:uniquing];
   [self mulleGainAccessToAnimationsWithUniquingSet:uniquing];
}


- (void) mulleRelinquishAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   [self mulleRelinquishAccessToAnimationsWithUniquingSet:uniquing];
   [super mulleRelinquishAccessWithUniquingSet:uniquing];
}

@end
