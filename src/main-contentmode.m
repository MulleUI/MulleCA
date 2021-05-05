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


static UIImageView  *_imageView[ 3][ 2];


static UIEvent   *buttonClicked( id <UIControl> control, UIEvent *event)
{
   UIViewContentMode   contentMode;
   char                *title;
   NSUInteger          i;
   NSUInteger          j;

   fprintf( stderr, "**** %s ****\n", __PRETTY_FUNCTION__);

   title       = [[(MullePopUpButton *) control clickedButton] titleCString];
   contentMode = UIViewContentModeParseCString( title);
   for( i = 0; i < 3; i++)
      for( j = 0; j < 2; j++)
         [_imageView[ i][ j] setContentMode:contentMode];
   return( nil);
}

#define IMAGE_PORTRAIT
//#define VIEW_PORTRAIT


void   setupSceneInContentPlane( MulleWindowPlane *plane)
{
   CGRect             frame;
   CGRect             hframes[ 3];
   CGRect             frames[ 3][ 2];
   CGSize             imageSize;
   UIEdgeInsets       insets;
   MulleBitmapImage   *image[ 3];
   MullePopUpButton   *button;
   NSUInteger         i;
   NSUInteger         j;

   image[ 0] = [[[MulleBitmapImage alloc] initWithConstRGBA:turtle_bitmap
                                                 bitmapSize:turtle_bitmap_size]
                                                      autorelease];
   image[ 1] = [[[MulleBitmapImage alloc] initWithConstRGBA:sealie_bitmap
                                             bitmapSize:sealie_bitmap_size]
                                              autorelease];
   // 1280x878
   image[ 2] = [[[MulleBitmapImage alloc] initWithContentsOfFileWithFileRepresentationString:"/home/src/srcO/MulleUI/bengal.jpg"] autorelease];

   frame  = [plane frame];
   frame  = CGRectInset( frame, 20, 40);

   MulleRectPartitionHorizontally( frame, 3, hframes, 20);

   for( i = 0; i < 3; i++)
   {
      MulleRectPartitionVertically( hframes[ i], 2, frames[ i], 20);

      // now make odd frames portrait
      frames[ i][ 1].size.width = frames[ i][ 1].size.height - 40;
      frames[ i][ 1].origin.x   = frames[ i][ 1].origin.x  + (frames[ i][ 0].size.width - frames[ i][ 1].size.width) / 2.0;
   }

   for( i = 0; i < 3; i++)
      for( j = 0; j < 2; j++)
      {
         _imageView[ i][ j]  = [[[UIImageView alloc] initWithImage:image[ i]] autorelease];
         [_imageView[ i][ j] setBackgroundColor:CGColorCreateGenericRGB( 0.5, 0.5, 0.5, 1.0)];

         frame = CGRectInset( frames[ i][ j], 5, 5);
         [_imageView[ i][ j] setFrame:frame];
         [plane addSubview:_imageView[ i][ j]];
      }

   button = [MullePopUpButton viewWithFrame:CGRectMake( 0, 0, 120, 20)];
   [button setTitleCString:"ContentMode"];
   [button setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
   [button setAutoresizingMask:MulleUIViewAutoresizingStickToBottom|
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
      [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

      setupSceneInContentPlane( [window contentPlane]);

      [window dump];

      [window renderLoop];
      [[UIApplication sharedInstance] terminate];
   }
}
