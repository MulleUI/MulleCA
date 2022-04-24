//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//

#import "CAAnimation.h"


//
// Animatable objects, like CALayer need to store the animations
// This protocolclass does just that and also implements
// -animateWithAbsoluteTime:
//
// So the only thing a CALayer needs to implement itself is the
// creation of animations during a CATransaction (implicit animations)
//
struct CAAnimationStorage
{
   NSUInteger                  _numberOfAnimations;
   struct mulle_pointerarray   _animations;
};


PROTOCOLCLASS_INTERFACE( CAAnimationStorageObject, CAAnimatableObject)

- (struct CAAnimationStorage *) animationStorage;

@optional

- (BOOL) hasAnimations;
- (NSUInteger) numberOfAnimations;
- (BOOL) hasRunningAnimations;
- (void) addAnimation:(CAAnimation *) animation;
- (void) removeAnimation:(CAAnimation *) animation;
- (void) removeAllAnimations;
- (void) removeAnimationsForAnimationObject:(id) animationObject;

// this could move to CAAnimator maybe, it's a little weird to have the
// storage adopt CAAnimatableObject
- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) renderTime;

PROTOCOLCLASS_END()

