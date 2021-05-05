#import "import-private.h"

#import "MulleSVGImage.h"
#import "MulleSVGLayer.h"
#import "CGContext.h"
#import "UIWindow.h"
#import "UIApplication.h"
#import "UIEvent.h"
#import "UIView+Yoga.h"
#import <string.h>


// TODO: remove yoga


// Topics:
//
//  * render SVG code in a view
//

#include "Ghostscript_Tiger-svg.inc"



static void   setupSceneInContentPlane( MulleWindowPlane *contentPlane)
{
   MulleSVGImage  *tigerSVGImage;
   MulleSVGLayer  *tigerLayer;
   CGRect         frame;
   UIView         *view;
   YGLayout       *yoga;

   tigerSVGImage = [[[MulleSVGImage alloc] initWithConstantBytes:svginput
                                                          length:strlen( svginput) + 1] autorelease];
   fprintf( stderr, "tigerSVGImage: %p\n", tigerSVGImage);

   tigerLayer = [[[MulleSVGLayer alloc] initWithSVGImage:tigerSVGImage] autorelease];
   [tigerLayer setDebugNameCString:"tiger"];
   fprintf( stderr, "layer: %p\n", tigerLayer);

   [tigerLayer setFrame:CGRectZero];
 //  [layer setBounds:CGRectMake( 0.0, 0.0, 200, 30)];
   [tigerLayer setBackgroundColor:getNVGColor( 0xFFE0D0D0)];
   [tigerLayer setBorderColor:getNVGColor( 0xFF30FF80)];
   [tigerLayer setBorderWidth:32.0f];
   [tigerLayer setCornerRadius:16.0f];

   view = [[[UIView alloc] initWithLayer:tigerLayer] autorelease];
   [view setAutoresizingMask:MulleUIViewAutoresizingFlexible];
   [contentPlane addSubview:view];
}


int  main( int argc, char *argv[])
{
   UIWindow   *window;

   window  = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 640.0, 400.0)];
   assert( window);

   [[UIApplication sharedInstance] addWindow:window];

   setupSceneInContentPlane( [window contentPlane]);

   [window dump];
   [window renderLoop];

   [[UIApplication sharedInstance] terminate];
   return( 0);
}

