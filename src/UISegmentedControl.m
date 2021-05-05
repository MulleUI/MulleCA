#import "UISegmentedControl.h"

#import "MulleSegmentedControlLayer.h"
#import "UIEvent.h"
#import "UIView+CGGeometry.h"
#import "UIView+CALayer.h"
#import "CGGeometry+CString.h"
#import "CGColor.h"

@implementation UISegmentedControl

- (id) initWithFrame:(CGRect) frame
{
   MulleSegmentedControlLayer  *segmentedControlLayer;
   CGRect                      rect;

   rect.origin = CGPointZero;
   rect.size   = frame.size;
   segmentedControlLayer = [[[MulleSegmentedControlLayer alloc] initWithFrame:rect] autorelease];
   [segmentedControlLayer setBorderWidth:1.5];
   [segmentedControlLayer setBorderColor:MulleColorMake( 0x7F7FFFFF)];
   return( [self initWithLayer:segmentedControlLayer
                         frame:frame]);
}

// move this to + UIEvent ?
- (UIEvent *) consumeMouseDown:(UIEvent *) event
{
   // figure our which segment the click, was in
   // and select this
   CGPoint       mouseLocation;
   CGPoint       canvasLocation;
   NSUInteger    index;
   char          *s;

   assert( [self allowsEmptySelection]|| [self numberOfSelectedSegments] > 0);

   mouseLocation        = [event mouseLocationInView:self];
 //  contentMousePosition = [self convertPoint:mouseLocation
 //                                   fromView:nil];
//
   s = CGPointCStringDescription( mouseLocation);
   fprintf( stderr, "mouse event: %s\n", s);

   canvasLocation = [self convertPoint:mouseLocation
                               toLayer:nil];
   s = CGPointCStringDescription( canvasLocation);
   fprintf( stderr, "canvas view : %s\n", s);

   index = [self segmentIndexAtPoint:canvasLocation];
   if( index == NSNotFound)
      return( nil);

   if( ! [self isFirstResponder])
      [self becomeFirstResponder];

   [self memorizeSelectedSegments];
   if( [self allowsMultipleSelection])
   {
      if( [self isSelectedSegmentAtIndex:index])
      {
         if( [self allowsEmptySelection] || [self numberOfSelectedSegments] > 1)
            [self deselectSegmentAtIndex:index];
      }
      else
         [self selectSegmentAtIndex:index];
   }
   else
   {
      if( [self selectedSegmentIndex] == index && [self allowsEmptySelection])
         index = -1;
      [self setSelectedSegmentIndex:index];
   }

   return( [super consumeMouseDown:event]);
}

- (UIEvent *) consumeMouseUp:(UIEvent *) event
{
   // figure our which segment the click, was in
   // and select this
   CGPoint       mouseLocation;
   CGPoint       contentMousePosition;
   NSUInteger    index;

   mouseLocation        = [event locationInWindow];
//  contentMousePosition = [self convertPoint:mouseLocation
//                                   fromView:nil];
//
   contentMousePosition = mouseLocation;

   index = [self segmentIndexAtPoint:contentMousePosition];
   if( index == NSNotFound)
   {
      [self recallSelectedSegments];
      return( nil);
   }

   return( [super consumeMouseUp:event]);
}

@end
