#import "import-private.h"

#import "MullePopUpButton.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIColor.h"
#include <string.h>
#include <stdio.h>


static UIEvent   *buttonClicked( id <UIControl> control, UIEvent *event)
{
   fprintf( stderr, "%s\n", __PRETTY_FUNCTION__);

   return( nil);
}

// TODO: test with 100 entries so that the scrollview has something
//       to do
//       animation now working for menu items
//
static char *titles[] =
{
   "XXXX <<<< 1111 XXXX >>>> XXXX",
   "XXXX <<<< XXXX 2222",
   "XXXX <<<< XXXX XXXX >>>> 3333",
   "4444 <<<< XXXX XXXX >>>> XXXX",
   "XXXX <<<< 5555 |||| XXXX >>>> XXXX",
   "XXXX <<<< XXXX 6666 >>>> XXXX"
};


void   setupSceneInContentPlane( MulleWindowPlane *plane)
{
   MullePopUpButton   *button;

   button = [MullePopUpButton viewWithFrame:CGRectMake( 0, 0, 120, 20)];
   [button setTitleCString:"PopUpButton"];
   [button setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
   [button setAutoresizingMask:MulleUIViewAutoresizingStickToTop|
                               MulleUIViewAutoresizingStickToLeft|
                               MulleUIViewAutoresizingStickToRight];
   [button setClick:buttonClicked];

   [button setTitlesCStrings:titles
                       count:sizeof( titles) / sizeof( char *)];

   [plane addSubview:button];
}


int   main( int argc, char *argv[])
{
   UIWindow   *window;

   /*
    * window and app
    */
   window = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)] autorelease];
   [[UIApplication sharedInstance] addWindow:window];
   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentPlane( [window contentPlane]);

   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
}
