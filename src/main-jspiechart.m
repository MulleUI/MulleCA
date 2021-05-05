#import "import-private.h"

#import "CALayer.h"
#import "CGContext.h"
#import "CGContext+CGFont.h"
#import "UIWindow.h"
#import "UIColor.h"
#import "UIApplication.h"
#import "UIButton.h"
#import "UIStackView.h"
#import "UIScrollView.h"
#import "MulleBitmapImage.h"
#import "MulleMenu.h" // rename to MulleMenuView.h
#import "MulleMenuButton.h"
#import "MullePopUpButton.h"
#import "UIView+Layout.h"
#import "UIView+UIEvent.h"
#import "NSValue+CGGeometry.h"
#import "UIEvent.h"
#import <string.h>


static MulleBitmapImage      *bengalBitmap;
static MulleBitmapImage      *patternBitmap;

static char  *javascript = "quadcurve.js";
static char  *titles[] =
{
   "quadcurve.js",
   "donutpie.js",
   "pie-chart-demo.js",
   "colorsandlines.js",
   "drawings.js"
};


static UIEvent   *buttonClicked( id <UIControl> control, UIEvent *event)
{
   fprintf( stderr, "%s\n", __PRETTY_FUNCTION__);

   javascript = [[(MullePopUpButton *) control clickedButton] titleCString];
   return( nil);
}



static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGRect              rect;
   CGRect              canvas;
   MulleJS             *js;
   struct NVGcontext   *nvg;
   CGSize              size;
   char                *filename;

   nvg = MulleContextGetNVGContext( context);

   // clip javascript drawing
   canvas = [layer canvas];

   nvgIntersectScissor( nvg, canvas.origin.x, canvas.origin.y, canvas.size.width, canvas.size.height);
   nvgTranslate( nvg, canvas.origin.x, canvas.origin.y);

   @autoreleasepool
   {
      [context fontWithNameCString:"sans"];
      js = [MulleJS object];
      [js setObject:context
             forKey:@"CGContext"];
      [js setObject:[NSValue valueWithPointer:nvg]
             forKey:@"nvgContext"];
      [js setObject:bengalBitmap
             forKey:@"bengal"];
      [js setObject:patternBitmap
             forKey:@"pattern"];
      [js setObject:@(canvas.size.width)
             forKey:@"width"];
      [js setObject:@(canvas.size.height)
             forKey:@"height"];
      [js setObject:[UIColor mulleValueWithCGColor:[(id) layer backgroundColor]]
             forKey:@"backgroundColor"];

      filename = MulleObjC_asprintf( "/home/src/srcO/MulleUI/src/%s", javascript);
      [js runScriptFileCString:filename];
   }
}


static void   setupSceneInContentPlane( MulleWindowPlane *contentPlane)
{
   UIView             *rootView;
   UIView             *displayView;
   MulleMenu          *menuView;
   MullePopUpButton   *button;
   MulleMenuButton    *menuButton;
   CALayer            *layer;
   CGRect             frame;
   int                i;
   UIWindow           *window;

   window = [contentPlane window];

   frame = [contentPlane bounds];
   assert( frame.size.width > 0.0);
   assert( frame.size.width  > 0.0);

   rootView  = [UIView viewWithFrame:CGRectZero];
   [rootView setDebugNameCString:"RootView"];
   [rootView setBackgroundColor:getNVGColor( 0xFFFFFFFF)];
   [rootView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];

   // LCD Display container
   // because the root view is still zero sized, the -10.2 as size is really
   // the margin. The 100 is the height of the display

   displayView  = [UIView viewWithFrame:CGRectZero];
   [displayView setBackgroundColor:getNVGColor( 0x00007FFF)];
   [displayView setDebugNameCString:"DisplayView"];
   [displayView setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
   [displayView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];

   layer = [displayView layer];
   [displayView setDrawCallback:drawStuff];
   [rootView addSubview:displayView];

   button = [MullePopUpButton viewWithFrame:CGRectMake( 0, 0, 120, 20)];
   [button setTitleCString:"Change"];
   [button setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
   [button setAutoresizingMask:MulleUIViewAutoresizingStickToTop|MulleUIViewAutoresizingStickToLeft];
   [button setClick:buttonClicked];

   // not strdupped currently!
   [button setTitlesCStrings:titles
                       count:sizeof( titles) / sizeof( char *)];

   [displayView addSubview:button];

   [rootView setNeedsLayout];

   [contentPlane addSubview:rootView];
}


int  main()
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *application;
   MulleJS         *js;
      /*
       * window and app
       */

   /* move singleton outside of test allocator code */
   application = [UIApplication sharedInstance];

   mulle_testallocator_initialize();
   mulle_default_allocator = mulle_testallocator;

   @autoreleasepool
   {
      bengalBitmap   = [[[MulleBitmapImage alloc] initWithContentsOfFileWithFileRepresentationString:"/home/src/srcO/MulleUI/bengal_s.jpg"] autorelease];
      patternBitmap = [[[MulleBitmapImage alloc] initWithContentsOfFileWithFileRepresentationString:"/home/src/srcO/MulleUI/pattern.png"] autorelease];

      window  = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 729.00, 449.00)] autorelease];
      assert( window);

      [application addWindow:window];

      setupSceneInContentPlane( [window contentPlane]);

      [window dump];

      context = [window context];
      [window renderLoop];

      [application terminate];
   }

   /*
      Hunt for leaks:

      MULLE_OBJC_EPHEMERAL_SINGLETON=YES \
      MULLE_OBJC_TRACE_INSTANCE=YES \
      MULLE_OBJC_TRACE_METHOD_CALL=YES \
      MULLE_TESTALLOCATOR_TRACE=2 \
         ./kitchen/Debug/calculator
   */

   mulle_testallocator_reset();
  }

