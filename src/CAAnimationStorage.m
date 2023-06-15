//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CAAnimationStorage.h"

#import "import-private.h"


#ifdef DEBUG
//#define DEBUG_VERBOSE
#endif


PROTOCOLCLASS_IMPLEMENTATION( CAAnimationStorageObject)


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
   struct CAAnimationStorage            *storage;

   storage = [self animationStorage];
   return( storage->_numberOfAnimations != 0);
}


- (NSUInteger) numberOfAnimations
{
   struct CAAnimationStorage            *storage;

   storage = [self animationStorage];
   return( storage->_numberOfAnimations);
}


- (BOOL) hasRunningAnimations
{
   BOOL                                 flag;
   CAAnimation                          *animation;
   struct CAAnimationStorage            *storage;
   struct mulle_pointerarrayenumerator  rover;

   flag    = NO;
   storage = [self animationStorage];
   rover   = mulle_pointerarray_enumerate( &storage->_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
      if( animation && ! [animation hasEnded])
      {
         flag = YES;
      }
   mulle_pointerarrayenumerator_done( &rover);
   return( flag);
}


- (void) addAnimation:(id <CAAnimation>) animation
{
   struct CAAnimationStorage   *storage;

   assert( animation);

#ifdef DEBUG_VERBOSE
   fprintf( stderr, "%s %s receives animation %p\n", __PRETTY_FUNCTION__,
                        [self UTF8String], animation);
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

   storage = [self animationStorage];

   index = _mulle_pointerarray_find( &storage->_animations, animation);
   if( index == mulle_not_found_e)
      return;

   if( ! --storage->_numberOfAnimations)
      [self removeAllAnimations];
   else
   {
      [animation autorelease];
      mulle_pointerarray_set( &storage->_animations, (unsigned int) index, NULL);
   }
}

- (void) resetAnimationsForAnimationObject:(id) animationObject
{
   struct mulle_pointerarrayenumerator   rover;
   id <CAAnimation>                      animation;
   struct CAAnimationStorage             *storage;

   storage = [self animationStorage];

   rover = mulle_pointerarray_enumerate( &storage->_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
   {
      if( [animation animationObject] == animationObject)
         [animation reset];
   }
   mulle_pointerarrayenumerator_done( &rover);
}


- (void) resetAllAnimations
{
   struct mulle_pointerarrayenumerator   rover;
   id <CAAnimation>                      animation;
   struct CAAnimationStorage             *storage;

   storage = [self animationStorage];

   rover = mulle_pointerarray_enumerate( &storage->_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
      [animation reset];
   mulle_pointerarrayenumerator_done( &rover);
}


- (void) removeAnimationsForAnimationObject:(id) animationObject
{
   struct mulle_pointerarrayenumerator   rover;
   id <CAAnimation>                      animation;
   struct CAAnimationStorage             *storage;
   struct mulle_allocator                *allocator;
   NSUInteger                            index;

   storage = [self animationStorage];

   index = 0;
   rover = mulle_pointerarray_enumerate( &storage->_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
   {
      if( [animation animationObject] == animationObject)
      {
         assert( index == _mulle_pointerarray_find( &storage->_animations, animation));

         [animation autorelease];
         mulle_pointerarray_set( &storage->_animations, (unsigned int) index, NULL);
         storage->_numberOfAnimations--;
      }
      ++index;
   }
   mulle_pointerarrayenumerator_done( &rover);

   if( ! storage->_numberOfAnimations)
   {
      allocator = mulle_pointerarray_get_allocator( &storage->_animations);
      _mulle_pointerarray_done( &storage->_animations);
      _mulle_pointerarray_init( &storage->_animations, 0, allocator);
   }
}

- (void) removeAllAnimations
{
   struct mulle_pointerarrayenumerator   rover;
   CAAnimation                           *animation;
   struct CAAnimationStorage             *storage;
   struct mulle_allocator                *allocator;

   storage   = [self animationStorage];
   allocator = mulle_pointerarray_get_allocator( &storage->_animations);

   rover = mulle_pointerarray_enumerate( &storage->_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
      [animation autorelease];
   mulle_pointerarrayenumerator_done( &rover);

   _mulle_pointerarray_done( &storage->_animations);
   _mulle_pointerarray_init( &storage->_animations, 0, allocator);

   storage->_numberOfAnimations = 0;
}


- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) now
                   animationRate:(mulle_relativetime_t) animationRate
{
   CAAnimation                           *animation;
   NSUInteger                            n_animations;
   NSUInteger                            n_deletions;
   struct CAAnimationStorage             *storage;
   struct mulle_pointerarray             deletions;
   struct mulle_pointerarrayenumerator   rover;
   id                                    target;
   BOOL                                  flag;
   CAAnimationState                      state;

   storage = [self animationStorage];
   n_animations = mulle_pointerarray_get_count( &storage->_animations);
   if( ! n_animations)
      return( NO);

#ifdef DEBUG_VERBOSE
   fprintf( stderr, "%.5f: %s %s (%ld)\n",
               now, __PRETTY_FUNCTION__, [self UTF8String], n_animations);
#endif

   // assume deletion is a rare occurrence
   mulle_pointerarray_init( &deletions, 0, NULL);

   flag  = NO;
   // animate all animations, collect those that are finished
   rover = mulle_pointerarray_enumerate( &storage->_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
   {
      target = [animation animationObject];
      state  = [animation animateObject:target ? target : self
                           absoluteTime:now
                          animationRate:animationRate];
      if( state == CAAnimationStateDone)
      {
         if( [animation isRemovedOnCompletion])
            mulle_pointerarray_add( &deletions, animation);
      }
      else
         flag = YES;
   }
   mulle_pointerarrayenumerator_done( &rover);

   // remove finished animations
   n_deletions = mulle_pointerarray_get_count( &deletions);
   if( n_deletions)
   {
      // likely quite common, and this is easier
      if( n_deletions == n_animations)
      {
         [self removeAllAnimations];
      }
      else
      {
         rover = mulle_pointerarray_enumerate( &deletions);
         while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
            [self removeAnimation:animation];
         mulle_pointerarrayenumerator_done( &rover);
      }
   }
   mulle_pointerarray_done( &deletions);

   return( flag);
}


PROTOCOLCLASS_END()
