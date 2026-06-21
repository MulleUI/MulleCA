//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CAAnimationGroup.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CAAnimation+DebugPrivate.h"
#import "CABasicAnimation.h"


@interface CAAnimation( Private)

- (void) willStartAnimating;
- (BOOL) didEnd;

- (void) setAnimationOptions:(struct CAAnimationOptions *) options;

- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) time
                   animationRate:(mulle_relativetime_t) animationRate;
@end


@implementation CAAnimationGroup

//
// Override addAnimation: to NOT compute delays (parallel behavior).
// Just add directly to storage without touching the animation's delay.
//
- (void) addAnimation:(id <CAAnimation>) animation
{
   struct CAAnimationStorage   *storage;

   assert( animation);

   [(id) animation setRemovedOnCompletion:NO];

   storage = [self animationStorage];
   assert( _mulle_pointerarray_find( &storage->_animations, animation) == mulle_not_found_e);

   _mulle_pointerarray_add( &storage->_animations, [(id) animation retain]);
   storage->_numberOfAnimations++;
}


//
// Override removeAnimation: to NOT shift other animations.
//
- (void) removeAnimation:(id <CAAnimation>) animation
{
   struct CAAnimationStorage   *storage;
   uintptr_t                   index;

   storage = [self animationStorage];
   index   = _mulle_pointerarray_find( &storage->_animations, animation);
   if( index == mulle_not_found_e)
      return;

   _mulle_pointerarray_set( &storage->_animations, index, NULL);
   storage->_numberOfAnimations--;
   [(id) animation release];
}


- (void) setAnimationDelegate:(id) delegate
{
   [self setDelegate:delegate];
}


- (id) animationDelegate
{
   return( [self delegate]);
}

@end


@implementation CAAnimationGroup( CAAnimationOptions)

static inline void  setupAnimationOptions( CAAnimationGroup *self,
                                           struct CAAnimationOptions *options)
{
   options->timeRange        = mulle_relativetimerange_make( self->_animationDelay,
                                                             self->_animationDuration);
   options->offset           = self->_animationOffset;
   options->repeatCount      = self->_animationRepeatCount;
   options->bits             = (self->_animationAutoreverses ? CAAnimationReverses : 0) |
                               (self->_animationIsAdditive   ? CAAnimationAdditive : 0);
}


- (void) setupAnimationOptions:(struct CAAnimationOptions *) options
{
   memset( options, 0, sizeof( *options));
   setupAnimationOptions( self, options);
}

@end


@implementation CAAnimationGroup( CABasicAnimationOptions)

- (void) setupBasicAnimationOptions:(struct CABasicAnimationOptions *) options
{
   memset( options, 0, sizeof( *options));

   setupAnimationOptions( self, &options->base);
   options->tween = _animationTweenFunction;
   if( ! options->tween)
      options->curve  = _animationCurve;
}

@end
