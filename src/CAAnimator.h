//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
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
