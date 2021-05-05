#import "import-private.h"

#import "UIEvent.h"
#import "UIWindow.h"
#import "UIWindow+UIEvent.h"
#import "UIApplication.h"
#import "CALayer.h"
#import "CGContext.h"

#include <stdlib.h>
#include <unistd.h>


@implementation UIApplication( Thread)

- (BOOL) renderWindow:(UIWindow *) window
{
   if( [window renderFrameWaitForNeedsDisplay])
   {
      [window mullePerformFinalize];
      return( NO);
   }
   return( YES);
}


- (void) doWindowsThread:(id) window
{
   [window setThread:[NSThread currentThread]];
   while( [self renderWindow:window])
   {
      [window pollEvents];
   }
}

@end



// Topics:
//  * create a window
//  * place view inside window
//  * add drawing C code to the views layer to produce the graphics
//  * run renderloop (with event handling)
//
void   _drawStuff( NVGcontext *vg,
                   CGRect rect,
                   int antialias)
{
   nvgShapeAntiAlias( vg, antialias);
   nvgStrokeWidth( vg, 10.0);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x8080007F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x0080807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50,
                       rect.origin.y + 50,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x8000807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y + 50,
                       rect.size.width,
                       rect.size.height,
                       20);
   nvgStrokeColor(vg, MulleColorMake( 0x8080807F));
   nvgStroke( vg);

   nvgShapeAntiAlias( vg, 1);
}


static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGRect                     rect;
   struct NVGcontext          *vg;
   CGFloat                    wh;
   CGRect                     canvas;
   struct MulleFrameInfo      *info;

   vg   = MulleContextGetNVGContext( context);

   info = [context currentFrameInfo];
   wh   = (info->renderFrame % 100) + 10.0;

   canvas = [layer canvas];
   rect   = CGRectMake( 100.5, 100, wh, wh);

   // ??
   rect.origin.x += canvas.origin.x;
   rect.origin.y += canvas.origin.y;

   _drawStuff( vg, rect, 1);
}


void   setupScene( UIWindow *window)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame        = [window frame];
   frame.origin = CGPointZero;

   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   layer = [view layer];
   [layer setDrawCallback:drawStuff];
   [window addSubview:view];
}


int   main()
{
   UIApplication     *application;
   UIWindow          *windows[ 2];
   int               i;

   /*
    * window and app
    */
   // mulle_testallocator_initialize();
   // mulle_default_allocator = mulle_testallocator;

   @autoreleasepool
   {
      for( i = 0; i < 2; i++)
      {
         windows[ i] = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 400.0, 300.0)
                                        titleCString:"Demo"
                                           styleMask:0] autorelease];

         [[UIApplication sharedInstance] addWindow:windows[ i]];

         [windows[ i] setBackgroundColor:CGColorCreateGenericRGB( 0.0, 0.0, (i + 1) * 1.0 / 2, 1.0)];

         setupScene( windows[ i]);

         [NSThread detachNewThreadSelector:@selector( doWindowsThread:)
                                  toTarget:[UIApplication sharedInstance]
                                withObject:windows[ i]];
      }
      for(;;)
      {
   	   [UIEvent os_pollEvents];
      }
   }
   sleep( 4);
}