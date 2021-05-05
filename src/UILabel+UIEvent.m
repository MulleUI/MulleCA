//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UILabel+UIEvent.h"

#import "import-private.h"

#import "MulleTextLayer+Selection.h"
#import "UIEvent.h"


@implementation UILabel ( UIEvent)

- (UIEvent *) mouseDown:(UIEvent *) event
{
   CGPoint           mouseLocation;
   MulleTextLayer    *textLayer;

   mouseLocation = [event mouseLocationInView:self];
   textLayer     = (MulleTextLayer *) _mainLayer;
   [textLayer startSelectionAtPoint:mouseLocation];

   // TODO: if layer is a subview then layer selection is actually not
   //       that fascinating to preempt the click. Or is it ?
   //       Probably the owner should make the label non-responsive to events.
   //       with setUserInteractionEnabled:NO. OTOH maybe the UILabel should
   //       not consume the event fully ?
   return( nil);
}


- (UIEvent *) mouseDragged:(UIEvent *) event
{
   CGPoint           mouseLocation;
   MulleTextLayer    *textLayer;

   mouseLocation = [event mouseLocationInView:self];
   textLayer     = (MulleTextLayer *) _mainLayer;
   [textLayer adjustSelectionToPoint:mouseLocation];
   return( nil);
}

@end
