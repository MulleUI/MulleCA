//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "import.h"


#import "CAAnimationStorage.h"

//
// The CAAnimator just stores CAAnimations and when asked to animate,
// animates them. CAAnimationGroups are CAAnimations, that get created by
// CATransactions.
//
//                          .------------.
//                    .-----| CAAnimator |-----------------------.
//                    |     '------------'                       |
//                    v           |                              v
//          .------------------.  |    .-------------.  .------------------.
//        .-| CAAnimationGroup |  '--->| CAAnimation |  | CAAnimationGroup |
//        | '------------------'       '-------------'  '------------------'
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
@end
