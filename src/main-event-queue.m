#import "import-private.h"

#import "UIWindow.h"
#import "UIApplication.h"
#import "CALayer.h"
#import "CGContext.h"

#include <stdlib.h>


@implementation UIApplication( Thread)

- (BOOL) renderWindow:(UIWindow *) window
              context:(CGContext *) context
{
   // this will wait for NeedsDisplay
   if( [window renderFrameWaitForNeedsDisplayWithContext:context])
   {
      [window mullePerformFinalize];
      return( NO);
   }
   return( YES);
}


- (void) doWindowsThread:(id) argument
{
   UIWindow        *window;
   CGContext       *context;
   BOOL            flag;

   window  = [argument :@"window"];   
   context = [argument :@"context"];   

   do
   {
      flag = [self renderWindow:window
                        context:context];
   }
   while( flag);
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
   nvgStrokeColor(vg, MulleColorCreate( 0x8080007F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50, 
                       rect.origin.y, 
                       rect.size.width, 
                       rect.size.height, 
                       20);
   nvgStrokeColor(vg, MulleColorCreate( 0x0080807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x + 50, 
                       rect.origin.y + 50, 
                       rect.size.width, 
                       rect.size.height, 
                       20);
   nvgStrokeColor(vg, MulleColorCreate( 0x8000807F));
   nvgStroke( vg);

   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x, 
                       rect.origin.y + 50, 
                       rect.size.width, 
                       rect.size.height, 
                       20);
   nvgStrokeColor(vg, MulleColorCreate( 0x8080807F));
   nvgStroke( vg);

   nvgShapeAntiAlias( vg, 1);  
}                 


BOOL  drawStuff( CALayer *layer, 
                 CGContext *context, 
                 CGRect frame, 
                 struct MulleFrameInfo *info)
{
   CGRect              rect;
   struct NVGcontext   *vg;
   CGFloat             wh;


   vg = MulleContextGetNVGContext( context);

   wh = (info->renderFrame % 100) + 10.0;

   rect = CGRectMake( 100.5, 100, wh, wh);
   rect.origin.x += frame.origin.x;
   rect.origin.y += frame.origin.y;

   _drawStuff( vg, rect, 1);
   return( NO);
}


void   setupScene( UIWindow *window, CGContext *context)
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
   [layer setDrawContentsCallback:drawStuff];
   [window addSubview:view];
}


int   main()
{
   UIApplication     *application;
   UIWindow          *windows[ 2];
   CGContext         *contexts[ 2];
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

         contexts[ i] = [windows[ i] createContext];
         [contexts[ i] setBackgroundColor:CGColorCreateGenericRGB( 0.0, 0.0, (i + 1) * 1.0 / 2, 1.0)];

         setupScene( windows[ i], contexts[ i]);

         [NSThread detachNewThreadSelector:@selector( doWindowsThread:)
                                  toTarget:[UIApplication sharedInstance]
                                withObject:@{ 
                                              @"window":  windows[ i],
                                              @"context": contexts[ i],
                                            }];
      }
      for(;;)
      {
   	   glfwPollEvents();
      }
   }
   sleep( 4);
}