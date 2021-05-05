#import "import-private.h"

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


// Topics:
//  * create a window
//  * place view inside window
//  * add drawing C code to the views layer to produce the graphics
//  * run renderloop (with event handling)
//  * shows differences for pixel alignment and antialiasing
//
static inline CGFloat  xfloorf( CGFloat x)
{
   return( roundf( x));
}

void   drawText( NVGcontext *vg,
                 CGRect rect,
                 CGFloat lineh,
                 CGColorRef fore,
                 CGColorRef back,
                 int antialias)
{
   CGPoint      point;
   NSUInteger   i;
   CGFloat      h;
   CGFloat      x;
   CGFloat      x1;
   CGFloat      x2;
   CGFloat      y;

   nvgShapeAntiAlias( vg, antialias);

   h = rect.size.height / 7;
   h = h < lineh ? lineh : h;

   point.x = rect.origin.x;
   point.y = rect.origin.y + lineh;
   for( i = 0; i < 7; i++)
   {
      if( i != 6)
      {
         nvgBeginPath( vg);
         x1 = xfloorf( point.x - 2);
         x2 = xfloorf( CGRectGetMaxX( rect) + 2);
         y  = xfloorf( 2 + rect.origin.y + (i + 1) * h - 2) + 0.5;
         nvgMoveTo( vg, x1, y);
         nvgLineTo( vg, x2, y);
         nvgStrokeColor( vg, fore);
         nvgStrokeWidth( vg, 1.0);
         nvgStroke( vg);
      }

      nvgTextColor( vg, fore, back);
      x        = point.x;
      switch( i)
      {
      case 0 : nvgTextAlign( vg, NVG_ALIGN_LEFT); break;
      case 1 : nvgTextAlign( vg, NVG_ALIGN_CENTER);
               x = CGRectGetMidX( rect);
               break;
      case 2 : nvgTextAlign( vg, NVG_ALIGN_RIGHT);
               x = CGRectGetMaxX( rect);
               break;
      // TOP draws at point downwards
      case 3 : nvgTextAlign( vg, NVG_ALIGN_TOP); break;
      case 4 : nvgTextAlign( vg, NVG_ALIGN_MIDDLE); break;
      // TOP draws at point upwards
      case 5 : nvgTextAlign( vg, NVG_ALIGN_BOTTOM); break;
      case 6 : nvgTextAlign( vg, NVG_ALIGN_BASELINE); break;
      }
      nvgText( vg, x, point.y, "FoTaTy!,ci|fX_<°>", NULL);
      point.y += h;
   }

   nvgShapeAntiAlias( vg, 1);
}


static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGRect              rows[ 4];
   CGRect              columns[ 2];
   CGRect              rect;
   UIEdgeInsets        insets;
   NSUInteger          i;
   NSUInteger          j;
   struct NVGcontext   *vg;
   CGColorRef          fore;
   CGColorRef          back;
   CGFont              *font;

   vg = MulleContextGetNVGContext( context);

   font  = [context fontWithNameCString:"sans"];
   nvgFontFace( vg, [font nameCString]);

   MulleRectPartitionHorizontally( [layer canvas], 4, rows, 20);
   for( i = 0; i < 4; i++)
   {
      MulleRectPartitionVertically( rows[ i], 2, columns, 20);
      for( j = 0; j < 2; j++)
      {
         if( j == 0)
         {
            fore = MulleColorMake( 0xFFFFFFFF);
            back = MulleColorMake( 0x000000FF);
         }
         else
         {
            back = MulleColorMake( 0xFFFFFFFF);
            fore = MulleColorMake( 0x000000FF);
         }

         nvgStrokeWidth( vg, 1.0);
         nvgBeginPath( vg);
         nvgStrokeColor( vg, fore);
         nvgFillColor( vg, back);
         nvgRoundedRect( vg, columns[ j].origin.x,
                             columns[ j].origin.y,
                             columns[ j].size.width,
                             columns[ j].size.height,
                             3);
         nvgStroke( vg);
         nvgFill( vg);

         insets = UIEdgeInsetsMake( 2, 2, 2, 2);
         rect   = UIEdgeInsetsInsetRect( columns[ j], insets);
         rect   = CGRectIntegral( rect);

         if( i & 1)
         {
            rect.origin.x += 0.5;
            rect.origin.y += 0.5;
         }

         if( i < 2)
         {
            nvgFontSize( vg, 10);
            drawText( vg, rect, 10, fore, back, 1);
         }
         else
         {
            nvgFontSize( vg, 16);
            drawText( vg, rect, 16, fore, back, 1);
         }
      }
   }
}



void   setupScene( UIView *contentPlane, CGContext *context)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame        = [contentPlane frame];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 20, 20, 20, 20);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   layer = [view layer];
   [layer setDrawCallback:drawStuff];
   [contentPlane addSubview:view];
}


int   main()
{
   CGContext   *context;
   UIWindow    *window;
   CGRect      frame;

   /*
    * window and app
    */
   mulle_testallocator_initialize();
   mulle_default_allocator = mulle_testallocator;

   @autoreleasepool
   {
      frame   = CGRectMake( 0.0, 0.0, 800.0, 600.0);
      window  = [[[UIWindow alloc] initWithFrame:frame] autorelease];
      assert( window);

      [[UIApplication sharedInstance] addWindow:window];

      context = [window context];
      [context setBackgroundColor:CGColorCreateGenericRGB( 0.0, 0.0, 1.0, 1.0)];

      setupScene( [window contentPlane], context);

      [window dump];

      [window renderLoop];
      [[UIApplication sharedInstance] terminate];
   }
   mulle_testallocator_reset();
}

