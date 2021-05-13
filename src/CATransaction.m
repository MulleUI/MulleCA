//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CATransaction.h"

#import "import-private.h"

#import "CAAnimation.h"


@implementation CATransaction

static struct
{
   mulle_thread_tss_t   thread_key;
} Self;


//
// need to run this in +load so that CATransactionGetCurrentTransactionManager
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


id     CATransactionGetCurrentTransactionManager( void)
{
   return( mulle_thread_tss_get( Self.thread_key));
}


void   CATransactionSetCurrentTransactionManager( id p)
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
   _mulle_pointerarray_done( &_animatedObjects);
   [super dealloc];
}


- (void) reset
{
   _mulle_pointerarray_reset( &_animatedObjects);

   _animationDelay              = 0.0;
   _animationDuration           = 2.0;
   _animationRepeatCount        = 0.0;
   _animationAutoreverses       = NO;

   // keep delegate ? NO
   _animationDelegate           = nil;
   _animationWillStartSelector  = 0;
   _animationDidStopSelector    = 0;

   MulleObjCObjectSetDuplicatedCString( self, &_animationID, NULL);

   _animationID = NULL;
   _context     = NULL;

   mulle_thread_tss_set( Self.thread_key, NULL);
}


- (void) begin
{
   assert( mulle_thread_tss_get( Self.thread_key) == NULL);

   _state = CATransactionStarted;
   mulle_thread_tss_set( Self.thread_key, self);
}


- (void) commit
{
   char                                  *animationID;
   id                                    delegate;
   id <CAImplicitlyAnimatableObject>     obj;
   MulleAnimationDelegate                *animationDelegate;
   SEL                                   didEnd;
   SEL                                   willStart;
   struct CAAnimationParameters          parameters;
   struct mulle_pointerarray             tmp;
   struct mulle_pointerarrayenumerator   rover;
   void                                  *context;

   assert( _state == CATransactionStarted);

   _state = CATransactionCommitting;

   animationDelegate = nil;
   if( _animationDelegate)
   {
      animationDelegate = [[MulleAnimationDelegate new] autorelease];
      [animationDelegate setIdentifier:_animationID];
      [animationDelegate setContext:_context];
      [animationDelegate setDelegate:_animationDelegate];
      [animationDelegate setAnimationWillStartSelector:_animationWillStartSelector];
      [animationDelegate setAnimationDidStopSelector:_animationDidStopSelector];
   }

   parameters.animationDelay        = _animationDelay;
   parameters.animationDuration     = _animationDuration;
   parameters.animationRepeatCount  = _animationRepeatCount;
   parameters.animationCurve        = _animationCurve;
   parameters.animationAutoreverses = _animationAutoreverses;

   rover = mulle_pointerarray_enumerate( &_animatedObjects);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
   {
      [obj commitImplicitAnimationsWithID:_animationID
                                 delegate:animationDelegate
                               parameters:&parameters]; // either UIView class or CATransaction
   }
   mulle_pointerarrayenumerator_done( &rover);

   //
   // TODO: we need a special kind of animation that is actually just calling
   //       the delegate at appropriate times. This animation needs to be
   //       part of a obj ? Window obj ? Or some completely different
   //       mechanism ?
   //

   [self reset];
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


- (void) setAnimationID:(char *) s
{
   MulleObjCObjectSetDuplicatedCString( self, &_animationID, s);
}


- (char *) animationID
{
   return( _animationID);
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

@end
