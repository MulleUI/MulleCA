#import "import-private.h"

#import "MulleSVGImage.h"
#import "MulleSVGLayer.h"
#import "MulleBitmapImage.h"
#import "MulleImageLayer.h"
#import "CGContext.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIButton.h"
#import "UIImageView.h"
#import "UIColor.h"
#import "UIScrollView.h"
#import "UIEvent.h"
#import <string.h>


// #define MULTI_THREADED


// scale stuff for stream

static UIWindow  *create_window( MulleBitmapImage   *tigerBitmap,
                                 MulleBitmapImage   *sealieBitmap)
{
   MulleImageLayer    *imageLayer;
   CGRect             frame;
   CGRect             windowFrame;
   CGRect             bounds;
   UIWindow           *window;
   UIView             *view;
   UIView             *contentView;
   UIButton           *button;
   UIScrollView       *scroller;
   UIImageView        *imageView;

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
   window      = [UIWindow windowWithFrame:windowFrame];
   assert( window);

   [window setBackgroundColor:[UIColor yellowColor]];


   // BUTTON IN SCROLLVIEW


   imageLayer = [[[MulleImageLayer alloc] initWithImage:tigerBitmap] autorelease];
   imageView  = [[[UIImageView alloc] initWithLayer:imageLayer] autorelease];

   fprintf( stderr, "view: %p f=[%s] c=[%s]\n", 
                        imageView, 
                        CGRectCStringDescription( [imageView frame]),
                        CGRectCStringDescription( [imageView contentRect]));

   fprintf( stderr, "layer: %p f=[%s] c=[%s]\n", 
                        imageLayer, 
                        CGRectCStringDescription( [imageLayer frame]),
                        CGRectCStringDescription( [imageLayer canvas]));

   // SCROLLVIEW
   frame    = CGRectMake( 20.0, 20.0, 640 - 40.0, 400.0 - 40.0);
   scroller = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
   [scroller setZoomEnabled:YES];
   [scroller setContentSize:[imageView frame].size];
   [[scroller contentView] addSubview:imageView];
   [[window contentPlane] addSubview:scroller];

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
#ifdef MULTI_THREADED   
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
#else
   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
#endif   
   return( 0);
}

