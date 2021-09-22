#define _GNU_SOURCE

#import "CAAnimation.h"

#import "CAAnimationGroup.h"

#import "import-private.h"
#include <assert.h>



#ifdef DEBUG
//#define DEBUG_VERBOSE
#endif


@interface CAAnimationGroup( Private)
// kinda private
- (void) animationWillStart:(CAAnimation *) animation;
- (void) animationDidStop:(CAAnimation *) animation;

@end

static char  *CAAnimationBitCString( NSUInteger bit)
{
   switch( bit)
   {
   case CAAnimationStarted     : return( "CAAnimationStarted");
   case CAAnimationAnimating   : return( "CAAnimationAnimating");
   case CAAnimationScrubbing   : return( "CAAnimationScrubbing");
   case CAAnimationHasReversed : return( "CAAnimationHasReversed");
   case CAAnimationEnded       : return( "CAAnimationEnded");
   case CAAnimationPreempt     : return( "CAAnimationPreempt");
   case CAAnimationReverses    : return( "CAAnimationReverses");
   case CAAnimationAdditive    : return( "CAAnimationAdditive");
   }
   return( "???");
}


static NSUInteger  CAAnimationBits[] =
{
   // internal state, can't be set
   CAAnimationStarted,    // animation active, but possibly delayed
   CAAnimationAnimating,    // passed delay, now doing something
   CAAnimationScrubbing,    // future
   CAAnimationHasReversed,
   CAAnimationEnded,
   CAAnimationPreempt,   // signal preemption

   // user options
   CAAnimationReverses,
   CAAnimationAdditive
};


static char   *CAAnimationBitsCString( NSUInteger bits)
{
   struct mulle_buffer   buffer;
   char                  *s;
   NSUInteger            i;

   mulle_buffer_init( &buffer, NULL);

   for( i = 0; i < sizeof( CAAnimationBits) / sizeof( NSUInteger); i++)
   {
      if( bits & CAAnimationBits[ i])
      {
         mulle_buffer_add_string_if_not_empty( &buffer, "|");
         mulle_buffer_add_string( &buffer, CAAnimationBitCString( CAAnimationBits[ i]));
      }
   }

   mulle_buffer_add_string_if_empty( &buffer, "0");

   s = mulle_buffer_extract_string( &buffer);
   mulle_buffer_done( &buffer);

   return( s);
}



@implementation CAAnimation

const struct CAAnimationOptions   CAAnimationDefaultOptions =
{
   { 0, 1 },      // 1 second starting immediately
   1.0,
   0
};


- (void) setAnimationOptions:(struct CAAnimationOptions *) options
{
   // no need for super coz NSObject based
   if( ! options)
      options = (struct CAAnimationOptions *) &CAAnimationDefaultOptions;

   // reverses is only used if repeats is set
   assert( ! (options->bits & 0xFFFF));

   self->_relative            = options->timeRange;
   self->_bits                = options->bits & ~0xFFFF;  // mask off our internal state bits

   self->_repeatCount         = options->repeatCount;
   // only used for reset
   self->_originalRepeatCount = self->_repeatCount;
   self->_removedOnCompletion = YES;
}


+ (instancetype) animationWithAnimationOptions:(struct CAAnimationOptions *) options
{
   return( [[[self alloc] initWithAnimationOptions:options] autorelease]);
}

// separated into two parameters, so animations can live without
// a group
- (id) initWithAnimationOptions:(struct CAAnimationOptions *) options
{
   if( options && options->timeRange.duration <= 0.0)
   {
      [self release];
      return( nil);
   }

   [self setAnimationOptions:options];

   return( self);
}


- (id) init
{
   return( [self initWithAnimationOptions:NULL]);
}


- (id) copy
{
   CAAnimation  *clone;

   clone = NSCopyObject( self, 0, NULL);
   clone->_animationObject = nil;  // or what ?
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
}


- (void) willStartAnimating
{
   self->_bits |= CAAnimationAnimating;
#ifdef DEBUG_VERBOSE
   fprintf( stderr, "%s %s\n",
               __PRETTY_FUNCTION__, [self UTF8String]);
#endif
}


// returns YES, if really ended (reverse flag is confusing to me)
- (BOOL) didEnd
{
   // don't call callbacks if we are "scrubbing" (future)
   // also don't really end
   if( self->_bits & CAAnimationScrubbing)
      return( NO);

   self->_bits |= CAAnimationEnded;
   [_delegate animationDidStop:self
                      finished:YES];

#ifdef DEBUG_VERBOSE
   fprintf( stderr, "%s %s\n",
               __PRETTY_FUNCTION__, [self UTF8String]);
#endif
   return( YES);
}


- (BOOL) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now
{
   CGFloat          x;
   double           t;
   double           e;
   CAAbsoluteTime   diff;

#ifdef DEBUG_VERBOSE
   {
      char   *s;

      s = CAAnimationBitsCString( self->_bits);
      fprintf( stderr, "%s %s %s\n",
                  __PRETTY_FUNCTION__, [self UTF8String], s);
      free( s);
   }
#endif

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
      [self willStartAnimating];

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

#ifdef DEBUG_VERBOSE
   fprintf( stderr, "%.5f: %s %s\n",
               now, __PRETTY_FUNCTION__, [self UTF8String]);
#endif

   [self animateObject:object
normalizedRelativeTime:t
           elapsedTime:now - self->_lastFrame];

   if( _frames == 1)
      [_delegate animationDidStart:self];

   // not yet done ?
   if( now != self->_absolute.end)
      return( YES);

   // not repeating ? done
   if( self->_repeatCount == 0.0)
      return( ! [self didEnd]);

   // _self->_repeatCount > 0.0 means repeats a finite number
   if( self->_repeatCount > 0.0)
   {
      self->_repeatCount -= 1.0;
      if( self->_repeatCount <= 0.0)
         return( ! [self didEnd]);
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


