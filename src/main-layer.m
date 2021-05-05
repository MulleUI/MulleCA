#import "import-private.h"

#import "CGContext.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"


void   setupScene( MulleWindowPlane *contentPlane)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame        = [contentPlane bounds];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   layer = [view layer];
   [layer setBackgroundColor:CGColorCreateGenericRGB( 0.0, 1.0, 0.0, 1.0)];
   [layer setBorderColor:CGColorCreateGenericRGB( 1.0, 0.0, 0.0, 1.0)];
   [layer setCornerRadius:20];
   [layer setBorderWidth:40];

   [contentPlane addSubview:view];
}


int   main()
{
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   mulle_testallocator_initialize();
   mulle_default_allocator = mulle_testallocator;
   {
      /*
      * window and app
      */
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
      [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

      setupScene( [window contentPlane]);

      [window dump];

      [app addWindow:window];
      [window renderLoop];
      [app terminate];
   }
}

