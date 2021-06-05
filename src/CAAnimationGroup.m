//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CAAnimationGroup.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CABasicAnimation.h"


@implementation CAAnimationGroup


- (id) init
{
   _animationDuration = 2.0;
   return( self);
}


- (void) setAnimationID:(char *) s
{
   MulleObjCObjectSetDuplicatedCString( self, &_animationID, s);
}


- (char *) animationID
{
   return( _animationID);
}


- (void) dealloc
{
   MulleObjCInstanceDeallocateMemory( self, &_animationID);
   [super dealloc];
}



- (void) animationWillStart:(CAAnimation *) animation
{
   // if this is the first time we got this, then
   // send the delegate a message
   if( _startedCount++)
      return;

   if( _animationWillStartSelector)
      [_animationDelegate performSelector:_animationWillStartSelector
                               withObject:(id) _animationID
                               withObject:_context];
}


- (void) animationDidStop:(CAAnimation *) animation
{
   // if we got #animations messages, then the last one
   // to finish sends the delegate message (defensively coded, so it
   // only sends it once
   if( ++_endedCount != _startedCount)
   {
      assert( _endedCount == _startedCount);
      return;
   }

   if( _animationDidStopSelector)
      [_animationDelegate performSelector:_animationDidStopSelector
                               withObject:(id) _animationID
                               withObject:_context];
}

@end


@implementation CAAnimationGroup( CAAnimation)

static inline void  setAnimationOptions( CAAnimationGroup *self,
                                         struct CAAnimationOptions *options)
{
   options->timeRange   = CARelativeTimeRangeMake( self->_animationDelay, self->_animationDuration);
   options->repeatCount = self->_animationRepeatCount;
   options->bits        = (self->_animationAutoreverses ? CAAnimationReverses : 0) |
                          (self->_animationIsAdditive   ? CAAnimationAdditive : 0);
}


- (void) setAnimationOptions:(struct CAAnimationOptions *) options
{
   memset( options, 0, sizeof( *options));
   setAnimationOptions( self, options);
}

@end


@implementation CAAnimationGroup( CABasicAnimation)

- (void) setBasicAnimationOptions:(struct CABasicAnimationOptions *) options
{
   memset( options, 0, sizeof( *options));

   setAnimationOptions( self, &options->base);
   options->tween     = _animationTweenFunction;
   if( ! options->tween)
      options->curve  = _animationCurve;
}

@end

