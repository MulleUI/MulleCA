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


//
// if maxCount is zero, nothing will be written, but the number of
// animations matching will be returned.
//
- (NSUInteger) getAnimations:(CAAnimation **) animations
                    maxCount:(NSUInteger) maxCount
                 animationID:(char *) animationID
             animationObject:(id) animationObject;

- (void) finishAnimationsWithAnimationID:(char *) animationID
                         animationObject:(id) animationObject;

- (NSUInteger) numberOfActiveAnimations;
- (NSUInteger) numberOfRunningAnimations;
- (NSUInteger) numberOfFinishedAnimations;

@end
