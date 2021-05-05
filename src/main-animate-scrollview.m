#import "import-private.h"

#import "MulleBitmapImage.h"
#import "MulleImageLayer.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIImageView.h"
#import "UIColor.h"
#import "UIScrollView.h"
#import "UIView+CAAnimation.h"
#import "UIView+Layout.h"
#import <string.h>

// #define HAVE_SCROLLER_SCENE
#define HAVE_STATIC_SCENE
//#define REVERSE_DIRECTION

#ifdef HAVE_SCROLLER_SCENE
static void   setup_scroller_scene( CGRect rect, MulleBitmapImage *tigerBitmap, UIView *contentPlane)
{
   UIImageView    *imageView;
   CGRect         startFrame;
   CGRect         endFrame;
   CGRect         frame;
   CGRect         bounds;
   UIScrollView   *scroller;

   imageView = [[[UIImageView alloc] initWithImage:tigerBitmap] autorelease];
   frame.origin       = CGPointMake( 0.0, 0.0);
   frame.size.width   = rect.size.width;
   frame.size.height  = rect.size.height;
   [imageView setFrame:frame];
   [imageView setContentMode:UIViewContentModeTopLeft];

   // SCROLLVIEW
   bounds                 = frame;
   startFrame             = rect;
   endFrame               = startFrame;
#ifdef REVERSE_DIRECTION
   endFrame.size.height   = 20.0;
#else
   startFrame.size.height = 20.0;
#endif

   scroller = [[[UIScrollView alloc] initWithFrame:startFrame] autorelease];
   [scroller setContentSize:bounds.size];
   [scroller setBorderWidth:2.0];
   [scroller setBorderColor:MulleColorMake( 0x2040E0FF)];
   [[scroller contentView] addSubview:imageView];
   [scroller layout];

   [contentPlane addSubview:scroller];

   [UIView beginAnimations:"animation"
                    context:NULL];
      [UIView setAnimationDelay:0];
      [UIView setAnimationDuration:0.5];
      [UIView setAnimationRepeatAutoreverses:YES];
      [UIView setAnimationRepeatCount:20];

      [scroller setFrame:endFrame];
      [scroller layout];

   [UIView commitAnimations];
}
#endif

#ifdef HAVE_STATIC_SCENE
static void   setup_static_scene( CGRect rect, MulleBitmapImage *tigerBitmap, UIView *contentPlane)
{
   UIImageView    *imageView;
   CGRect         startFrame;
   CGRect         endFrame;
   CGRect         startBounds;
   CGRect         endBounds;
   CGRect         frame;
   CGRect         bounds;

   assert( contentPlane);
   
   imageView = [[[UIImageView alloc] initWithImage:tigerBitmap] autorelease];
   [imageView setContentMode:UIViewContentModeTopLeft];

   bounds      = [imageView bounds];

   startBounds = bounds;
   endBounds   = bounds;
   startFrame  = rect;
   endFrame    = rect;
#ifdef REVERSE_DIRECTION
   endFrame.size.height   = 20.0;
#else
   startFrame.size.height = 20.0;
   startBounds.origin.y  -= (bounds.size.height / rect.size.height) * (rect.size.height - 20);
#endif

   [imageView setFrame:startFrame];
   [imageView setBounds:startBounds];
   [contentPlane addSubview:imageView];
   [imageView layout];

#if 1
   [UIView beginAnimations:"animation2"
                    context:NULL];
      [UIView setAnimationDelay:0];
      [UIView setAnimationDuration:2.0];
      [UIView setAnimationRepeatAutoreverses:YES];
      [UIView setAnimationRepeatCount:20];
      [UIView setAnimationDelegate:[contentPlane window]];
      [UIView setAnimationWillStartSelector:@selector( dump)];
      [UIView setAnimationDidStopSelector:@selector( dump)];

      [imageView setBounds:endBounds];
      [imageView setFrame:endFrame];
      [imageView layout];

   [UIView commitAnimations];
#endif   
}
#endif

static void   setup_scene( MulleWindowPlane *contentPlane)
{
   MulleImageLayer    *buttonLayer;
   CGRect             frame;
   CGRect             endFrame;
   CGRect             startFrame;
   CGRect             windowFrame;
   CGRect             bounds;
   CGRect             rects[ 2];
   UIWindow           *window;
   UIImageView        *imageView;
   UIScrollView       *scroller;
   MulleBitmapImage   *tigerBitmap;

   // 1280x878
   tigerBitmap = [[[MulleBitmapImage alloc] initWithContentsOfFileWithFileRepresentationString:"/home/src/srcO/MulleUI/bengal.jpg"] autorelease];
   assert( tigerBitmap);

   // WINDOW

   bounds = [contentPlane bounds];
   bounds = CGRectInset( bounds, 10, 10);

   MulleRectPartitionHorizontally( bounds, 2, rects, 10);

#ifdef HAVE_SCROLLER_SCENE
  setup_scroller_scene( rects[ 0], tigerBitmap, contentPlane);
#endif  
#ifdef HAVE_STATIC_SCENE
   setup_static_scene( rects[ 1], tigerBitmap, contentPlane);
#endif   
}


int   main( int argc, char *argv[])
{
   UIWindow           *window;
   UIApplication      *application;

   // WINDOW
   window       = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 640, 400.0)] autorelease];
   [window setBackgroundColor:[UIColor yellowColor]];
   setup_scene( [window contentPlane]);

   // APPLICATION
   application = [UIApplication sharedInstance];
   [application addWindow:window];
   [window renderLoop];
   [application terminate];
}

