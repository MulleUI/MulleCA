//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "import.h"

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


PROTOCOLCLASS_INTERFACE0( CAAnimationStorageObject)

- (struct CAAnimationStorage *) animationStorage;

@optional

// call this in your -init (and -copy if you do NSCopying)
// self is returned unchanged as a convenience
- (id) initAnimationStorage;

// call this in your -dealloc
- (void) deallocAnimationStorage;

- (BOOL) hasAnimations;
- (NSUInteger) numberOfAnimations;
- (BOOL) hasRunningAnimations;
- (void) addAnimation:(id <CAAnimation>) animation;
- (void) removeAnimation:(id <CAAnimation>) animation;
- (void) resetAllAnimations;
- (void) removeAllAnimations;
- (void) resetAnimationsForAnimationObject:(id) animationObject;
- (void) removeAnimationsForAnimationObject:(id) animationObject;

- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) renderTime
                   animationRate:(mulle_relativetime_t) animationRate;

PROTOCOLCLASS_END()

