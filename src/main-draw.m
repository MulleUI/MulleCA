#define _GNU_SOURCE

#import "import-private.h"

#import "CGContext.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "UIColor.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"
#import "MulleLayout.h"
#include <time.h>

#define DRAW_ALPHA
#define DRAW_RECT
#define DRAW_LINES
//#define ARTIFICIAL_LAG



#define LAG_FRAMES    2

static void   lag( long refreshRate)
{
   struct timespec   sleep;
   long              nsperframe;

   nsperframe    = (1000000000L + (refreshRate - 1)) / refreshRate;
   sleep.tv_sec  = 0.0;
   sleep.tv_nsec = (long) round( nsperframe * LAG_FRAMES);
   nanosleep( &sleep, NULL);
}

// Topics:
//  * create a window
//  * place view inside window
//  * add drawing C code to the views layer to produce the graphics
//  * run renderloop (with event handling)
//  * shows differences for pixel alignment and antialiasing
//
static void   _drawAlpha( NVGcontext *vg,
                          CGRect rect,
                          int antialias)
{
   rect.size.width  -= 50;
   rect.size.height -= 50;

   nvgShapeAntiAlias( vg, antialias);
   nvgStrokeWidth( vg, 10.0);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x8080007F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x0080807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50,
                       rect.origin.y + 50,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x8000807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y + 50,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x8080807F));
   nvgStroke( vg);

   nvgShapeAntiAlias( vg, 1);
}



static void   _drawRects( NVGcontext *vg,
                          CGRect rect,
                          CGColorRef color,
                          int antialias,
                          CGFloat thickness)
{
   nvgShapeAntiAlias( vg, antialias);
   nvgStrokeWidth( vg, thickness);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, color);
   nvgStroke( vg);

   nvgShapeAntiAlias( vg, 1);
}

static NSInteger   lines;

static void   _drawColoredLinesH( NVGcontext *vg,
                                  CGRect rect,
                                  int antialias,
                                  CGFloat thickness)
{
   CGPoint      point;
   NSUInteger   i;
   CGFloat      h;

   nvgShapeAntiAlias( vg, antialias);
   nvgStrokeWidth( vg, thickness);

   h = rect.size.height / 8;

   for( point.x = rect.origin.x; point.x < CGRectGetMaxX( rect); point.x += 2.0)
   {
      point.y = rect.origin.y;
      for( i = 0; i < 8; i++)
      {
         nvgBeginPath( vg);

         nvgMoveTo(vg, point.x, point.y);
         point.y += h;
         nvgLineTo(vg, point.x, point.y);
         switch( i)
         {
         case 0 : nvgStrokeColor( vg, MulleColorMake( 0xFFFFFFFF)); break;
         case 1 : nvgStrokeColor( vg, MulleColorMake( 0xFF0000FF)); break;
         case 2 : nvgStrokeColor( vg, MulleColorMake( 0x00FF00FF)); break;
         case 3 : nvgStrokeColor( vg, MulleColorMake( 0x0000FFFF)); break;
         case 4 : nvgStrokeColor( vg, MulleColorMake( 0xFFFF00FF)); break;
         case 5 : nvgStrokeColor( vg, MulleColorMake( 0xFF00FFFF)); break;
         case 6 : nvgStrokeColor( vg, MulleColorMake( 0x00FFFFFF)); break;
         case 7 : nvgStrokeColor( vg, MulleColorMake( 0xFFFFFFFF)); break;
         }
         nvgStroke( vg);
         if( lines >= 0)
            ++lines;
      }
   }

   nvgShapeAntiAlias( vg, 1);
}


static void   _drawColoredLinesV( NVGcontext *vg,
                                  CGRect rect,
                                  int antialias,
                                  CGFloat thickness)
{
   CGPoint      point;
   NSUInteger   i;
   CGFloat      w;

   nvgShapeAntiAlias( vg, antialias);
   nvgStrokeWidth( vg, thickness);

   w = rect.size.width / 8;

   for( point.y = rect.origin.y; point.y < CGRectGetMaxY( rect); point.y += 2.0)
   {
      point.x = rect.origin.x;
      for( i = 0; i < 8; i++)
      {
         nvgBeginPath( vg);

         nvgMoveTo(vg, point.x, point.y);
         point.x += w;
         nvgLineTo(vg, point.x, point.y);
         switch( i)
         {
         case 0 : nvgStrokeColor( vg, MulleColorMake( 0xFFFFFFFF)); break;
         case 1 : nvgStrokeColor( vg, MulleColorMake( 0xFF0000FF)); break;
         case 2 : nvgStrokeColor( vg, MulleColorMake( 0x00FF00FF)); break;
         case 3 : nvgStrokeColor( vg, MulleColorMake( 0x0000FFFF)); break;
         case 4 : nvgStrokeColor( vg, MulleColorMake( 0xFFFF00FF)); break;
         case 5 : nvgStrokeColor( vg, MulleColorMake( 0xFF00FFFF)); break;
         case 6 : nvgStrokeColor( vg, MulleColorMake( 0x00FFFFFF)); break;
         case 7 : nvgStrokeColor( vg, MulleColorMake( 0xFFFFFFFF)); break;
         }
         nvgStroke( vg);
         if( lines >= 0)
            ++lines;
      }
   }

   nvgShapeAntiAlias( vg, 1);
}


static void   _drawColoredLinesHV( NVGcontext *vg,
                                   CGRect rect,
                                   int antialias,
                                   CGFloat thickness)
{
   CGPoint      point;
   NSUInteger   i;
   CGFloat      w;

   nvgShapeAntiAlias( vg, antialias);
   nvgStrokeWidth( vg, thickness);
   nvgSave( vg);
   nvgScissor( vg, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
   nvgTranslate(vg, rect.origin.x + rect.size.width / 2.0, rect.origin.y + rect.size.height / 2.0);
   nvgRotate(vg, 0.9 * NVG_PI*2);
   nvgTranslate(vg, -rect.origin.x - rect.size.width / 2.0, -rect.origin.y - rect.size.height / 2.0);

   w = rect.size.width / 8;

   for( point.y = rect.origin.y; point.y < CGRectGetMaxY( rect); point.y += 2.0)
   {
      point.x = rect.origin.x;
      for( i = 0; i < 8; i++)
      {
         nvgBeginPath( vg);

         nvgMoveTo(vg, point.x, point.y);
         point.x += w;
         nvgLineTo(vg, point.x, point.y);
         switch( i)
         {
         case 0 : nvgStrokeColor( vg, MulleColorMake( 0xFFFFFFFF)); break;
         case 1 : nvgStrokeColor( vg, MulleColorMake( 0xFF0000FF)); break;
         case 2 : nvgStrokeColor( vg, MulleColorMake( 0x00FF00FF)); break;
         case 3 : nvgStrokeColor( vg, MulleColorMake( 0x0000FFFF)); break;
         case 4 : nvgStrokeColor( vg, MulleColorMake( 0xFFFF00FF)); break;
         case 5 : nvgStrokeColor( vg, MulleColorMake( 0xFF00FFFF)); break;
         case 6 : nvgStrokeColor( vg, MulleColorMake( 0x00FFFFFF)); break;
         case 7 : nvgStrokeColor( vg, MulleColorMake( 0xFFFFFFFF)); break;
         }
         nvgStroke( vg);
         if( lines >= 0)
            ++lines;
      }
   }
   nvgRestore( vg);

   nvgShapeAntiAlias( vg, 1);
}


static void   _drawColoredLines( NVGcontext *vg,
                                 CGRect rect,
                                 int antialias,
                                 CGFloat thickness)
{
   CGRect   rows[ 2];
   CGRect   columns[ 2];

   MulleRectPartitionVertically( rect, 2, rows, 2);

   MulleRectPartitionHorizontally( rows[ 0], 2, columns, 2);

   _drawColoredLinesH( vg, columns[ 0], antialias, thickness);
   _drawColoredLinesV( vg, columns[ 1], antialias, thickness);

   MulleRectPartitionHorizontally( rows[ 1], 2, columns, 2);

   _drawColoredLinesHV( vg, columns[ 0], antialias, thickness);
}


static void   drawStuff( CALayer *layer, CGContext *context)
{
   CGRect              rows[ 3];
   CGRect              columns[ 8];
   CGRect              subrows[ 2];
   CGRect              rect;
   UIEdgeInsets        insets;
   NSUInteger          i;
   NSUInteger          j;
   struct NVGcontext   *vg;
   CGColorRef          fore;
   CGColorRef          back;
   CGRect              canvas;

   vg = MulleContextGetNVGContext( context);

   canvas = [layer canvas];
   MulleRectPartitionVertically( canvas, 3, rows, 8);

   // draw antialias demo shape on white
   MulleRectPartitionHorizontally( rows[ 0], 4, columns, 8);

   for( i = 0; i < 4; i++)
   {
      nvgStrokeWidth( vg, 1.0);
      nvgBeginPath( vg);
      nvgStrokeColor( vg, MulleColorMake( 0x808080FF));
      nvgRoundedRect( vg, columns[ i].origin.x,
                          columns[ i].origin.y,
                          columns[ i].size.width,
                          columns[ i].size.height,
                          3);
      nvgStroke( vg);

      rect.size   = CGSizeMake( 150, 150);
      rect.origin = MulleOriginOfSizeCenteredInRect( rect.size, columns[ i]);
      rect        = CGRectIntegral( rect);

      if( i & 1)
      {
         rect.origin.x += 0.5;
         rect.origin.y += 0.5;
      }
#ifdef DRAW_ALPHA
      _drawAlpha( vg, rect, i >= 2);
#endif
   }

   // draw single lines of width 1 on black
   MulleRectPartitionHorizontally( rows[ 1], 8, columns, 8);
   for( i = 0; i < 8; i++)
   {
      MulleRectPartitionVertically( columns[ i], 2, subrows, 8);

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
         nvgRoundedRect( vg, subrows[ j].origin.x,
                             subrows[ j].origin.y,
                             subrows[ j].size.width,
                             subrows[ j].size.height,
                             3);
         nvgStroke( vg);
         nvgFill( vg);

         insets = UIEdgeInsetsMake( 10, 10, 10, 10);
         rect   = UIEdgeInsetsInsetRect( subrows[ j], insets);
         rect   = CGRectIntegral( rect);

         if( i & 1)
         {
            rect.origin.x += 0.5;
            rect.origin.y += 0.5;
         }
#ifdef DRAW_RECT
         _drawRects( vg, rect, fore, i >= 2, i >= 4 ? 0.5 : 1.0);
#endif
      }
   }

   // draw colored lines

   // draw single lines of width 1 on black
   MulleRectPartitionHorizontally( rows[ 2], 8, columns, 8);
   for( i = 0; i < 8; i++)
   {
      MulleRectPartitionVertically( columns[ i], 2, subrows, 8);

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
         nvgRoundedRect( vg, subrows[ j].origin.x,
                             subrows[ j].origin.y,
                             subrows[ j].size.width,
                             subrows[ j].size.height,
                             3);
         nvgStroke( vg);
         nvgFill( vg);

         insets = UIEdgeInsetsMake( 10, 10, 10, 10);
         rect   = UIEdgeInsetsInsetRect( subrows[ j], insets);
         rect   = CGRectIntegral( rect);

         if( i & 1)
         {
            rect.origin.x += 0.5;
            rect.origin.y += 0.5;
         }
#ifdef DRAW_LINES
         _drawColoredLines( vg, rect, i >= 2, i >= 4 ? 0.5 : 1.0);
#endif
      }
      if( lines > 0)
      {
         fprintf( stderr, "lines drawn: %ld\n", lines);
         lines = -1;
      }
   }
#ifdef ARTIFICIAL_LAG
   lag( info->refreshRate);
#endif
}


void   setupScene( MulleWindowPlane *contentPlane)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;

   frame        = [contentPlane bounds];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 20, 20, 20, 20);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view setDrawCallback:drawStuff];
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

      setupScene( [window contentPlane]);

      [[UIApplication sharedInstance] addWindow:window];
      [window renderLoop];
      [[UIApplication sharedInstance] terminate];
   }
   mulle_testallocator_reset();
}

