//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CAAnimationStorage.h"

#import "import-private.h"


#ifdef DEBUG
//#define DEBUG_VERBOSE
#endif


@implementation  CAAnimationStorageObject

- (id) initAnimationStorage
{
   struct mulle_allocator     *allocator;
   struct CAAnimationStorage  *storage;

   storage = [self animationStorage];

   allocator = MulleObjCInstanceGetAllocator( self);
   _mulle_pointerarray_init( &storage->_animations, 0, allocator);

   return( self);
}


- (void) deallocAnimationStorage
{
   struct CAAnimationStorage  *storage;

   storage = [self animationStorage];
   _mulle_pointerarray_done( &storage->_animations);
}


/*
 * Animations storage and management
 */
- (BOOL) hasAnimations
{
   struct CAAnimationStorage   *storage;

   storage = [self animationStorage];
   return( storage->_numberOfAnimations != 0);
}


- (NSUInteger) numberOfAnimations
{
   struct CAAnimationStorage   *storage;

   storage = [self animationStorage];
   return( storage->_numberOfAnimations);
}


- (BOOL) hasRunningAnimations
{
   BOOL                        flag;
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;

   flag    = NO;
   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( animation && ! [animation hasEnded])
      {
         flag = YES;
         break;
      }
   }
   return( flag);
}


- (BOOL) hasLayoutChangingAnimations
{
   BOOL                        flag;
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;

   flag    = NO;
   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( [animation changesLayout])
      {
         flag = YES;
         break;
      }
   }
   return( flag);
}


- (void) addAnimation:(id <CAAnimation>) animation
{
   struct CAAnimationStorage   *storage;

   assert( animation);

#ifdef DEBUG_VERBOSE
   MulleUILog( "add animation %#@", animation);
#endif
   storage = [self animationStorage];
   assert( _mulle_pointerarray_find( &storage->_animations, animation) == mulle_not_found_e);

   _mulle_pointerarray_add( &storage->_animations, [animation retain]);
   storage->_numberOfAnimations++;
}


- (void) removeAnimation:(id <CAAnimation>) animation
{
   struct CAAnimationStorage   *storage;
   uintptr_t                   index;
   unsigned int                n;

   storage = [self animationStorage];

   index = _mulle_pointerarray_find( &storage->_animations, animation);
   if( index == mulle_not_found_e)
      return;

#ifdef DEBUG_VERBOSE
   MulleUILog( "remove animation %#@", self, animation);
#endif

   if( ! --storage->_numberOfAnimations)
      [self removeAllAnimations];
   else
   {
      [animation autorelease];
      mulle_pointerarray_set( &storage->_animations, (unsigned int) index, NULL);

      // if we have too many holes, performance will suffer, so do not accept
      // too many holes (don't bother with tiny arrays)
      n = _mulle_pointerarray_get_count( &storage->_animations);
      if( n >= 8 && n >= storage->_numberOfAnimations * 2)
         mulle_pointerarray_compact( &storage->_animations, NULL);
   }
}


- (void) resetAnimationsForAnimationObject:(id) animationObject
{
   id <CAAnimation>            animation;
   struct CAAnimationStorage   *storage;

   storage = [self animationStorage];

   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( [animation animationObject] == animationObject)
         [animation reset];
   }
}


- (void) resetAllAnimations
{
   id <CAAnimation>            animation;
   struct CAAnimationStorage   *storage;

   storage = [self animationStorage];

   mulle_pointerarray_for( &storage->_animations, animation)
   {
      [animation reset];
   }
}


- (void) removeAnimationsForAnimationObject:(id) animationObject
{
   id <CAAnimation>            animation;
   struct CAAnimationStorage   *storage;
   struct mulle_allocator      *allocator;
   NSUInteger                  i, n;
   NSUInteger                  removed;

   storage = [self animationStorage];

   removed = 0;
   // use a C for loop, as we are mutating the array inside it
   n = mulle_pointerarray_get_count( &storage->_animations);
   for( i = 0; i < n; i++)
   {
      animation = mulle_pointerarray_get( &storage->_animations, i);
      if( [animation animationObject] == animationObject)
      {
         [animation autorelease];

         // we are zeroing in the middle off the enumeration, this will
         // trigger a mutation check and crash, therefore we gotta be a bit
         // sneaky (this is fine, since we are just autoreleasing)
         mulle_pointerarray_set( &storage->_animations, (unsigned int) i, NULL);
         removed++;
      }
   }
   storage->_numberOfAnimations -= removed;

   if( ! storage->_numberOfAnimations)
   {
      allocator = mulle_pointerarray_get_allocator( &storage->_animations);
      _mulle_pointerarray_done( &storage->_animations);
      _mulle_pointerarray_init( &storage->_animations, 0, allocator);
   }
}


- (void) removeAllAnimations
{
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;
   struct mulle_allocator      *allocator;

   storage   = [self animationStorage];
   allocator = mulle_pointerarray_get_allocator( &storage->_animations);

   mulle_pointerarray_for( &storage->_animations, animation)
   {
      [animation autorelease];
   }

   _mulle_pointerarray_done( &storage->_animations);
   _mulle_pointerarray_init( &storage->_animations, 0, allocator);

   storage->_numberOfAnimations = 0;
}


- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) now
                   animationRate:(mulle_relativetime_t) animationRate
{
   CAAnimation                 *animation;
   NSUInteger                  n_deletions;
   struct CAAnimationStorage   *storage;
   struct mulle_pointerarray   deletions;
   id                          target;
   BOOL                        hasAnimations;
   CAAnimationReturnState      state;

   storage = [self animationStorage];

#ifdef DEBUG_VERBOSE
   MulleUILog( "now=%.6f numberOfAnimations=%ld",
                now, storage->_numberOfAnimations);
#endif

   if( ! storage->_numberOfAnimations)
      return( NO);

   // assume deletion is a rare occurrence
   mulle_pointerarray_init( &deletions, 0, NULL);
   {
      hasAnimations = NO;
      // animate all animations, collect those that are finished
      mulle_pointerarray_for( &storage->_animations, animation)
      {
         target = [animation animationObject];
         state  = [animation animateObject:target ? target : self
                              absoluteTime:now
                             animationRate:animationRate];

         if( state == CAAnimationReturnStateDone)
         {
            if( [animation isRemovedOnCompletion])
            {
#ifdef DEBUG_VERBOSE
               MulleUILog( "schedule animation %#@ for deletion", animation);
#endif
               mulle_pointerarray_add( &deletions, animation);
            }
         }
         else
            hasAnimations = YES;
      }

      // remove finished animations
      n_deletions = mulle_pointerarray_get_count( &deletions);
      if( n_deletions)
      {
         // likely quite common, and this is easier
         if( n_deletions == storage->_numberOfAnimations)
         {
            [self removeAllAnimations];
         }
         else
         {
            mulle_pointerarray_for( &deletions, animation)
            {
               [self removeAnimation:animation];
            }
         }
      }
   }
   mulle_pointerarray_done( &deletions);

   return( hasAnimations);
}


- (NSUInteger) _numberOfAnimationsWithStateBitsSet:(NSUInteger) setBits
                                  stateBitsCleared:(NSUInteger) clrBits
{
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;
   NSUInteger                  count;

   storage = [self animationStorage];
   count   = 0;
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      count += [animation _numberOfAnimationsWithStateBitsSet:setBits
                                            stateBitsCleared:clrBits];
   }

   return( count);
}


- (void) mulleGainAccessToAnimationsWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;

   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( mulle_pointerset_insert( uniquing, animation))
         [animation mulleGainAccessWithUniquingSet:uniquing];
   }
}


- (void) mulleRelinquishAccessToAnimationsWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   CAAnimation                 *animation;
   struct CAAnimationStorage   *storage;

   storage = [self animationStorage];
   mulle_pointerarray_for( &storage->_animations, animation)
   {
      if( mulle_pointerset_insert( uniquing, animation))
         [animation mulleRelinquishAccessWithUniquingSet:uniquing];
   }
}


@end


@implementation CAAnimation( CAAnimationStorageObject)

- (NSUInteger) _numberOfAnimationsWithStateBitsSet:(NSUInteger) setBits
                                  stateBitsCleared:(NSUInteger) clrBits
{
   NSUInteger   state;

   state = self->_state.bits;
   if( (state & clrBits) != 0)
      return( 0);
   if( (state & setBits) != setBits)
      return( 0);

   return( 1);
}

@end