#import "import-private.h"

#import "MulleSVGImage.h"
#import "MulleSVGLayer.h"
#import "MulleBitmapImage.h"
#import "MulleImageLayer.h"
#import "CGContext.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIButton.h"
#import "UIColor.h"
#import "UIScrollView.h"
#import "UIEvent.h"
#import <string.h>


// stolen from catgl ©2015,2018 Yuichiro Nakada
#define W  200
#define H  100

// #include "Ghostscript_Tiger-svg.inc"
// #include "sealie-bitmap.inc"
// #include "turtle-bitmap.inc"
// #include "viech-bitmap.inc"

#if 0
static char   svginput[] = \
"<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">\n"
"   <rect x=\"100\" y=\"50\" width=\"200\" height=\"100\" stroke=\"#c04949\" stroke-linejoin=\"round\" stroke-width=\"5.265\"/>\n"
"</svg>\n"
"\n"
;
#endif


static UIEvent   *button_callback( UIButton *button, UIEvent *event)
{
   fprintf( stderr, "button_callback: %s\n", [button cStringDescription]);
   return( nil);
}


static UIEvent   *scroll_callback( UIButton *button, UIEvent *event)
{
   UIScrollView   *scroller;
   CGPoint        offset;

   fprintf( stderr, "scroll_callback: %s\n", [button cStringDescription]);

   scroller = (UIScrollView *) [[button superview] superview];
   assert( [scroller isKindOfClass:[UIScrollView class]]);

   offset    = [scroller contentOffset];
   offset.y += 10;
   [scroller setContentOffset:offset];

   return( nil);
}


static UIEvent   *dump_window( UIButton *button, UIEvent *event)
{
   fprintf( stderr, "dump_window: %s\n", [button cStringDescription]);

   [[button window] dump];

   return( nil);
}

// scale stuff for stream

static UIWindow  *create_window( MulleBitmapImage   *tigerBitmap,
                                 MulleBitmapImage   *sealieBitmap)
{
   MulleImageLayer    *buttonLayer;
   CGRect             frame;
   CGRect             windowFrame;
   CGRect             bounds;
   CGContext          *context;
   UIWindow           *window;
   UIView             *view;
   UIView             *contentView;
   UIButton           *button;
   UIButton           *insideButton;
   UIButton           *nestedButton;
   UIButton           *inScrollerButton;
   UIScrollView       *scroller;

#if 0
   sealieBitmap = [[[MulleBitmapImage alloc] initWithConstRGBA:sealie_bitmap
                                                     bitmapSize:sealie_bitmap_size]
                                                  autorelease];
#endif
   // 1280x878
   tigerBitmap = [[[MulleBitmapImage alloc] initWithContentsOfFileWithFileRepresentationString:"/home/src/srcO/MulleUI/bengal.jpg"] autorelease];
   assert( tigerBitmap);

   // WINDOW
   windowFrame = CGRectMake( 0.0, 200.0, 640, 400.0);
   window      = [[[UIWindow alloc] initWithFrame:windowFrame] autorelease];
   assert( window);

   contentView = [window contentPlane];
   [contentView setBackgroundColor:[UIColor yellowColor]];


   // BUTTON IN SCROLLVIEW
   buttonLayer = [[[MulleImageLayer alloc] initWithImage:tigerBitmap] autorelease];
   // [buttonLayer setDebugNameCString:"button"];
   frame.origin       = CGPointMake( 0.0, 0.0);
   frame.size.width   = 640 * 10;
   frame.size.height  = 400 * 10;
   [buttonLayer setFrame:frame];
   fprintf( stderr, "layer: %p\n", buttonLayer);

   inScrollerButton = [[[UIButton alloc] initWithLayer:buttonLayer] autorelease];
//   [inScrollerButton setBackgroundImage:tigerBitmap
//                               forState:UIControlStateNormal];
#if 0                               
   [inScrollerButton setBackgroundImage:sealieBitmap
                               forState:UIControlStateSelected];
   [inScrollerButton setClick:dump_window];
#endif   
//   [contentView addSubview:inScrollerButton];

   // SCROLLVIEW
   bounds   = frame;
   frame    = CGRectMake( 20.0, 20.0, 640 - 40.0, 400.0 - 40.0);
   scroller = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
   [scroller setZoomEnabled:YES];
   [scroller setContentSize:bounds.size];
   [[scroller contentView] addSubview:inScrollerButton];
   [contentView addSubview:scroller];

   [window dump];
   return( window);
}



int   main( int argc, char *argv[])
{
   MulleBitmapImage   *sealieBitmap;
   MulleBitmapImage   *tigerBitmap;
   CGContext          *context;
   UIWindow           *window;
   UIApplication      *application;

   sealieBitmap = NULL;
#if 0
   sealieBitmap = [[[MulleBitmapImage alloc] initWithConstRGBA:sealie_bitmap
                                                     bitmapSize:sealie_bitmap_size]
                                                  autorelease];
#endif
   tigerBitmap = [[[MulleBitmapImage alloc] initWithContentsOfFileWithFileRepresentationString:"/home/src/srcO/MulleUI/bengal.jpg"] autorelease];
   assert( tigerBitmap);

   // WINDOW
   window = create_window( tigerBitmap, sealieBitmap);
   assert( window);

   application = [UIApplication sharedInstance];
   [application addWindow:window];
   [NSThread detachNewThreadSelector:@selector( runInApplication:)
                            toTarget:window
                          withObject:application];

   window = create_window( tigerBitmap, sealieBitmap);
   assert( window);
   [application addWindow:window];
   [NSThread detachNewThreadSelector:@selector( runInApplication:)
                            toTarget:window
                          withObject:application];

   [application run];
}

