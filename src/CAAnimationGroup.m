//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CAAnimationGroup.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CABasicAnimation.h"


#ifdef DEBUG
//#define DEBUG_VERBOSE
#endif


@interface CAAnimation( Private)

- (void) willStartAnimating;
- (BOOL) didEnd;

// consider this "private"
- (void) setAnimationOptions:(struct CAAnimationOptions *) options;

// this is actually in our protocolclass, but compiler don't know it
- (BOOL) animateWithAbsoluteTime:(CAAbsoluteTime) time;
@end



@implementation CAAnimationGroup


- (id) init
{
   _animationDuration = 2.0;
   return( self);
}


extern const struct CAAnimationOptions   CAAnimationDefaultOptions;



- (void) dealloc
{
   [self removeAllAnimations];

   MulleObjCInstanceDeallocateMemory( self, _animationID);
   [super dealloc];
}


- (struct CAAnimationStorage *) animationStorage
{
   return( &_animationStorage);
}


- (void) setAnimationID:(char *) s
{
   MulleObjCObjectSetDuplicatedCString( self, &_animationID, s);
}


- (char *) animationID
{
   return( _animationID);
}


/*
 *
 */
- (void) willStartAnimating
{
   [super willStartAnimating];

   if( _animationWillStartSelector)
      [_animationDelegate performSelector:_animationWillStartSelector
                               withObject:(id) _animationID
                               withObject:_context];
}


// returns YES, if really ended (reverse flag is confusing to me)
- (BOOL) didEnd
{
   BOOL   flag;

   flag = [super didEnd];

   if( flag && _animationDidStopSelector)
      [_animationDelegate performSelector:_animationDidStopSelector
                               withObject:(id) _animationID
                               withObject:_context];
   return( flag);
}


- (BOOL) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now
{
   BOOL   flag;

#ifdef DEBUG_VERBOSE
   fprintf( stderr, "%.5f: %s %s (%ld)\n",
               now, __PRETTY_FUNCTION__, [self cStringDescription], n_animations);
#endif
   if( ! (_bits & CAAnimationStarted))
   {
      [self willStartAnimating];
   }
   // animate self to get bits set, otherwise

   if( ! (_bits & CAAnimationEnded))
   {
      // run animations of animations in group
      flag = [super animateWithAbsoluteTime:now];
      if( ! flag)
         [self didEnd];
   }

   return( (_bits & CAAnimationEnded) ? NO : YES);
}



@end


@implementation CAAnimationGroup( CAAnimation)

static inline void  setupAnimationOptions( CAAnimationGroup *self,
                                         struct CAAnimationOptions *options)
{
   options->timeRange   = CARelativeTimeRangeMake( self->_animationDelay, self->_animationDuration);
   options->repeatCount = self->_animationRepeatCount;
   options->bits        = (self->_animationAutoreverses ? CAAnimationReverses : 0) |
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
   options->tween     = _animationTweenFunction;
   if( ! options->tween)
      options->curve  = _animationCurve;
}

@end

