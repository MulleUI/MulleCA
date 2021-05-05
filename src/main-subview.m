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
   UIView        *subview;
   CGRect         frame;
   CGRect         bounds;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame        = [contentPlane bounds];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [UIView viewWithFrame:frame];
   layer = [view layer];
   [layer setBackgroundColor:CGColorCreateGenericRGB( 0.0, 1.0, 0.0, 1.0)];
   [layer setBorderColor:CGColorCreateGenericRGB( 1.0, 0.0, 0.0, 1.0)];
   [layer setCornerRadius:20];
   [layer setBorderWidth:40];

   [contentPlane addSubview:view];

   insets = UIEdgeInsetsMake( 80, 80, 80, 80);
   frame  = UIEdgeInsetsInsetRect( [view bounds], insets);

   subview  = [UIView viewWithFrame:frame];
   layer = [subview layer];
   [layer setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 0.0, 1.0)];
   [layer setBorderColor:CGColorCreateGenericRGB( 0.0, 1.0, 1.0, 1.0)];
   [layer setCornerRadius:10];
   [layer setBorderWidth:20];

   [view addSubview:subview];

//   // make twice as high virtually (afterwards)
//   bounds = [view bounds];
//   bounds.size.height *= 0.5;
//   [view setBounds:bounds];
}


int   main()
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *application;

   application = [UIApplication sharedInstance];
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupScene( [window contentPlane]);

   [window dump];

   [application addWindow:window];
   [window renderLoop];
   [application terminate];

   return( 0);
}

