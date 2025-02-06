//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CATransaction.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CAAnimationGroup.h"
#import "CAImplicitlyAnimatableObject.h"


@interface CAAnimation( Private)

- (void) setAnimationOptions:(struct CAAnimationOptions *) options;

@end



@implementation CATransaction

mulle_thread_tss_t   CATransactionThreadKey;



//
// need to run this in +load so that CATransactionGetCurrentTransaction
// can be called
//
+ (void) load
{
   if( mulle_thread_tss_create( 0, &CATransactionThreadKey))
      abort();
}


+ (void) unload
{
   mulle_thread_tss_free( CATransactionThreadKey);
}


- (instancetype) init
{
   _mulle_pointerarray_init( &_animatedObjects, 16, NULL);
   return( self);
}


- (void) dealloc
{
   [_animationGroup release];
   _mulle_pointerarray_done( &_animatedObjects);
   [super dealloc];
}


- (void) reset
{
   [_animationGroup autorelease];
   _animationGroup = nil;

   _state = CATransactionIdle;

   _mulle_pointerarray_reset( &_animatedObjects);
   CATransactionSetCurrentTransaction( NULL);
}


- (void) begin
{
   assert( _state == CATransactionIdle);

   _state          = CATransactionStarted;
   _animationGroup = [CAAnimationGroup new];
   CATransactionSetCurrentTransaction( self);
}


//
// TODO: Extend this to have chained animation groups, so that you can have
//       more complex animations.
//
// During the commit more animated objects may get added. As they are
// added in the back, this will not impede us. Instead they will be
// picked up as well.
//
- (CAAnimationGroup *) commit
{
   id <CAImplicitlyAnimatableObject>     obj;
   CAAnimationGroup                      *group;
   struct CAAnimationOptions             options;

   assert( _state == CATransactionStarted);


   group = _animationGroup;
   _state = CATransactionCommitting;

   // if we set the transaction to NULL here already, this stops
   // the snapshot generation
   CATransactionSetCurrentTransaction( NULL);
   {

      mulle_pointerarray_for( &_animatedObjects, obj)
      {
         [obj commitImplicitAnimations:group];
      }

      [group setupAnimationOptions:&options];
      [group setAnimationOptions:&options];

      // autoreleases _animationGroup and zeroes ivar
      [self reset];
   }

   return( group);
}


- (BOOL) areAnimationsEnabled
{
   return( _state != CATransactionIdle);
}


//
//
//
- (void) addAnimatableObject:(id <CAImplicitlyAnimatableObject>) obj
{
   assert( obj);
   assert( [(NSObject *) obj respondsToSelector:@selector( commitImplicitAnimations:)]);
   assert( _state >= CATransactionStarted && _state <= CATransactionCommitting);
   assert( _mulle_pointerarray_find( &_animatedObjects, obj) == mulle_not_found_e);
   _mulle_pointerarray_add( &_animatedObjects, obj);
}


- (void) removeAnimatableObject:(id <CAImplicitlyAnimatableObject>) obj
{
   uintptr_t   i;

   assert( _state >= CATransactionStarted && _state <= CATransactionCommitting);

   i = _mulle_pointerarray_find( &_animatedObjects, obj);
   if( i != mulle_not_found_e)
      _mulle_pointerarray_remove_in_range( &_animatedObjects, mulle_range_make( i, 1));
}


// forward dynamic properties to animationGroup
- (void *) forward:(void *) param
{
   assert( _animationGroup);
   return( mulle_objc_object_call_variable_inline( _animationGroup,
                                                          (mulle_objc_methodid_t) _cmd,
                                                          param));
}

@end
