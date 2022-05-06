//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CATransaction.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CAAnimationGroup.h"




@interface CAAnimation( Private)

- (void) setAnimationOptions:(struct CAAnimationOptions *) options;

@end



@implementation CATransaction

static struct
{
   mulle_thread_tss_t   thread_key;
} Self;


//
// need to run this in +load so that CATransactionGetCurrentTransaction
// can be called
//
+ (void) load
{
   if( mulle_thread_tss_create( 0, &Self.thread_key))
      abort();
}


+ (void) unload
{
   mulle_thread_tss_free( Self.thread_key);
}


id   CATransactionGetCurrentTransaction( void)
{
   return( mulle_thread_tss_get( Self.thread_key));
}


void   CATransactionSetCurrentTransaction( id p)
{
   mulle_thread_tss_set( Self.thread_key, p);
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
   mulle_thread_tss_set( Self.thread_key, NULL);
}


- (void) begin
{
   assert( _state == CATransactionIdle);

   _state = CATransactionStarted;
   _animationGroup = [CAAnimationGroup new];
   mulle_thread_tss_set( Self.thread_key, self);
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
   struct mulle_pointerarrayenumerator   rover;
   CAAnimationGroup                      *group;
   struct CAAnimationOptions             options;

   assert( _state == CATransactionStarted);

   group = _animationGroup;
   _state = CATransactionCommitting;
   {
      rover = mulle_pointerarray_enumerate( &_animatedObjects);
      while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      {
         [obj commitImplicitAnimations:group];
      }
      mulle_pointerarrayenumerator_done( &rover);

      //
      [group setupAnimationOptions:&options];
      [group setAnimationOptions:&options];

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


// forward dynamic properties to animationGroup
- (void *) forward:(void *) param
{
   assert( _animationGroup);
   return( mulle_objc_object_call_variablemethodid_inline( _animationGroup,
                                                          (mulle_objc_methodid_t) _cmd,
                                                          param));
}


@end
