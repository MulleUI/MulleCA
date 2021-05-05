#import "import-private.h"

#import "CGBase.h"
#import "CGContext.h"
#import "CGGeometry.h"
#import "CGColor+MulleObjC.h"
#import "CGGeometry+MulleObjC.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "UIView+CAAnimation.h"
#import "UIColor.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"


@interface CircleLayer : CALayer

@property( observable) CGFloat     scale;
@property( observable) CGColorRef  color;  // 0 - 1
@property( observable) CGRect      box;

@end


@implementation CircleLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   _scale = 1;
   _color = MulleColorMake( 0x000000FF);
   _box   = [self canvas];

   return( self);
}

@end


static void  drawStuff( CALayer *aLayer, CGContext *context)
{
   CircleLayer         *layer = (CircleLayer *) aLayer;
   CGFloat             radius;
   CGRect              box;
   CGRect              canvas;
   struct NVGcontext  *vg;

   canvas = [layer canvas];

   vg = MulleContextGetNVGContext( context);
   nvgBeginPath( vg);
   radius = MulleCGFloatMinimum( CGRectGetWidth( canvas), CGRectGetHeight( canvas)) / 2 - 10;
   radius *= [layer scale];

   nvgCircle( vg, CGRectGetMidX( canvas), CGRectGetMidY( canvas), radius);
   nvgStrokeColor( vg, [layer color]);
   nvgStrokeWidth( vg, 3.5);
   nvgStroke( vg);

   nvgBeginPath( vg);
   box = [layer box];
   nvgRect( vg, CGRectGetMinX( box), CGRectGetMinY( box), CGRectGetWidth( box), CGRectGetHeight( box));
   nvgStrokeColor( vg, [layer color]);
   nvgStrokeWidth( vg, 3.5);
   nvgStroke( vg);
}



void  setupAnimation( CircleLayer *layer)
{
   // UIView -> CAAnimation
   [UIView beginAnimations:"animation"
                    context:NULL];
   [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
   [UIView setAnimationDelay:2];
   [UIView setAnimationDuration:2];
   [UIView setAnimationRepeatCount:20];

   [layer setScale:-1.0];
   [layer setColor:MulleColorMake( 0x0000FFFF)];
   [layer setBox:CGRectMake( 100, 100, 100, 100)];

   [UIView commitAnimations];
}


void   setupSceneAndAnimation( MulleWindowPlane *contentPlane)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CircleLayer    *layer;

   frame        = [contentPlane bounds];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   layer = [[[CircleLayer alloc] initWithFrame:frame] autorelease];
   view  = [[[UIView alloc] initWithLayer:layer] autorelease];
   [layer setDrawCallback:drawStuff];
   [contentPlane addSubview:view];

   [layer setColor:MulleColorMake( 0xFF0000FF)];

   // UIView -> CAAnimation
   setupAnimation( layer);
}


int   main()
{
   UIWindow   *window;

   /*
    * window and app
    */
   window  = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
   assert( window);

   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupSceneAndAnimation( window);

   [window dump];

   [[UIApplication sharedInstance] addWindow:window];
   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
}

