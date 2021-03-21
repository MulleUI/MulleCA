#import "import-private.h"

#import "MulleBitmapImage.h"
#import "MulleLayout.h"
#import "MullePopUpButton.h"
#import "UIImageView.h"
#import "UIStackView.h"
#import "CGContext.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIColor.h"
#import <string.h>


#include "sealie-bitmap.inc"
#include "turtle-bitmap.inc"
#include "viech-bitmap.inc"


static UIImageView  *_imageView[ 4];


static UIEvent   *buttonClicked( id <UIControl> control, UIEvent *event)
{
   UIViewContentMode   contentMode;
   char                *title;
   NSUInteger          i;

   fprintf( stderr, "%s\n", __PRETTY_FUNCTION__);

   title       = [[(MullePopUpButton *) control clickedButton] titleCString];
   contentMode = UIViewContentModeParseCString( title);
   for( i = 0; i < 4; i++)
      [_imageView[ i] setContentMode:contentMode];
   return( nil);
}

#define IMAGE_PORTRAIT
//#define VIEW_PORTRAIT


void   setupScene( MulleWindowPlane *plane, CGContext *context)
{
   CGRect             frame;
   CGRect             frames[ 4];
   CGSize             imageSize;
   UIEdgeInsets       insets;
   MulleBitmapImage   *image[ 2];
   MullePopUpButton   *button;
   NSUInteger         i;

   frame  = [plane frame];
   frame  = CGRectInset( frame, 80, 80);

   MulleRectPartititonVertically( frame, 2, frames, 0);
   MulleRectPartititonHorizontally( frames[ 1], 2, &frames[ 2], 0);
   MulleRectPartititonHorizontally( frames[ 0], 2, &frames[ 0], 0);

   // now make frames 1 and 3 portrait

   frames[ 1].size.width = frames[ 1].size.height - 20;
   frames[ 3].size.width = frames[ 1].size.height - 20;

   image[ 0] = [[[MulleBitmapImage alloc] initWithConstRGBA:turtle_bitmap
                                                 bitmapSize:turtle_bitmap_size]
                                                      autorelease];
   image[ 1] = [[[MulleBitmapImage alloc] initWithConstRGBA:sealie_bitmap
                                             bitmapSize:sealie_bitmap_size]
                                              autorelease];

   for( i = 0; i < 4; i++)
   {
      frame  = CGRectInset( frames[ i], 5, 5);
      _imageView[ i]  = [[[UIImageView alloc] initWithImage:image[ i / 2]] autorelease];
      [_imageView[ i] setBackgroundColor:CGColorCreateGenericRGB( 0.5, 0.5, 0.5, 1.0)];
      [_imageView[ i] setFrame:frame];
      [plane addSubview:_imageView[ i]];
   }

   button = [MullePopUpButton mulleViewWithFrame:CGRectMake( 0, 0, 120, 20)];
   [button setTitleCString:"ContentMode"];
   [button setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
   [button setAutoresizingMask:MulleUIViewAutoresizingStickToBottom|\
                               MulleUIViewAutoresizingStickToLeft|
                               MulleUIViewAutoresizingStickToRight];
   [button setClick:buttonClicked];

   // not strdupped currently!
   [button setTitlesCStrings:UIViewContentModeNames
                       count:N_UIViewContentModeNames];

   [plane addSubview:button];

//   imageSize     = [image size];
//   frame.origin  = MulleSizeGetCenterInRect( imageSize, frame);
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
#ifdef VIEW_PORTRAIT
      window  = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 600.0, 800.0)] autorelease];
#else
      window  = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)] autorelease];
#endif
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
