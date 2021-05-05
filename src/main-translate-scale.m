#define _GNU_SOURCE

#import "import-private.h"

#import "CGAffineTransform.h"
#import "CGAffineTransform+CString.h"
#import "CGContext.h"
#import "CGContext+CGFont.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "UIColor.h"
#import "CALayer.h"
#import "CGFont.h"
#import <string.h>
#import "UIEdgeInsets.h"
#import "MulleLayout.h"
#include <time.h>


//
// We draw little rectangles exactly 20x20. Then we simulate picking out
// a rectangle out of it using bounds. This is a precursor to actually using
// frame and bounds. But we don't use the layers frame and bounds here.
//
static void   drawCheckerBoard( struct NVGcontext *vg,
                                CGRect canvas,
                                CGFloat tileSize,
                                CGFont  *font,
                                CGColorRef color1,
                                CGColorRef color2)
{
   NSUInteger   x;
   NSUInteger   y;
   NSUInteger   w;
   NSUInteger   h;
   char         buf[ 64];

   w = (NSUInteger) ceil( canvas.size.width / tileSize);
   h = (NSUInteger) ceil( canvas.size.height / tileSize);

   for( y = 0; y < h; y++)
      for( x = 0; x < w; x++)
      {
         nvgBeginPath( vg);
         nvgRect( vg, canvas.origin.x + x * tileSize,
                      canvas.origin.y + y * tileSize,
                      tileSize,
                      tileSize);
         if( (x ^ y) & 1)
            nvgFillColor( vg, color1);
         else
            nvgFillColor( vg, color2);
         nvgFill( vg);

         sprintf( buf, "%ld/%ld", (long) x, (long) y);
         nvgFontSize( vg, 10.0);
         nvgFontFace( vg, [font nameCString]);
         nvgTextAlign( vg, NVG_ALIGN_CENTER | NVG_ALIGN_BASELINE);
         if( (x ^ y) & 1)
            nvgTextColor( vg, MulleColorMakeGrayOpaque( 1.0), color1);
         else
            nvgTextColor( vg, MulleColorMakeGrayOpaque( 1.0), color2);

         nvgText( vg, canvas.origin.x + x * tileSize + tileSize / 2.0,
                      canvas.origin.y + y * tileSize + tileSize / 2.0,
                      buf,
                      NULL);
      }
}

#define TILE_SIZE   40

static void  draw( CALayer *layer, CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              frame;
   CGRect              bounds;
   CGRect              canvas;
   CGRect              rect;
   CGFont              *font;
   CGPoint             scale;
   CGAffineTransform   xform;
   _NVGtransform       xform2;
   _NVGtransform       xform3;

   vg     = MulleContextGetNVGContext( context);
   font = [context fontWithNameCString:"sans"];

   // do a few translations and scales to simulate a view hierarchy
//   nvgTranslate( vg, 40.0, 0.0);
//   nvgScale( vg, 0.75, 1.0);
//
//   nvgTranslate( vg, 0.0, 40.0);
//   nvgScale( vg, 1.0, 0.75);
//   nvgRotate( vg, 0.33);
   rect  = [layer canvas];

   xform = CGAffineTransformMakeTranslation( rect.origin.x, 20);
   xform = CGAffineTransformConcat( xform, CGAffineTransformMakeScale( 0.75, 0.80));

   xform = CGAffineTransformConcat( xform, CGAffineTransformMakeTranslation( -rect.origin.x * 0.75, 60.0));
   xform = CGAffineTransformConcat( xform, CGAffineTransformMakeScale( 0.66, 0.75));

   fprintf( stderr, "%s\n", CGAffineTransformCStringDescription( xform));

//   nvgTransform( vg, xform.a, xform.b, xform.c, xform.d, xform.tx, xform.ty);

   nvgTransformTranslate( xform2, rect.origin.x, 20);
   nvgTransformScale( xform3, 0.75, 0.80);
   nvgTransformMultiply( xform2, xform3);

   nvgTransformTranslate( xform3, - rect.origin.x * 0.75, 60);
   nvgTransformMultiply( xform2, xform3);
   nvgTransformScale( xform3, 0.66, 0.75);
   nvgTransformMultiply( xform2, xform3);

   nvgTransform( vg, xform2[ 0], xform2[ 1], xform2[ 2], xform2[ 3], xform2[ 4], xform2[ 5]);

   fprintf( stderr, "%s\n", _NVGtransformCStringDescription( xform2));
/*
   drawCheckerBoard( vg, canvas,
                         TILE_SIZE,
                         font,
                         MulleColorMakeGrayOpaque( 0.8),
                         MulleColorMakeGrayOpaque( 0.2));
*/
   frame = rect;

   // we scissor it for niceness
   nvgIntersectScissor( vg, frame.origin.x,
                            frame.origin.y,
                            frame.size.width,
                            frame.size.height);


   // we draw a 8x8 checkerboard of TILE_SIZE
   canvas = CGRectMake( 0, 0, TILE_SIZE * 8, TILE_SIZE * 8);

   // we pick out 6x6 tiles from it, that's the bounds
   bounds = CGRectMake( TILE_SIZE, TILE_SIZE, TILE_SIZE * 6, TILE_SIZE * 6);

   // now we setup the bounds/frame transformation

   // scale so bounds are mapped to frame
   scale.x = frame.size.width / bounds.size.width;
   scale.y = frame.size.height / bounds.size.height;

   nvgSave( vg);
   nvgScale( vg, scale.x, scale.y);

   // and translate the origin
   nvgTranslate( vg, -bounds.origin.x, -bounds.origin.y);

   drawCheckerBoard( vg, canvas,
                         TILE_SIZE,
                         font,
                         MulleColorMake( 0x00FF007F),
                         MulleColorMake( 0x00FF003F));
   nvgRestore( vg);


   //
   // now we simulate a subview, that is at a certain frame.
   // We use the same bounds. As we get overdraw, we scissor it.
   //
   frame  = CGRectMake( CGRectGetMidX( rect) - rect.size.width / 4,
                        CGRectGetMidY( rect) - rect.size.height / 4,
                        rect.size.width / 2,
                        rect.size.height / 2);
   nvgIntersectScissor( vg, frame.origin.x,
                            frame.origin.y,
                            frame.size.width,
                            frame.size.height);


   // main difference!, translate frame.origin first
   nvgTranslate( vg, frame.origin.x, frame.origin.y);

   scale.x = frame.size.width / bounds.size.width;
   scale.y = frame.size.height / bounds.size.height;

   nvgScale( vg, scale.x, scale.y);

   // and translate the origin
   nvgTranslate( vg, -bounds.origin.x, -bounds.origin.y);

   drawCheckerBoard( vg, canvas,
                         TILE_SIZE,
                         font,
                         MulleColorMake( 0xFF00FF7F),
                         MulleColorMake( 0xFF00FF3F));
}



void   setupSceneInContentPlane( MulleWindowPlane *contentPlane)
{
   UIView    *view;
   CGRect    frame;
   CALayer   *layer;

   frame = [contentPlane bounds];
   assert( frame.origin.x == 0.0);
   assert( frame.origin.y == 0.0);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   layer = [view layer];
   [layer setDrawCallback:draw];
   [contentPlane addSubview:view];
}


int   main()
{
   CGContext   *context;
   UIWindow    *window;

   /*
    * window and app
    */
   mulle_testallocator_initialize();
   mulle_default_allocator = mulle_testallocator;

   @autoreleasepool
   {
      window = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 800, 600)] autorelease];
      assert( window);
      [window setEventFrequency:0.0];
      [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

      setupSceneInContentPlane( [window contentPlane]);

      [[UIApplication sharedInstance] addWindow:window];
      [window renderLoop];
      [[UIApplication sharedInstance] terminate];
   }
   mulle_testallocator_reset();
}

