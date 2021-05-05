#import "import-private.h"

#import "CGContext.h"
#import "MulleTextLayer.h"
#import "UIApplication.h"
#import "UIColor.h"
#import "UIEvent.h"
#import "UITextField.h"
#import "UIView+CAAnimation.h"
#import "UIWindow.h"
#import <string.h>


void setup_window( UIWindow *window)
{
   CGRect          frame;
   UITextField     *textField;
   UIView          *contentView;

   contentView = [window contentPlane];
   [contentView setBackgroundColor:[UIColor greenColor]];

   frame.size.width  = 400;
   frame.size.height = 80;
   frame.origin.x   = (400.0 - frame.size.width ) / 2.0;
   frame.origin.y   = 10;

   textField = [[[UITextField alloc] initWithFrame:frame] autorelease];
   [textField setCString:"TextFyeld"];
   // TODO: this is apparently ignored!!! why ?? (because the prototype
   //       was missing!)
   [textField setFontPixelSize:60.0];
   [textField setCursorPosition:MulleIntegerPointMake( 2, 0)];
   [textField setAlignmentMode:CAAlignmentRight];
   [textField mulleSetVerticalAlignmentMode:MulleTextVerticalAlignmentBottom];
   [textField setEditable:YES];
#if 0
   [textField setTextOffset:CGPointMake( 80.0, 0.0)];
#endif
   // [insideButton setClipsToBounds:YES];
   [contentView addSubview:textField];
}

#define N_WINDOWS 20


static void  handle_events( int i, UIWindow *windows[])
{
   int   j;

   for( j = i; j >= 0; --j)
   {
      if( [windows[ j] needsDisplay])
      {
         fprintf( stderr, "Refresh Window #%d %p\n", j + 1, windows[ j]);
         [windows[ j] renderFrameWaitForNeedsDisplay];
      }
   }
}


int   main()
{
   UIApplication   *application;
   char            buf[ 64];
   int             i;
   int             j;
   UIWindow        *windows[ N_WINDOWS];
   CAAbsoluteTime  end;
   CGFloat         blue;

   /*
    * window and app
    */
   // mulle_testallocator_initialize();
   // mulle_default_allocator = mulle_testallocator;

   @autoreleasepool
   {
      for( i = 0; i < N_WINDOWS; i++)
      {
          /*
          * window and app
          */
         sprintf( buf, "Demo %d", i + 1);
         windows[ i] = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 400.0, 300.0)
                                        titleCString:buf
                                           styleMask:0] autorelease];
         assert( windows[ i]);
         fprintf( stderr, "Created Window #%d %p\n", i + 1, windows[ i]);

        // setup_window( windows[ i]);

         [[UIApplication sharedInstance] addWindow:windows[ i]];

         blue = ((N_WINDOWS - (i + 1)) * 1.0 / N_WINDOWS) * 0.75 + 0.25;
         [windows[ i] setBackgroundColor:CGColorCreateGenericRGB( 0.0,
                                                                  0.0,
                                                                  blue,
                                                                  1.0)];

         [UIEvent os_pollEvents];
         handle_events( i, windows);
      // [[UIApplication sharedInstance] terminate];
      }

      end = CAAbsoluteTimeNow() + 2.0;
      for(;;)
      {
         [UIEvent os_waitEventsTimeout:2.0];
         handle_events( N_WINDOWS - 1, windows);
         if( CAAbsoluteTimeNow() >= end)
            break;
      }
   }

   //   mulle_testallocator_reset();
}

