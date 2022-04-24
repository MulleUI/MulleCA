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


- (void) dealloc
{
   [self removeAllAnimations];
   [super dealloc];
}

@end
