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

// consider this "private"
- (void) setAnimationOptions:(struct CAAnimationOptions *) options;

// this is actually in our protocolclass, but compiler don't know it
- (BOOL) animateWithAbsoluteTime:(mulle_absolutetime_t) time
                   animationRate:(mulle_relativetime_t) animationRate;
@end



@implementation CAAnimationGroup

- (void) dealloc
{
   [self removeAllAnimations];

   MulleObjCObjectSetDuplicatedUTF8String( self, &_animationID, NULL);
   [super dealloc];
}


- (struct CAAnimationStorage *) animationStorage
{
   return( &_animationStorage);
}


- (void) setAnimationID:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_animationID, s);
}


- (char *) animationID
{
   return( _animationID);
}


- (BOOL) changesLayout
{
   return( [self hasLayoutChangingAnimations]);
}

/*
 *
 */
- (void) willStartAnimating
{
   if( _animationWillStartSelector)
      [_animationDelegate performSelector:_animationWillStartSelector
                               withObject:(id) _animationID
                               withObject:_context];
}


- (void) animateObject:(id) object
normalizedRelativeTime:(mulle_relativetime_t) t
           elapsedTime:(mulle_relativetime_t) elapsedTime
{
   // do nothing here
}


- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
   NSUInteger   state;
   NSUInteger   bits;

   CAAnimationLogVerbose( "object=%#@ now=%.6f (animations=%td)",
                              object, now, [self numberOfAnimations]);

   bits  = _state.bits;
   state = [super animateObject:nil
                   absoluteTime:now
                  animationRate:animationRate];

   // CAAnimationStorage animator
   [self animateWithAbsoluteTime:now
                   animationRate:animationRate];

   // we like to call this after the constituent animations have run,
   // so use a separate logic here than -didEnd
   if( ((bits ^ _state.bits) & CAAnimationEnded) == CAAnimationEnded)
   {
      if( _animationDidStopSelector)
         [_animationDelegate performSelector:_animationDidStopSelector
                                  withObject:(id) _animationID
                                  withObject:_context];
   }
   return( state);
}


- (void) reset
{
   [self resetAllAnimations];
   [super reset];
}

@end


@implementation CAAnimationGroup( CAAnimation)

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


// rename to something else than set, here
- (void) setupAnimationOptions:(struct CAAnimationOptions *) options
{
   memset( options, 0, sizeof( *options));
   setupAnimationOptions( self, options);
}

@end


@implementation CAAnimationGroup( CABasicAnimation)

- (void) setupBasicAnimationOptions:(struct CABasicAnimationOptions *) options
{
   memset( options, 0, sizeof( *options));

   setupAnimationOptions( self, &options->base);
   options->tween = _animationTweenFunction;
   if( ! options->tween)
      options->curve  = _animationCurve;
}

@end

