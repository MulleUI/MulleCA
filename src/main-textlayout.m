#import "import-private.h"

#import "CGContext.h"
#import "CGGeometry+CString.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "UIColor.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"
#import "MulleTextLayer.h"
#import "MulleLayout.h"


static char  *demo_0_text = "VfL_TychoFaurier";
static char  *demo_1_text = "A";

static void   demo( CGContext *context, CGRect rect, char *text, char *fontname, int i)
{
   _NVGtransform    transform;
   CGPoint          origin;
   CGRect           border;
   CGRect           frame;
   CGSize           size;
   MulleTextLayer   *layer;
   NVGcontext       *vg;
   NVGscissor       scissor;
   UIEdgeInsets     insets;
   static CGRect    old[ 4];

   vg = MulleContextGetNVGContext( context);

   layer = [MulleTextLayer layer];
   [layer setCString:text];
   [layer setFontName:fontname];
   [layer setFontPixelSize:10.0];
   [layer setAlignmentMode:CAAlignmentCenter];
   frame.size = [layer sizeToFit:CGSizeMake( INFINITY, INFINITY)
                         context:context];
   frame.origin = MulleSizeGetCenterInRect( frame.size, rect);
   [layer setFrame:frame];

   if( ! CGRectEqualToRect( old[ i], frame))
   {
      old[ i] = frame;
      fprintf( stderr, "%d: %s\n", i, CGRectCStringDescription( frame));
   }

   nvgCurrentTransform( vg, transform);
   nvgGetScissor( vg, &scissor);

   // TODO: move to context
   [layer setTransform:transform
               scissor:&scissor];
   if ( [layer drawInContext:context])
   {
      nvgSetScissor( vg, &scissor);
      nvgResetTransform( vg);
      nvgTransform( vg, transform[ 0], transform[ 1], transform[ 2],
                        transform[ 3], transform[ 4], transform[ 5]);
   }

   // DRAW BORDER MANUALLY
   insets = UIEdgeInsetsMake( 2, 2, 2, 2);
   border = UIEdgeInsetsExtrudeRect( frame, insets);

   nvgBeginPath( vg);
   nvgRect( vg, border.origin.x,
                border.origin.y,
                border.size.width,
                border.size.height);
   nvgStrokeWidth( vg, 1.0);
   nvgStrokeColor(vg, MulleColorCreate( 0x8000007F));
   nvgStroke( vg);

//   [layer drawContentsInContext:context];
}


static void   demo_0( CGContext *context, CGRect rect)
{
//   demo( context, rect, demo_0_text, NULL, 0);
}

static void   demo_1( CGContext *context,  CGRect rect)
{
//   demo( context, rect, demo_1_text, NULL, 1);
}

static void   demo_2( CGContext *context,  CGRect rect)
{
//   demo( context, rect, demo_0_text, "hacked", 2);
}

static void   demo_3( CGContext *context,  CGRect rect)
{
   demo( context, rect, demo_1_text, "hacked", 3);
}

static void   (*demos[ 4])(CGContext *context,  CGRect rect) =
{
   demo_0, demo_1, demo_2, demo_3
};


void   drawRect( NVGcontext *vg,  CGRect rect)
{
   nvgBeginPath( vg);
   nvgRect( vg, rect.origin.x,
                rect.origin.y,
                rect.size.width,
                rect.size.height);
   nvgStrokeWidth( vg, 1.0);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);
}


#define N_ROWS    2
#define N_COLUMNS 2

BOOL  drawStuff( CALayer *layer,
                 CGContext *context,
                 CGRect frame,
                 struct MulleFrameInfo *info)
{
   CGRect              rect;
   struct NVGcontext   *vg;
   CGRect              rows[ N_ROWS];
   CGRect              columns[ N_COLUMNS];
   NSUInteger          i;
   NSUInteger          j;
   UIEdgeInsets        insets;

   vg = MulleContextGetNVGContext( context);

   MulleRectPartititonVertically( frame, N_ROWS, rows, 0);

   //
   //  test UIViewContentMode
   //
   insets = UIEdgeInsetsMake( 8, 8, 8, 8);

   for( i = 0; i < N_ROWS; i++)
   {
      MulleRectPartititonHorizontally( rows[ i], N_COLUMNS, columns, 0);
      for( j = 0; j < N_COLUMNS; j++)
      {
         rect = UIEdgeInsetsInsetRect( columns[ j], insets);
         drawRect( vg, rect);
         (*demos[ i * 2 + j])( context, rect);
      }
   }

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
      [context addFontWithContentsOfFileWithFileRepresentationString:"Roboto-Regular-Hacked.ttf"
                                                     fontNameCString:"hacked"];

      setupScene( [window contentPlane], context);

      [window dump];

      [window renderLoopWithContext:context];
      [[UIApplication sharedInstance] terminate];
   }
}

