//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
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
