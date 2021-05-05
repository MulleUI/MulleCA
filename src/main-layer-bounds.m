#import "import-private.h"

#import "CGContext.h"
#import "CGContext+CGFont.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIEvent.h"
#import "UIView.h"
#import "CALayer.h"
#import "CGFont.h"
#import <string.h>
#import "UIEdgeInsets.h"


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

#define TILE_SIZE   30

static void  draw( CALayer *layer,
                   CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;
   CGFont              *font;
   CGRect              bounds;

   vg     = MulleContextGetNVGContext( context);
   nvgSave( vg);
   {
      bounds = [layer bounds];
      nvgScissor( vg, bounds.origin.x,
                      bounds.origin.y,
                      bounds.size.width,
                      bounds.size.height);

      font   = [context fontWithNameCString:"sans"];
      canvas = [layer canvas];
      drawCheckerBoard( vg, canvas,
                            TILE_SIZE,
                            font,
                            MulleColorMakeGrayOpaque( 0.8),
                            MulleColorMakeGrayOpaque( 0.2));
   }
   nvgRestore( vg);
}



void   setupSceneInContentPlane( MulleWindowPlane *contentPlane)
{
   UIView    *view1;
   UIView    *view2;
   CGRect    frame;
   CALayer   *layer1;
   CALayer   *layer2;

   frame = [contentPlane bounds];

   frame = CGRectMake( 100, 100, 10 * TILE_SIZE, 8 * TILE_SIZE);

   view1  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view1 setBorderWidth:3.0];
   [view1 setBorderColor:MulleColorMake( 0x00FF00FF)];
   layer1 = [view1 layer];
   [layer1 setDrawCallback:draw];
   [contentPlane addSubview:view1];

   frame = CGRectMake( 1 * TILE_SIZE, 1 * TILE_SIZE, 8 * TILE_SIZE, 6 * TILE_SIZE);

   view2  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view2 setBorderWidth:3.0];
   [view2 setBorderColor:MulleColorMake( 0xFF0000FF)];
   layer2 = [view2 layer];
   [layer2 setCanvas:[layer1 canvas]];
   [layer2 setBounds:CGRectMake( 2 * TILE_SIZE,
                                 3 * TILE_SIZE,
                                 4 * TILE_SIZE,
                                 3 * TILE_SIZE)];
   [layer2 setDrawCallback:draw];
   [view1 addSubview:view2];
}


int   main()
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *application;
   /*
    * window and app
    */
   application = [UIApplication sharedInstance];
   [UIEvent setReuseEvents:NO];

   mulle_testallocator_initialize();
   mulle_default_allocator = mulle_testallocator;

   @autoreleasepool
   {
      window = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 800, 600)] autorelease];
      assert( window);
      [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

      setupSceneInContentPlane( [window contentPlane]);

      [application addWindow:window];
      [window renderLoop];
      [application terminate];
   }
   mulle_testallocator_reset();
}

