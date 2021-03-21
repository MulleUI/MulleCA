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


//
// draw a square in a rect, with the various contentmodes
//
void   drawContentMode( NVGcontext *vg,
                        CGRect rect,
                        UIViewContentMode contentMode)
{
   CGSize   size;
   CGRect   smallRect;
   CGFloat  hue;

   nvgBeginPath( vg);
   nvgRect( vg, rect.origin.x,
                rect.origin.y,
                rect.size.width,
                rect.size.height);
   nvgStrokeWidth( vg, 1.0);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);

   size.width  = rect.size.width  / 2.0;
   size.height = rect.size.height / 2.0 > size.width ? size.width : rect.size.height / 2.0;

   smallRect = MulleSizeApplyContentModeInRect( size, contentMode, rect);
   nvgBeginPath( vg);
   nvgRoundedRect( vg, smallRect.origin.x,
                       smallRect.origin.y,
                       smallRect.size.width,
                       smallRect.size.height,
                       smallRect.size.width / 10.0);
   nvgStrokeWidth( vg, 2.0);
   hue = 0.2 + 0.6 * ((double) contentMode / (N_UIViewContentModeNames - 1));
   nvgStrokeColor( vg, MulleColorCreateHSLA( hue, 1.0, 0.7, 0.7));
   nvgStroke( vg);
}

//
// draw two squares in a rect, with the various rectangle placements
//
void   drawRectPlacement( NVGcontext *vg,
                          CGRect rect,
                          NSUInteger i)
{
   CGSize   size;
   CGRect   smallRect;
   CGRect   otherRect;
   CGFloat  hue;
   UIViewContentMode   contentMode;

   assert( i >= 0 && i <= 36);

   nvgBeginPath( vg);
   nvgRect( vg, rect.origin.x,
                rect.origin.y,
                rect.size.width,
                rect.size.height);
   nvgStrokeWidth( vg, 1.0);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);

   size.width  = rect.size.width  / 3.0;
   size.height = rect.size.height / 3.0 > size.width ? size.width : rect.size.height / 3.0;

   smallRect = MulleSizeApplyContentModeInRect( size, UIViewContentModeCenter, rect);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, smallRect.origin.x,
                       smallRect.origin.y,
                       smallRect.size.width,
                       smallRect.size.height,
                       smallRect.size.width / 10.0);
   nvgStrokeWidth( vg, 2.0);
   hue = 0.0 + 0.5 * ((double) i / (36 - 1));
   nvgStrokeColor( vg, MulleColorCreateHSLA( hue, 1.0, 0.7, 0.7));
   nvgStroke( vg);

   size.width  = rect.size.width  / 4.0;
   size.height = rect.size.height / 4.0 > size.width ? size.width : rect.size.height / 4.0;

   otherRect.size   = size;
   otherRect.origin = rect.origin;

   contentMode      = MulleLayoutPlacementMake( i % 6, i / 6);
   otherRect.origin = MullePlaceRectNextToRect( otherRect, smallRect, contentMode);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, otherRect.origin.x,
                       otherRect.origin.y,
                       otherRect.size.width,
                       otherRect.size.height,
                       otherRect.size.width / 10.0);
   hue = 0.5 + 0.5 * ((double) i / (36 - 1));
   nvgFillColor( vg, MulleColorCreateHSLA( hue, 1.0, 0.7, 0.7));
   nvgFill( vg);
}


static unsigned char   preferences[] =
{
   MulleLayoutPlacementLeftAligned << 4  | MulleLayoutPlacementDown,
   MulleLayoutPlacementRightAligned << 4 | MulleLayoutPlacementUp,
   MulleLayoutPlacementRightAligned << 4 | MulleLayoutPlacementDown,
   MulleLayoutPlacementLeftAligned << 4  | MulleLayoutPlacementUp,
   MulleLayoutPlacementCenter << 4       | MulleLayoutPlacementMiddle
};

//
// draw two squares in a rect, with the various rectangle placements
//
void   drawRectSpacePlacement( NVGcontext *vg,
                               CGRect rect,
                               UIViewContentMode rectMode)
{
   CGSize   size;
   CGRect   smallRect;
   CGRect   otherRect;
   CGFloat  hue;

   nvgBeginPath( vg);
   nvgRect( vg, rect.origin.x,
                rect.origin.y,
                rect.size.width,
                rect.size.height);
   nvgStrokeWidth( vg, 1.0);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);

   size.width  = rect.size.width  / 3.0;
   size.height = rect.size.height / 3.0 > size.width ? size.width : rect.size.height / 3.0;

   smallRect = MulleSizeApplyContentModeInRect( size, rectMode, rect);
   nvgBeginPath( vg);
   nvgRoundedRect( vg, smallRect.origin.x,
                       smallRect.origin.y,
                       smallRect.size.width,
                       smallRect.size.height,
                       smallRect.size.width / 10.0);
   nvgStrokeWidth( vg, 2.0);
   hue = 0.0 + 0.5 * ((double) rectMode / (N_UIViewContentModeNames - 1));
   nvgStrokeColor( vg, MulleColorCreateHSLA( hue, 1.0, 0.7, 0.7));
   nvgStroke( vg);

   otherRect.origin      = rect.origin;
   otherRect.size.width  = rect.size.width * 2.0 / 3.0;
   otherRect.size.height = rect.size.height * 2.0 / 3.0 > otherRect.size.width
                             ? otherRect.size.width
                             : rect.size.height * 2.0 / 3.0;

   otherRect.origin = MullePlaceRectNextToRectInSpace( otherRect,
                                                       smallRect,
                                                       rect,
                                                       (sizeof( preferences) / sizeof( preferences[ 0])),
                                                       preferences,
                                                       (sizeof( preferences) / sizeof( preferences[ 0])) - 1);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, otherRect.origin.x,
                       otherRect.origin.y,
                       otherRect.size.width,
                       otherRect.size.height,
                       otherRect.size.width / 10.0);
   hue = 0.5 + 0.5 * ((double) rectMode / (N_UIViewContentModeNames - 1));
   nvgFillColor( vg, MulleColorCreateHSLA( hue, 1.0, 0.7, 0.7));
   nvgFill( vg);
}


static void   drawLayoutInSpace( NVGcontext *vg,
                                 CGRect rect)
{
   struct MulleLayout  layout;
   CGRect              part;
   BOOL                flag;
   NSUInteger          i;

   _MulleLayoutInitWithRect( &layout, rect, UIEdgeInsetsMake( 3, 3, 3, 3));

   nvgBeginPath( vg);
   nvgRect( vg, rect.origin.x,
                rect.origin.y,
                rect.size.width,
                rect.size.height);
   nvgStrokeWidth( vg, 1.0);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);

   i    = 0;
   flag = NO;
   for(;;)
   {
      part = _MulleLayoutAddToRow( &layout,
                                   CGSizeMake( (rect.size.width - 6.0 - 5 * 10.0) / 6.0,
                                               ((rect.size.height - 6.0) * (i + 1) / 6.0) / 3.0),
                                   MulleEdgeInsetsMake( 0, 0, 0, 10));
      if( part.size.width == 0.0)
      {
         if( flag == YES)
            break;
         flag = YES;
         i = 0;
         _MulleLayoutNewRow( &layout);
         continue;
      }

      flag = NO;
      nvgBeginPath( vg);
      nvgRect( vg, part.origin.x,
                   part.origin.y,
                   part.size.width,
                   part.size.height);
      nvgStrokeWidth( vg, 1.0);
      nvgStrokeColor( vg, MulleColorCreateRandomOpaque());
      nvgStroke( vg);
      ++i;
   }

   MulleLayoutDone( &layout);
}


#define N_ROWS 4


BOOL  drawStuff( CALayer *layer,
                 CGContext *context,
                 CGRect frame,
                 struct MulleFrameInfo *info)
{
   CGRect              rect;
   struct NVGcontext   *vg;
   CGRect              rows[ N_ROWS];
   CGRect              subrows[ 2];
   CGRect              rects[ N_UIViewContentModeNames > 18 ? N_UIViewContentModeNames : 18];
   NSUInteger          i;
   NSUInteger          j;
   UIEdgeInsets        insets;

   vg = MulleContextGetNVGContext( context);

   MulleRectPartititonVertically( frame, N_ROWS, rows, 0);

   //
   //  test UIViewContentMode
   //
   MulleRectPartititonHorizontally( rows[ 0], N_UIViewContentModeNames, rects, 0);

   for( i = 0; i < N_UIViewContentModeNames; i++)
   {
      insets = UIEdgeInsetsMake( 4, 4, 4, 4);
      drawContentMode( vg, UIEdgeInsetsInsetRect( rects[ i], insets), (UIViewContentMode) i);
   }

   //
   // test rectangle placement
   //
   MulleRectPartititonVertically( rows[ 1], 2, subrows, 0);
   for( j = 0; j < 2; j++)
   {
      MulleRectPartititonHorizontally( subrows[ j], 18, rects, 0);
      for( i = 0; i < 18; i++)
      {
         drawRectPlacement( vg, UIEdgeInsetsInsetRect( rects[ i], insets), j * 18 + i);
      }
   }

   //
   // test rectangle placement in space
   //
   MulleRectPartititonHorizontally( rows[ 2], N_UIViewContentModeNames - UIViewContentModeCenter, rects, 0);
   for( i = UIViewContentModeCenter; i < N_UIViewContentModeNames; i++)
   {
      drawRectSpacePlacement( vg,
                              UIEdgeInsetsInsetRect( rects[ i - UIViewContentModeCenter], insets),
                              i);
   }

   //
   // test layout struct
   //
   drawLayoutInSpace( vg, UIEdgeInsetsInsetRect( rows[ 3], insets));

   return( NO);
}

// scale stuff for stream
#define SCALE     2.0

void   setupScene( MulleWindowPlane *contentPlane, CGContext *context)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame  = [contentPlane frame];

   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   layer = [view layer];
   [layer setDrawContentsCallback:drawStuff];
   [contentPlane addSubview:view];
}


int   main()
{
   CGContext   *context;
   UIWindow    *window;

   /*
    * window and app
    */
   @autoreleasepool
   {
      window  = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 400.0 * SCALE, 300.0 * SCALE)] autorelease];
      assert( window);

      [[UIApplication sharedInstance] addWindow:window];

      context = [window createContext];
      [context setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

      setupScene( [window contentPlane], context);

      [window dump];

      [window renderLoopWithContext:context];
      [[UIApplication sharedInstance] terminate];
   }
}

