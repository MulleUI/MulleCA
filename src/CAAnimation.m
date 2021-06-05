#define _GNU_SOURCE

#import "CAAnimation.h"

#import "import-private.h"

#include <assert.h>


#import "CAAnimationGroup.h"


@interface CAAnimationGroup( Private)
// kinda private
- (void) animationWillStart:(CAAnimation *) animation;
- (void) animationDidStop:(CAAnimation *) animation;

@end



@implementation CAAnimation

static const struct CAAnimationOptions   CAAnimationDefaultOptions =
{
   { 0, 1 },      // 1 second starting immediately
   1.0,
   0
};


// separated into two parameters, so animations can live without
// a group
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
   self->_removedOnCompletion = YES;

   return( self);
}


- (id) init
{
   return( [self initWithOptions:NULL]);
}


- (id) copy
{
   CAAnimation  *clone;

   clone = NSCopyObject( self, 0, NULL);
   clone->_animationGroup = nil;
   return( clone);
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
normalizedRelativeTime:(double) t
           elapsedTime:(CARelativeTime) elapsed
{
   if( _animationFunction)
      (*_animationFunction)( self, object, t, elapsed);
}


// at the moment, if you call this
- (void) wasPreempted
{
   self->_bits |= CAAnimationEnded;
   [_delegate animationDidStop:self
                      finished:NO];
   [_animationGroup animationDidStop:self];
}


- (void) didEnd
{
   self->_bits |= CAAnimationEnded;
   [_delegate animationDidStop:self
                      finished:YES];
   [_animationGroup animationDidStop:self];
}


- (BOOL) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now
{
   CGFloat          x;
   double           t;
   double           e;
   CAAbsoluteTime   diff;

   if( self->_bits & CAAnimationEnded)
      return( NO);

   if( self->_bits & CAAnimationPreempt)
   {
      [self wasPreempted];
      return( NO);
   }

   // turn animation time into absolute
   if( ! (self->_bits & CAAnimationStarted))
   {
      self->_absolute.start = CATimeAdd( now, self->_relative.delay);
      self->_absolute.end   = CATimeAdd( self->_absolute.start,
                                         self->_relative.duration);
      self->_currentFrame   = self->_absolute.start; // need this for lastFrame
      self->_bits          |= CAAnimationStarted;
   }

   if( now < self->_absolute.start)
      return( YES);

   self->_lastFrame    = self->_currentFrame;
   self->_currentFrame = now;
   if( _frames++ == 0)
   {
      [_animationGroup animationWillStart:self];
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
         return( YES);
      }
   }

   [self animateObject:object
normalizedRelativeTime:t
           elapsedTime:now - self->_lastFrame];

   if( _frames == 1)
   {
      [_delegate animationDidStart:self];
   }

   // not yet done ?
   if( now != self->_absolute.end)
      return( YES);

   // not repeating ? done
   if( self->_repeatCount == 0.0)
   {
      [self didEnd];
      return( NO);
   }

   // _self->_repeatCount > 0.0 means repeats a finite number
   if( self->_repeatCount > 0.0)
   {
      self->_repeatCount -= 1.0;
      if( self->_repeatCount <= 0.0)
      {
         [self didEnd];
         return( NO);
      }
   }

   // start with next frame, with a new animation
   self->_bits &= ~CAAnimationStarted;
   if( self->_bits & CAAnimationReverses)
      [self reverse];
   return( YES);
}


- (BOOL) hasEnded
{
   return( (_bits & CAAnimationEnded) ? YES : NO);
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


