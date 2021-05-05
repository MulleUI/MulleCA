//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UITextField+UIResponder.h"

#import "import-private.h"

#import "UIEvent.h"
#import "UIView+CALayer.h"
#import "MulleTextLayer.h"
#import "MulleTextLayer+Cursor.h"
#import "MulleTextLayer+Selection.h"
#include "CGGeometry+CString.h"


@implementation UITextField( UIResponder)

- (BOOL) becomeFirstResponder
{
   // I think calling this too often is not good, as it does too much
   assert( ! [self isFirstResponder]);

   if( [super becomeFirstResponder])
   {
      [self setSelected:YES];
      [self reflectState];
      return( YES);
   }
   return( NO);
}


- (BOOL) resignFirstResponder
{
   if( [super resignFirstResponder])
   {
      [self setSelected:NO];
      [self reflectState];
      return( YES);
   }
   return( NO);
}

@end


@implementation UITextField ( UIControl)

- (void) reflectState
{
   UIControlState   state;
   UIControlState   fallbackState;
   CGRect           frame;
   CGColorRef       color;

   state = [self state];

   if( state & UIControlStateSelected)
   {
      [_titleBackgroundLayer setBackgroundColor:getNVGColor( 0xD0D0D0FF)];
      [_titleLayer setTextBackgroundColor:getNVGColor( 0xD0D0D0FF)];
   }
   else
      if( state & UIControlStateHighlighted)
      {
         [_titleBackgroundLayer setBackgroundColor:getNVGColor( 0x6060E0FF)];
         [_titleLayer setTextBackgroundColor:getNVGColor( 0x6060E0FF)];
      }
      else
      {
         [_titleBackgroundLayer setBackgroundColor:getNVGColor( 0xFFFFFFFF)];
         [_titleLayer setTextBackgroundColor:getNVGColor( 0xFFFFFFFF)];
      }
}


// use compatible code
- (void) mulleToggleSelectedState
{
   //
   // target/action has been called already by UIControl
   //
   [super mulleToggleSelectedState];
   [self reflectState];
}


- (void) mulleToggleHighlightedState
{
   [super mulleToggleHighlightedState];
   [self reflectState];
}


// consumeKeyDown handled by MulleKeyboardEventConsumer
- (UIEvent *) consumeUnicodeCharacter:(UIEvent *) event
{
   UIUnicodeEvent *unicodeEvent = (UIUnicodeEvent *) event;
   int   c;

   fprintf( stderr, "character: %ld\n", 
                        (long) [unicodeEvent character]);

   c = [unicodeEvent character];
   [self insertCharacter:c];
   return( nil);
}


- (UIEvent *) consumeMouseDown:(UIEvent *) event
{
   CGPoint   mouseLocation;
   CGPoint   canvasLocation;

   mouseLocation = [event mouseLocationInView:self];
   fprintf( stderr, "b) %s\n", CGPointCStringDescription( mouseLocation));

   canvasLocation = [self convertPoint:mouseLocation 
                               toLayer:_titleLayer];

   [_titleLayer setCursorPositionToPoint:canvasLocation];
   [_titleLayer startSelectionAtPoint:canvasLocation];

   return( nil);
}


- (UIEvent *) consumeMouseDragged:(UIEvent *) event
{
   CGPoint                     mouseLocation;
   CGPoint                     canvasLocation;
   struct MulleIntegerPoint    cursor;

   mouseLocation  = [event mouseLocationInView:self];
   canvasLocation = [self convertPoint:mouseLocation 
                               toLayer:_titleLayer];   
   [_titleLayer adjustSelectionToPoint:canvasLocation];

   cursor = [_titleLayer cursorPositionForPoint:canvasLocation];
   [_titleLayer setCursorPosition:cursor];   
   return( nil);
}

@end
