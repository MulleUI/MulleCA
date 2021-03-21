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


// Topics:
//  * create a window
//  * place view inside window
//  * add drawing C code to the views layer to produce the graphics
//  * run renderloop (with event handling)
//  * shows differences for pixel alignment and antialiasing
//
void   _drawAlpha( NVGcontext *vg,
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
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorCreate( 0x0080807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50,
                       rect.origin.y + 50,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorCreate( 0x8000807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y + 50,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080807F));
   nvgStroke( vg);

   nvgShapeAntiAlias( vg, 1);
}



void   _drawRects( NVGcontext *vg,
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





void   _drawColoredLinesH( NVGcontext *vg,
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
         case 0 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFFFFFF)); break;
         case 1 : nvgStrokeColor( vg, MulleColorCreate( 0xFF0000FF)); break;
         case 2 : nvgStrokeColor( vg, MulleColorCreate( 0x00FF00FF)); break;
         case 3 : nvgStrokeColor( vg, MulleColorCreate( 0x0000FFFF)); break;
         case 4 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFF00FF)); break;
         case 5 : nvgStrokeColor( vg, MulleColorCreate( 0xFF00FFFF)); break;
         case 6 : nvgStrokeColor( vg, MulleColorCreate( 0x00FFFFFF)); break;
         case 7 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFFFFFF)); break;
         }
         nvgStroke( vg);
      }
   }

   nvgShapeAntiAlias( vg, 1);
}


void   _drawColoredLinesV( NVGcontext *vg,
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
         case 0 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFFFFFF)); break;
         case 1 : nvgStrokeColor( vg, MulleColorCreate( 0xFF0000FF)); break;
         case 2 : nvgStrokeColor( vg, MulleColorCreate( 0x00FF00FF)); break;
         case 3 : nvgStrokeColor( vg, MulleColorCreate( 0x0000FFFF)); break;
         case 4 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFF00FF)); break;
         case 5 : nvgStrokeColor( vg, MulleColorCreate( 0xFF00FFFF)); break;
         case 6 : nvgStrokeColor( vg, MulleColorCreate( 0x00FFFFFF)); break;
         case 7 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFFFFFF)); break;
         }
         nvgStroke( vg);
      }
   }

   nvgShapeAntiAlias( vg, 1);
}


void   _drawColoredLinesHV( NVGcontext *vg,
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
         case 0 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFFFFFF)); break;
         case 1 : nvgStrokeColor( vg, MulleColorCreate( 0xFF0000FF)); break;
         case 2 : nvgStrokeColor( vg, MulleColorCreate( 0x00FF00FF)); break;
         case 3 : nvgStrokeColor( vg, MulleColorCreate( 0x0000FFFF)); break;
         case 4 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFF00FF)); break;
         case 5 : nvgStrokeColor( vg, MulleColorCreate( 0xFF00FFFF)); break;
         case 6 : nvgStrokeColor( vg, MulleColorCreate( 0x00FFFFFF)); break;
         case 7 : nvgStrokeColor( vg, MulleColorCreate( 0xFFFFFFFF)); break;
         }
         nvgStroke( vg);
      }
   }
   nvgRestore( vg);

   nvgShapeAntiAlias( vg, 1);
}




void   _drawColoredLines( NVGcontext *vg,
                           CGRect rect,
                           int antialias,
                           CGFloat thickness)
{
   CGRect   rows[ 2];
   CGRect   columns[ 2];

   MulleRectPartititonVertically( rect, 2, rows, 2);

   MulleRectPartititonHorizontally( rows[ 0], 2, columns, 2);

   _drawColoredLinesH( vg, columns[ 0], antialias, thickness);
   _drawColoredLinesV( vg, columns[ 1], antialias, thickness);

   MulleRectPartititonHorizontally( rows[ 1], 2, columns, 2);

   _drawColoredLinesHV( vg, columns[ 0], antialias, thickness);
}


BOOL  drawStuff( CALayer *layer,
                 CGContext *context,
                 CGRect frame,
                 struct MulleFrameInfo *info)
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

   vg = MulleContextGetNVGContext( context);

   MulleRectPartititonVertically( frame, 3, rows, 8);

   // draw antialias demo shape on white
   MulleRectPartititonHorizontally( rows[ 0], 4, columns, 8);

   for( i = 0; i < 4; i++)
   {
      nvgStrokeWidth( vg, 1.0);
      nvgBeginPath( vg);
      nvgStrokeColor( vg, MulleColorCreate( 0x808080FF));
      nvgRoundedRect( vg, columns[ i].origin.x,
                          columns[ i].origin.y,
                          columns[ i].size.width,
                          columns[ i].size.height,
                          3);
      nvgStroke( vg);

      rect.size   = CGSizeMake( 150, 150);
      rect.origin = MulleSizeGetCenterInRect( rect.size, columns[ i]);
      rect        = CGRectIntegral( rect);

      if( i & 1)
      {
         rect.origin.x += 0.5;
         rect.origin.y += 0.5;
      }

      _drawAlpha( vg, rect, i >= 2);
   }

   // draw single lines of width 1 on black
   MulleRectPartititonHorizontally( rows[ 1], 8, columns, 8);
   for( i = 0; i < 8; i++)
   {
      MulleRectPartititonVertically( columns[ i], 2, subrows, 8);

      for( j = 0; j < 2; j++)
      {
         if( j == 0)
         {
            fore = MulleColorCreate( 0xFFFFFFFF);
            back = MulleColorCreate( 0x000000FF);
         }
         else
         {
            back = MulleColorCreate( 0xFFFFFFFF);
            fore = MulleColorCreate( 0x000000FF);
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

         _drawRects( vg, rect, fore, i >= 2, i >= 4 ? 0.5 : 1.0);
      }
   }

   // draw colored lines

   // draw single lines of width 1 on black
   MulleRectPartititonHorizontally( rows[ 2], 8, columns, 8);
   for( i = 0; i < 8; i++)
   {
      MulleRectPartititonVertically( columns[ i], 2, subrows, 8);

      for( j = 0; j < 2; j++)
      {
         if( j == 0)
         {
            fore = MulleColorCreate( 0xFFFFFFFF);
            back = MulleColorCreate( 0x000000FF);
         }
         else
         {
            back = MulleColorCreate( 0xFFFFFFFF);
            fore = MulleColorCreate( 0x000000FF);
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

         _drawColoredLines( vg, rect, i >= 2, i >= 4 ? 0.5 : 1.0);
      }
   }


   return( NO);
}


// scale stuff for stream
#define SCALE     2.0

void   setupScene( UIWindow *window, CGContext *context)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame        = [window frame];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 20, 20, 20, 20);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   layer = [view layer];
   [layer setDrawContentsCallback:drawStuff];
   [window addSubview:view];
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
      window  = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 400.0 * SCALE, 300.0 * SCALE)] autorelease];
      assert( window);

      [[UIApplication sharedInstance] addWindow:window];

      context = [window createContext];
      [context setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

      setupScene( window, context);

      [window dump];

      [window renderLoopWithContext:context];
      [[UIApplication sharedInstance] terminate];
   }
   mulle_testallocator_reset();
}

