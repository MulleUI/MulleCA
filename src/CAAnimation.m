#define _GNU_SOURCE

#import "CAAnimation.h"

#import "import-private.h"

#include <assert.h>



@implementation CAAnimation

static const struct CAAnimationOptions   CAAnimationDefaultOptions =
{
   { 0, 1 },      // 1 second starting immediately
   1.0,
   0
};


- (id) initWithOptions:(struct CAAnimationOptions *) options
{
   // no need for super coz NSObject based
   if( ! options)
      options = (struct CAAnimationOptions *) &CAAnimationDefaultOptions;

   // reverses is only used if repeats is set
   assert( ! (options->bits & 0xFFFF));

   if( options->timeRange.duration <= 0.0)
   {
      [self release];
      return( nil);
   }

   self->_relative            = options->timeRange;
   self->_bits                = options->bits & ~0xFFFF;  // mask off our internal state bits

   self->_repeatCount         = options->repeatCount;
   // only used for reset
   self->_originalRepeatCount = self->_repeatCount;

   return( self);
}



- (void) reverse
{
   self->_relative.delay = 0.0;

   if( ! (self->_bits & CAAnimationHasReversed))
   {
      self->_bits |= CAAnimationHasReversed;
   }
}


- (void) reset
{
   self->_bits       &= ~0xFFFF;
   self->_frames      = 0;
   self->_repeatCount = self->_originalRepeatCount;
}


//
// this is called by the layer (ahem) animatableObject
// which does the animation now
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) x
           elapsedTime:(CARelativeTime) elapsed
{
   if( _animationFunction)
      (*_animationFunction)( self, object, x, elapsed);
}


- (void) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now
{
   CGFloat          x;
   CGFloat          t;
   CAAbsoluteTime   diff;

   if( self->_bits & CAAnimationEnded)
      return;

   // turn animation time into absolute
   if( ! (self->_bits & CAAnimationStarted))
   {
      self->_absolute.start = CATimeAdd( now, self->_relative.delay);
      self->_absolute.end   = CATimeAdd( self->_absolute.start,
                                         self->_relative.duration);
      self->_lastFrame      = now;
      self->_bits          |= CAAnimationStarted;
   }

   if( now < self->_absolute.start)
      return;

   if( _frames++ == 0)
   {
      [_animationDelegate willStart];
   }

   //
   // if time has passed, we don't want to overshoot but we really
   // want to place the final values into the object and not leave
   // some ugly interpolation
   //
   if( now >= self->_absolute.end)
      now = self->_absolute.end;

   diff = CATimeSubtract( now, self->_absolute.start);
   t    = diff / self->_relative.duration;

   if( self->_repeatCount > 0.0)
   {
      if( t > self->_repeatCount)  // exhausted ? Done!
      {
         self->_repeatCount = 0.0;
         return;
      }
   }

   [self animateObject:object
normalizedRelativeTime:t
           elapsedTime:CATimeSubtract( self->_lastFrame, now)];

   self->_lastFrame = now;

   // not yet done ?
   if( now != self->_absolute.end)
      return;

   // not repeating ? done
   if( self->_repeatCount == 0.0)
   {
      self->_bits |= CAAnimationEnded;
      [_animationDelegate didEnd];
      return;
   }

   // _self->_repeatCount > 0.0 means repeats a finite number
   if( self->_repeatCount > 0.0)
   {
      self->_repeatCount -= 1.0;
      if( self->_repeatCount <= 0.0)
      {
         self->_bits |= CAAnimationEnded;
         [_animationDelegate didEnd];
         return;
      }
   }

   // start with next frame, with a new animation
   self->_bits &= ~CAAnimationStarted;
   if( self->_bits & CAAnimationReverses)
      [self reverse];
}


static void   performSelectorOnObjects( struct mulle_pointerarray *objects,
                                        SEL sel,
                                        CAAbsoluteTime renderTime)
{
   struct mulle_pointerarrayenumerator   rover;
   id                                    object;

#ifdef RENDER_DEBUG_VERBOSE
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   rover = mulle_pointerarray_enumerate( objects);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &object))
      MulleObjCObjectPerformSelectorDoubleArgument( object, sel, renderTime);
   mulle_pointerarrayenumerator_done( &rover);
}


+ (void) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(CAAbsoluteTime) renderTime
{
   performSelectorOnObjects( objects,
                             @selector( animateWithAbsoluteTime:),
                             renderTime);
}

@end



@implementation MulleAnimationDelegate : NSObject

- (void) setIdentifier:(char *) s
{
   MulleObjCObjectSetDuplicatedCString( self, &_identifier, s);
}


- (void) dealloc
{
   MulleObjCInstanceDeallocateMemory( self, &_identifier);
   [super dealloc];
}


- (void) willStart
{
   // if this is the first time we got this, then
   // send the delegate a message
   if( _startedCount++)
      return;
   if( ! _animationWillStartSelector)
      return;

   [_delegate performSelector:_animationWillStartSelector
                   withObject:(id) _identifier
                   withObject:_context];
}


- (void) didEnd
{
   // if we got #animations messages, then the last one
   // to finish sends the delegate emessage
   if( ++_endedCount != _startedCount)
      return;
   if( ! _animationDidStopSelector)
      return;

   [_delegate performSelector:_animationDidStopSelector
                   withObject:(id) _identifier
                   withObject:_context];
}


- (void) didPreempt
{
   // if we got #animations messages, then the last one
   // to finish sends the delegat message
   if(  _endedCount == _startedCount)
      return;
   if( ! _animationDidStopSelector)
      return;

   _endedCount = _startedCount;  // don't send more

   [_delegate performSelector:_animationDidStopSelector
                   withObject:(id) _identifier
                   withObject:_context];
}

@end
