#import "import-private.h"

#import "CGContext.h"
#import "CGGeometry+CString.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "MulleLayout.h"
#import "UIView.h"
#import "UIView+Layout.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"


static void   overdraw( CALayer *layer, CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;

   vg = MulleContextGetNVGContext( context);

   canvas = [layer canvas];
   canvas = CGRectInset( canvas, -10, -10);

   nvgBeginPath( vg);
   nvgRect( vg, canvas.origin.x, canvas.origin.y, canvas.size.width, canvas.size.height);
   nvgFillColor( vg, MulleColorMake( 0x00FF00FF));
   nvgFill( vg);
}


void   setupSceneInContentPlane( MulleWindowPlane *contentPlane)
{
   CALayer             *layer;
   CGRect              bounds;
   CGRect              rect;
   CGRect              clipRect;
   CGAffineTransform   transform;
   UIView              *view;
   UIView              *subview;

   rect = [contentPlane contentRect];

   view = [UIView viewWithFrame:CGRectMake( CGRectGetMidX( rect), 0, rect.size.width / 2, rect.size.height)];
   [view setBackgroundColor:MulleColorMake( 0xC0C0C0FF)];
   [view setClipsToBounds:YES];

   layer = [CALayer layerWithFrame:CGRectMake( 100, 100, 100, 100)];
   [layer setBackgroundColor:MulleColorMake( 0xFF0000FF)];
   [layer setBorderColor:MulleColorMake( 0x0000FFFF)];
   [layer setBorderWidth:2.0];
   [layer setMasksToBounds:NO];
   [layer setDrawCallback:overdraw];
   [contentPlane addLayer:layer];

   layer = [[layer copy] autorelease];
   [layer setBackgroundColor:MulleColorMake( 0xFFFF00FF)];
   subview = [[[UIView alloc] initWithLayer:layer] autorelease];
   [subview setClipsToBounds:YES]; // default anyway does not affect layer
   [view addSubview:subview];

   // as above but clips
   layer = [CALayer layerWithFrame:CGRectMake( 250, 100, 100, 100)];
   [layer setBackgroundColor:MulleColorMake( 0xFF0000FF)];
   [layer setBorderColor:MulleColorMake( 0x0000FFFF)];
   [layer setBorderWidth:2.0];
   [layer setMasksToBounds:YES];
   [layer setDrawCallback:overdraw];
   [contentPlane addLayer:layer];   

   layer = [[layer copy] autorelease];
   [layer setBackgroundColor:MulleColorMake( 0xFFFF00FF)];
   subview = [[[UIView alloc] initWithLayer:layer] autorelease];
   [view addSubview:subview];



   // now change bounds to pan 
   layer = [CALayer layerWithFrame:CGRectMake( 100, 250, 100, 100)];
   [layer setBackgroundColor:MulleColorMake( 0xFF0000FF)];
   [layer setBorderColor:MulleColorMake( 0x0000FFFF)];
   [layer setBorderWidth:2.0];
   [layer setMasksToBounds:NO];
   bounds = [layer bounds];
   bounds.origin.x = CGRectGetMidX( bounds);
   [layer setBounds:bounds];
   [layer setDrawCallback:overdraw];
   [contentPlane addLayer:layer];   

   layer = [[layer copy] autorelease];
   [layer setBackgroundColor:MulleColorMake( 0xFFFF00FF)];
   subview = [[[UIView alloc] initWithLayer:layer] autorelease];
   [view addSubview:subview];

   layer = [CALayer layerWithFrame:CGRectMake( 250, 250, 100, 100)];
   [layer setBackgroundColor:MulleColorMake( 0xFF0000FF)];
   [layer setBorderColor:MulleColorMake( 0x0000FFFF)];
   [layer setBorderWidth:2.0];
   [layer setMasksToBounds:YES];
   bounds = [layer bounds];
   bounds.origin.x = CGRectGetMidX( bounds);
   [layer setBounds:bounds];
   [layer setDrawCallback:overdraw];
   [contentPlane addLayer:layer]; 

   layer = [[layer copy] autorelease];
   [layer setBackgroundColor:MulleColorMake( 0xFFFF00FF)];
   subview = [[[UIView alloc] initWithLayer:layer] autorelease];
   [view addSubview:subview];

   // now change bounds to pan and zoom
   layer = [CALayer layerWithFrame:CGRectMake( 100, 400, 100, 100)];
   [layer setBackgroundColor:MulleColorMake( 0xFF0000FF)];
   [layer setBorderColor:MulleColorMake( 0x0000FFFF)];
   [layer setBorderWidth:2.0];
   [layer setMasksToBounds:NO];
   bounds = [layer bounds];
   bounds.origin.x    = CGRectGetMidX( bounds);
   bounds.size.width *= 2.0;
   [layer setBounds:bounds];
   [layer setDrawCallback:overdraw];
   [contentPlane addLayer:layer];   

   layer = [[layer copy] autorelease];
   [layer setBackgroundColor:MulleColorMake( 0xFFFF00FF)];
   subview = [[[UIView alloc] initWithLayer:layer] autorelease];
   [view addSubview:subview];
 
   layer = [CALayer layerWithFrame:CGRectMake( 250, 400, 100, 100)];
   [layer setBackgroundColor:MulleColorMake( 0xFF0000FF)];
   [layer setBorderColor:MulleColorMake( 0x0000FFFF)];
   [layer setBorderWidth:2.0];
   [layer setMasksToBounds:YES];
   bounds = [layer bounds];
   bounds.origin.x    = CGRectGetMidX( bounds);
   bounds.size.width *= 2.0;
   [layer setBounds:bounds];
   [layer setDrawCallback:overdraw];
   [contentPlane addLayer:layer];          

   layer = [[layer copy] autorelease];
   [layer setBackgroundColor:MulleColorMake( 0xFFFF00FF)];
   subview = [[[UIView alloc] initWithLayer:layer] autorelease];
   [view addSubview:subview];


   [contentPlane addSubview:view];
}


int   main( int argc, char *argv[])
{
   CGContext   *context;
   UIWindow    *window;

   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentPlane( [window contentPlane]);

   [window dump];

   [[UIApplication sharedInstance] addWindow:window];
   [window renderLoop];
   [[UIApplication sharedInstance] terminate];

   return( 0);
}

