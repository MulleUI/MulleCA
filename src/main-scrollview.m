#import "import-private.h"

#import "MulleSVGImage.h"
#import "MulleSVGLayer.h"
#import "MulleBitmapImage.h"
#import "MulleImageLayer.h"
#import "MullePaint.h"
#import "CGContext.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIButton.h"
#import "UIColor.h"
#import "UIScrollView.h"
#import "UIView+Layout.h"
#import "UIEvent.h"
#import <string.h>


static void   drawGradient( CALayer *layer, CGContext *context)
{
   MullePaint   *paint;
   CGRect       canvas;
   NVGcontext   *vg;
  
   canvas = [layer canvas];
   // TODO: paint allocation is painful here...
   paint  = [[[MullePaint alloc] initLinearGradientWithStartPoint:canvas.origin
                                                         endPoint:CGPointMake( CGRectGetMaxX( canvas), CGRectGetMaxY( canvas))
                                                       innerColor:MulleColorMake( 0x202020FF)
                                                       outerColor:MulleColorMake( 0xE0E0E0FF)
                                                        CGContext:context] autorelease];  

   vg = MulleContextGetNVGContext( context);
   nvgBeginPath( vg);
   nvgRect( vg, canvas.origin.x,
                canvas.origin.y,
                canvas.size.width,
                canvas.size.height);
   nvgFillPaint(vg, [paint nvgPaint]);
   nvgFill( vg);
}


static void   setupSceneInContentPlane( MulleWindowPlane  *contentPlane)
{
   CGRect                frame;
   CGRect                rect;
   NSUInteger            x, y;
   UIEdgeInsets          insets;
   UIScrollContentView   *contentView;
   UIScrollView          *scroller;
   UIView                *subview;

   [contentPlane setPadding:UIEdgeInsetsMake( 20, 20, 20, 20)];

   frame    = [contentPlane contentRect];
   scroller = [UIScrollView viewWithFrame:frame];
   [scroller setBorderColor:MulleColorMake( 0xFF0000FF)];
   [scroller setBorderWidth:2.0];
   [scroller setAutoresizingMask:MulleUIViewAutoresizingFlexible];
   [scroller setNeedsLayout];

   [scroller setBackgroundColor:MulleColorMake( 0x33AA33FF)];
   [scroller setPadding:UIEdgeInsetsMake( 20, 20, 20, 20)];

   [scroller setContentSize:CGSizeMake( 1000, 1000)];
   [contentPlane addSubview:scroller];

   contentView = [scroller contentView];
   [contentView setBackgroundColor:MulleColorMake( 0x000000FF)];
   [contentView setBorderColor:MulleColorMake( 0xFFFFFFFF)];
   [contentView setBorderWidth:2.0];
   [contentView setDrawCallback:drawGradient];

   insets = UIEdgeInsetsMake( 45, 45, 45, 45);
   for( y = 0; y < 10; y++)
       for( x = 0; x < 10; x++)
       {
          rect = CGRectMake( x * 100.0, y * 100.0 , 100.0, 100.0);
          rect = UIEdgeInsetsInsetRect( rect, insets);
          subview = [UIView viewWithFrame:rect];
          [subview setBackgroundColor:MulleColorMakeRandomOpaque()];
          [contentView addSubview:subview];
       }
}



int   main( int argc, char *argv[])
{
   UIWindow           *window;
   UIApplication      *application;

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 640, 400)];
   assert( window);
   [window setBackgroundColor:MulleColorMake( 0x555555FF)];

   setupSceneInContentPlane( [window contentPlane]);

   application = [UIApplication sharedInstance];
   [application addWindow:window];
   [window renderLoop];
   [application terminate];

   return( 0);
}

