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
- (BOOL) hasLayoutChangingAnimations;

- (void) addAnimation:(id <CAAnimation>) animation;
- (void) removeAnimation:(id <CAAnimation>) animation;
- (void) resetAllAnimations;
- (void) removeAllAnimations;
- (void) resetAnimationsForAnimationObject:(id) animationObject;
- (void) removeAnimationsForAnimationObject:(id) animationObject;

// return YES if animating
- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) renderTime
                   animationRate:(mulle_relativetime_t) animationRate;

- (CAAnimation *) animationWithAnimationID:(char *) s;

- (char *) UTF8String;

// debugs support
- (NSUInteger) _numberOfAnimationsWithStateBitsSet:(NSUInteger) setBits
                                  stateBitsCleared:(NSUInteger) clrBits;

- (void) mulleGainAccessToAnimations            MULLE_OBJC_THREADSAFE_METHOD;
- (void) mulleRelinquishAccessToAnimations      MULLE_OBJC_THREADSAFE_METHOD;

PROTOCOLCLASS_END()


@interface CAAnimation( CAAnimationStorageObject)

- (NSUInteger) _numberOfAnimationsWithStateBitsSet:(NSUInteger) setBits
                                  stateBitsCleared:(NSUInteger) clrBits;

@end


#define CAAnimationStorageObjectIvars                      \
   struct CAAnimationStorage   _animationStorage


#define CAAnimationStorageObjectInterface                  \
- (struct CAAnimationStorage *) animationStorage           \

//
// not sure,if this is a good idea
//
#define CAAnimationStorageObjectImplementation             \
- (struct CAAnimationStorage *) animationStorage           \
{                                                          \
   return( &_animationStorage);                            \
}                                                          \
extern void   CAAnimationStorageImplementationDummyNotActuallyPresent( void)


// the dummy is just there so we can add a semicolon


