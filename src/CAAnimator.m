//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CAAnimator.h"

#import "import-private.h"


@implementation CAAnimation( CAAnimator)

- (char *) animationID
{
   return( NULL);
}

@end



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
- (NSUInteger) getAnimations:(CAAnimation **) animations
                    maxCount:(NSUInteger) maxCount
                 animationID:(char *) animationID
             animationObject:(id) animationObject
{
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;
   char                        *s;
   CAAnimation                 **p, **sentinel;
   id                          obj;

   storage  = [self animationStorage];
   p        = animations;
   sentinel = &p[ maxCount];

   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( animationObject)
      {
         obj = [animation animationObject];
         if( obj != animationObject)
            continue;
      }

      // if "NULL" this is CAAnimation leaf
      s = [animation animationID];
      if( ! s)
      {
         if( animationID)
            continue;
      }
      else
      {
         if( ! animationID || strcmp( s, animationID))
            continue;
      }

      if( p < sentinel)
         *p = animation;
      ++p;
   }
   return( p - animations);
}


- (void) finishAnimationsWithAnimationID:(char *) animationID
                         animationObject:(id) animationObject
{
   NSUInteger    n;
   CAAnimation   **p, **sentinel;

   mulle_flexarray_do( finishers, CAAnimation *, 32, 32)
   {
      n = [self getAnimations:finishers
                     maxCount:32
                  animationID:animationID
              animationObject:animationObject];
      if( n >= 32)
      {
         mulle_flexarray_realloc( finishers, n);
         n = [self getAnimations:finishers
                        maxCount:n
                     animationID:animationID
                 animationObject:animationObject];
      }

      sentinel = &finishers[ n];
      for( p = finishers; p < sentinel; p++)
         [*p finish];
   }
}


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

@end
