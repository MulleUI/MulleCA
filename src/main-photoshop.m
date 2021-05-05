#import "import-private.h"

#import "CGContext.h"
#import "UIApplication.h"
#import "UIEvent.h"
#import "UIWindow.h"
#import "UIView.h"
#import "CALayer.h"
#import "UIView+CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"
#import "MulleLayout.h"

//
// photoshop is a little 8x8 pixel editor, where the pixels
// are drawn in a sublayer. this tests event locations being properly
// forwarded
//
#define PIXEL_WH     8

@interface PixelEditorLayer : CALayer
{
   CGColorRef   _sprite[ PIXEL_WH][ PIXEL_WH];
}

- (CGColorRef) colorAtX:(NSUInteger) x
                      y:(NSUInteger) y;
- (void) setColor:(CGColorRef) color
                x:(NSUInteger) x
                y:(NSUInteger) y;
@end


@implementation PixelEditorLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   NSUInteger   x;

   [super initWithFrame:frame];
   for( x = 0; x < PIXEL_WH; x++)
      _sprite[ x][ x] = CGColorCreateGenericRGB( 0, 1.0, 0, 1.0);
   [self setBounds:CGRectMake( 0, 0, 8, 8)];
   return( self);
}

- (CGColorRef) colorAtX:(NSUInteger) x
                      y:(NSUInteger) y
{
   assert( x < PIXEL_WH);
   assert( y < PIXEL_WH);
   return( _sprite[ y][ x]);
}


- (void) setColor:(CGColorRef) color
                x:(NSUInteger) x
                y:(NSUInteger) y
{
   assert( x < PIXEL_WH);
   assert( y < PIXEL_WH);
   _sprite[ y][ x]  = color;
}


- (void) drawInContext:(CGContext *) context
{
   NSUInteger   x, y;
   NVGcontext   *vg;

   vg = [context nvgContext];
   for( y = 0; y < PIXEL_WH; y++)
      for( x = 0; x < PIXEL_WH; x++)
      {
         nvgBeginPath( vg);
         nvgRect( vg, x, y, 1, 1);
         nvgFillColor( vg, _sprite[ y][ x]);
         nvgFill( vg);
      }
}

@end


// doesn't use mainlayer, just because...
@interface PixelEditorView : UIView

@property( assign) PixelEditorLayer   *pixelEditorLayer;

@end


@implementation PixelEditorView

- (UIEvent *) mouseDown:(UIEvent *) event
{
   CGPoint    point;
   CALayer    *layer;

   point = [event mouseLocationInView:self];
   layer = [self layerHitTest:point];
   if( layer == _pixelEditorLayer)
   {
      point = [self convertPoint:point
                         toLayer:_pixelEditorLayer];
      [_pixelEditorLayer setColor:MulleColorMake( 0x0000FFFF)
                                x:(NSUInteger) floor( point.x)
                                y:(NSUInteger) floor( point.y)];
   }
   return( nil);
}

@end



void   setupScene( MulleWindowPlane *contentPlane)
{
   CALayer            *layer;
   CGRect             bounds;
   CGRect             frame;
   PixelEditorLayer   *sublayer;
   PixelEditorView    *subview;
   UIEdgeInsets       insets;
   UIView             *view;

   frame        = [contentPlane bounds];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 50, 50, 50, 50);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view setBorderWidth:1.0];
   [view setBorderColor:MulleColorMake( 0x000000FF)];
   [[view layer] setDebugNameCString:"black"];
   [contentPlane addSubview:view];

   // make sublayer evenly divisible by PIXEL_WH
   frame.origin      = CGPointMake( 0, 0);
   frame.size.width  = PIXEL_WH * 25;
   frame.size.height = PIXEL_WH * 25;

   sublayer = [[[PixelEditorLayer alloc] initWithFrame:frame] autorelease];
   [sublayer setDebugNameCString:"editor"];

   // make view a little bit larger
   frame.size.width  += 50.0;
   frame.size.height += 50.0;

   // place view in center of enclosing view
   frame = MulleSizeApplyContentModeInRect( frame.size, UIViewContentModeCenter, [view bounds]);

   subview  = [[[PixelEditorView alloc] initWithFrame:frame] autorelease];
   [subview setBorderWidth:1.0];
   [subview setBorderColor:MulleColorMake( 0xFF0000FF)];
   [[subview layer] setDebugNameCString:"red"];
   [view addSubview:subview];

   // center sublayer in pixelEditor, but then add
   frame = MulleSizeApplyContentModeInRect( [sublayer frame].size,
                                             UIViewContentModeCenter, [subview bounds]);
   [sublayer setFrame:frame];

   [subview addLayer:sublayer];
   [subview setPixelEditorLayer:sublayer];
}


int   main()
{
   CGContext   *context;
   UIWindow    *window;

   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400, 400)];
   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupScene( [window contentPlane]);

   [window dump];

   [[UIApplication sharedInstance] addWindow:window];
   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
}

