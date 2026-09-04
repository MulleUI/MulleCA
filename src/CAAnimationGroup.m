//
//  CAAnimationGroup.m
//  MulleCA
//
//  Copyright (c) 2019 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
