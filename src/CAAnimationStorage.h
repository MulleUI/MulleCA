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
   NSUInteger                  _numberOfAnimations; // probably an optimization
   struct mulle_pointerarray   _animations;
};


@mixin CAAnimationStorageObject

@required
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

// Finish all animations matching animationID: jump to final value.
- (void) finishAnimationsWithAnimationID:(char *) animationID;

// Cancel all animations matching animationID: revert to start value.
- (void) cancelAnimationsWithAnimationID:(char *) animationID;

// if maxCount is zero, nothing will be written, but the number of
// animations matching will be returned. Either animationID or
// animationObject (or both) may be NULL/nil to skip that filter.
- (NSUInteger) getAnimations:(CAAnimation **) animations
                    maxCount:(NSUInteger) maxCount
                 animationID:(char *) animationID
             animationObject:(id) animationObject;

// return YES if animating
- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) renderTime
                   animationRate:(mulle_relativetime_t) animationRate;


// debugs support
- (NSUInteger) _numberOfAnimationsWithStateBitsSet:(NSUInteger) setBits
                                  stateBitsCleared:(NSUInteger) clrBits;

- (void) mulleGainAccessToAnimationsWithUniquingSet:(struct mulle_pointerset *) uniquing         MULLE_OBJC_THREADSAFE_METHOD;
- (void) mulleRelinquishAccessToAnimationsWithUniquingSet:(struct mulle_pointerset *) uniquing   MULLE_OBJC_THREADSAFE_METHOD;

@end


@interface CAAnimation( CAAnimationStorageObject)

- (NSUInteger) _numberOfAnimationsWithStateBitsSet:(NSUInteger) setBits
                                  stateBitsCleared:(NSUInteger) clrBits;

@end


#define CAAnimationStorageObjectIvars \
   struct CAAnimationStorage   _animationStorage

#define CAAnimationStorageObjectProperties

// so do we want to copy the animations or not ? one a case per case
// basis we may, so we implement it here and then just don't use it if you
// don't want it
#define CAAnimationStorageObjectCopy( dst, src)                            \
   do                                                                      \
   {                                                                       \
      struct mulle_allocator      *allocator;                              \
      struct CAAnimationStorage   *dstStorage = &(dst)->_animationStorage; \
      struct CAAnimationStorage   *srcStorage = &(src)->_animationStorage; \
                                                                           \
      allocator = MulleObjCInstanceGetAllocator( dst);                     \
      _mulle_pointerarray_init( &dstStorage->_animations, 0, allocator);   \
      _mulle_pointerarray_add_pointerarray( &dstStorage->_animations,      \
                                            &srcStorage->_animations,      \
                                            mulle_range_make_all());       \
      dstStorage->_numberOfAnimations = srcStorage->_numberOfAnimations;   \
   }                                                                       \
   while( 0)

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


