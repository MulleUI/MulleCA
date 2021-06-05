//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CATransaction.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CAAnimationGroup.h"


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

   _mulle_pointerarray_reset( &_animatedObjects);
   mulle_thread_tss_set( Self.thread_key, NULL);
}


- (void) begin
{
   _state = CATransactionStarted;
   _animationGroup = [CAAnimationGroup new];
   mulle_thread_tss_set( Self.thread_key, self);
}


//
// TODO: Extend this to have chained animation groups, so that you can have
//       more complex animations.
//
- (void) commit
{
   id <CAImplicitlyAnimatableObject>     obj;
   struct mulle_pointerarrayenumerator   rover;

   assert( _state == CATransactionStarted);

   _state = CATransactionCommitting;
   {
      rover = mulle_pointerarray_enumerate( &_animatedObjects);
      while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
      {
         [obj commitImplicitAnimationsWithAnimationGroup:_animationGroup];
      }
      mulle_pointerarrayenumerator_done( &rover);

      [self reset];
   }
   _state = CATransactionIdle;
}


- (void) cancel
{
   [self reset];
   _state = CATransactionIdle;
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
   assert( [(NSObject *) obj conformsToProtocol:@protocol( CAImplicitlyAnimatableObject)]);

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
