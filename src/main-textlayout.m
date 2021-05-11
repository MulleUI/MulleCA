#import "import-private.h"

#import "CGContext.h"
#import "CGContext+CGFont.h"
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
static char  *demo_1_text = "f";

static void   demo( CGContext *context, CGRect rect, char *text, char *fontname, int i)
{
   CGPoint          origin;
   CGRect           border;
   CGRect           frame;
   CGSize           size;
   MulleTextLayer   *layer;
   NVGcontext       *vg;
   UIEdgeInsets     insets;
   static CGRect    old[ 4];

   vg = MulleContextGetNVGContext( context);

   layer = [MulleTextLayer layer];
   [layer setCString:text];
   [layer setFontName:fontname];
   [layer setFontPixelSize:10.0];
   [layer setAlignmentMode:CAAlignmentCenter];
   [layer mulleSetVerticalAlignmentMode:MulleTextVerticalAlignmentBottom]; // T
   frame.size = [layer sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                         context:context];
   frame.origin = MulleOriginOfSizeCenteredInRect( frame.size, rect);
   [layer setFrame:frame];

   if( ! CGRectEqualToRect( old[ i], frame))
   {
      old[ i] = frame;
      fprintf( stderr, "%d: %s\n", i, CGRectCStringDescription( frame));
   }

   // TODO: move to context
   [layer setBackgroundColor:MulleColorMake( 0)];
   [layer setBorderColor:MulleColorMake( 0)];
   nvgSave( vg);
   [layer renderInContext:context];
   nvgRestore( vg);
}


static void   demo_0( CGContext *context, CGRect rect)
{
   demo( context, rect, demo_0_text, NULL, 0);
}

static void   demo_1( CGContext *context,  CGRect rect)
{
   demo( context, rect, demo_1_text, NULL, 1);
}

static void   demo_2( CGContext *context,  CGRect rect)
{
   demo( context, rect, demo_0_text, "hacked", 2);
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
   nvgStrokeColor( vg, MulleColorMake( 0x8080007F));
   nvgStroke( vg);
}


#define N_ROWS    2
#define N_COLUMNS 2

static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGRect              rect;
   struct NVGcontext   *vg;
   CGRect              rows[ N_ROWS];
   CGRect              columns[ N_COLUMNS];
   NSUInteger          i;
   NSUInteger          j;
   UIEdgeInsets        insets;

   vg = MulleContextGetNVGContext( context);

   MulleRectPartitionVertically( [layer canvas], N_ROWS, rows, 8);

   //
   //  test UIViewContentMode
   //
   for( i = 0; i < N_ROWS; i++)
   {
      MulleRectPartitionHorizontally( rows[ i], N_COLUMNS, columns, 8);
      for( j = 0; j < N_COLUMNS; j++)
      {
         drawRect( vg, columns[ j]);
         (*demos[ i * 2 + j])( context, columns[ j]);
      }
   }
}

void   setupSceneInPlane( MulleWindowPlane *contentPlane)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   [contentPlane setPadding:UIEdgeInsetsMake( 8, 8, 8, 8)];

   frame = [contentPlane layoutRect];
   view  = [UIView viewWithFrame:frame];
   [view setDrawCallback:drawStuff];
   [contentPlane addSubview:view];
}


int   main()
{
   UIWindow    *window;

   /*
    * window and app
    */
   window  = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 300.0)];
   assert( window);

   [[UIApplication sharedInstance] addWindow:window];

   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];
   [[window context] addFontWithContentsOfFileWithFileRepresentationString:"Roboto-Regular-Hacked.ttf"
                                                   fontNameCString:"hacked"];

   setupSceneInPlane( [window contentPlane]);

   [window dump];

   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
   return( 0);
}

