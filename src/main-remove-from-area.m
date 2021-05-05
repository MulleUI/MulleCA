#import "import-private.h"

#import "CGBase.h"
#import "CGContext.h"
#import "CGGeometry.h"
#import "CGColor+MulleObjC.h"
#import "CGGeometry+CString.h"
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

@property( observable) CGFloat     scale;  // 0 - 1
@property( observable) CGColorRef  color;  // 0 - 1
@property( observable) CGRect      box;    // 0 - 1

@end


@implementation CircleLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   _scale = 1;
   _color = MulleColorMake( 0x000000FF);
   _box   = frame;
   return( [super initWithFrame:frame]);
}

@end


static void  drawStuff( CALayer *aLayer, CGContext *context)
{
   CircleLayer         *layer = (CircleLayer *) aLayer;
   CGFloat             radius;
   CGRect              box;
   CGRect              canvas;
   struct NVGcontext   *vg;

   vg = MulleContextGetNVGContext( context);
   nvgBezierTessellation( vg, NVG_TESS_AFD);

   nvgBeginPath( vg);

   canvas = [layer canvas];
   radius = MulleCGFloatMinimum( CGRectGetWidth( canvas), CGRectGetHeight( canvas)) / 2 - 10;
   radius *= [layer scale];

   nvgRect( vg, CGRectGetMidX( canvas) - radius,
                CGRectGetMidY( canvas) - radius,
                radius * 2,
                radius * 2);

//   nvgCircle( vg, CGRectGetMidX( canvas), CGRectGetMidY( canvas), radius);
   nvgFillColor( vg, [layer color]);
   nvgStrokeWidth( vg, 3.5);
   nvgFill( vg);
/*
   nvgBeginPath( vg);
   box = [layer box];
   nvgRect( vg, CGRectGetMinX( box), CGRectGetMinY( box), CGRectGetWidth( box), CGRectGetHeight( box));
   nvgFillColor( vg, [layer color]);
   nvgStrokeWidth( vg, 3.5);
   nvgFill( vg);
*/
}

// scale stuff for stream
#define SCALE     2.0

static void   setupSceneInContentPlane( MulleWindowPlane *contentPlane)
{
   CGFloat                               scale;
   CGFloat                               translate;
   CGRect                                frame;
   CGRect                                rect;
   CircleLayer                           *layer;
   NSInteger                             i;
   struct mulle_pointerarray             array;
   struct mulle_pointerarrayenumerator   rover;
   UIEdgeInsets                          insets;
   UIView                               *view;

   frame = [contentPlane bounds];

   for( i = 0; i < 1000; i++)
   {
      rect.origin.x = rand() % ((int) frame.size.width - 16);
      rect.origin.y = rand() % ((int) frame.size.height - 16);
      rect.size     = CGSizeMake( 32 ,32);

      layer = [[[CircleLayer alloc] initWithFrame:rect] autorelease];
      view  = [[[UIView alloc] initWithLayer:layer] autorelease];
      [layer setDrawCallback:drawStuff];
      [layer setColor:MulleColorMakeRandom( 0x00FF00FF, 0xFF00FF00)];
      [contentPlane addSubview:view];
   }

   _mulle_pointerarray_init( &array, 0, NULL);
   [contentPlane addSubviewsIntersectingRect:CGRectMake( frame.size.width / 4,
                                                         frame.size.height / 4,
                                                         frame.size.width / 2,
                                                         frame.size.height / 2)
                      toPointerArray:&array
              invertIntersectionTest:YES];

   rover = mulle_pointerarray_enumerate( &array);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      [view setBackgroundColor:MulleColorMakeRandom( 0xFF0000FF, 0x00FFFF00)];
   mulle_pointerarrayenumerator_done( &rover);

   mulle_pointerarray_done( &array);
}


int   main( int argc, char *argv[])
{
   CGContext   *context;
   UIWindow    *window;

   /*
    * window and app
    */
   window  = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
   assert( window);

   [[UIApplication sharedInstance] addWindow:window];

   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentPlane( [window contentPlane]);

   [window dump];
   [window renderLoop];

   [[UIApplication sharedInstance] terminate];

   return( 0);
}

