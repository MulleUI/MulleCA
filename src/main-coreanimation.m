#import "import-private.h"

#import "CALayer.h"
#import "CALayer+CAAnimation.h"
#import "CAAnimation.h"
#import "CATransaction.h"
#import "CGGeometry.h"
#import "CGColor.h"
#import "CGGeometry+CString.h"
#import "UIEdgeInsets.h"
#import "MulleTextLayer.h"
#import "MulleLayout.h"
#import <string.h>


@implementation CALayer( Debug)

- (void) setOpacity:(CGFloat) opacity
{
   fprintf( stderr, "%.3f: opacity = %.2f\n", CAAbsoluteTimeNow(), opacity);
   _opacity = opacity;
}

@end

static void   set_title( MulleTextLayer *title, char *s, CGRect rect, CGContext *context)
{
   CGRect  fitRect;

   [title setCString:s];
   // find required width
   fitRect.size = [title sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                              context:context];
   // keep height stable if there were changes, there shouldnt't be
   fitRect.size   = CGSizeMake( fitRect.size.width, rect.size.height);

   // figure out new origin
   fitRect.origin = MulleOriginOfSizeCenteredInRect( fitRect.size, rect);
   [title setFrame:fitRect];
}

//
// same as coregraphics just animated a very little
// The beginning is a little glitchy, why ?
//
int   main()
{
   CALayer                       *background;
   CGContext                     *context;
   CGRect                        frame;
   CGRect                        rect;
   CGRect                        fitRect;
   CGRect                        titleRect;
   CGRect                        someTextRect;
   CGRect                        backgroundRect;
   GLFWwindow                    *window;
   MulleTextLayer                *someText;
   MulleTextLayer                *title;
   struct MulleFrameInfo         info;
   CAAbsoluteTime                now;
   CAAnimation                   *animation;
   CAAnimation                   *animation2;
   struct CAAnimationOptions     options;

   // We don't have UIWindow here, we just do CGStuff so the windows has
   // to be done with glfw. We only do one of these tests, because they
   // are cumbersome to setup

   /* UIApplication */
   if( ! glfwInit())
      return -1;

#if MULLE_UI_GLVERSION == MULLE_GLES2
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 2);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
#endif
#if MULLE_UI_GLVERSION == MULLE_GLES3
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 2);
   glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif
#if MULLE_UI_GLVERSION == MULLE_GL
   glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 0);
   glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#endif

   /* UIWindow */
   frame  = CGRectMake( 0, 0, 640, 400); // need frame later
   window = glfwCreateWindow( frame.size.width, frame.size.height, "Demo", 0, 0);
   if( ! window)
   {
      fprintf( stderr, "glfwCreateWindow failed us\n");
      return( 1);
   }

   glfwMakeContextCurrent( window);
   context = [[CGContext new] autorelease];
   [context setBackgroundColor:MulleColorMake( 0x00FF00FF)];

   glfwSwapInterval( 0);  // need for smooth pointer/control sync

   /* Setup stuff to draw. We want this:
    *
    *  .- title ------.
    *  | Some text    |
    *  '--------------'
    *
    * We use three layers and stack em:
    *
    *    background
    *
    *    title
    *
    *  .--------------.
    *  | Some text    |
    *  '--------------'
    */
   rect = CGRectMake( 100, 100, 160, 60);

   backgroundRect = rect;
   background = [CALayer layerWithFrame:backgroundRect];
   [background setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];

   rect         = UIEdgeInsetsInsetRect( rect, UIEdgeInsetsMake( 14, 4, 4, 4));
   someTextRect = rect;

   someText = [MulleTextLayer layerWithFrame:someTextRect];
   [someText setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];
   [someText setCString:"Some text"];
   [someText setInsets:UIEdgeInsetsMake( 12, 8, 6, 8)];
   [someText setBorderWidth:1.5];
   [someText setCornerRadius:3.5];
   [someText setBorderColor:MulleColorMake( 0x000000FF)];

   rect      = UIEdgeInsetsInsetRect( rect, UIEdgeInsetsMake( -10, 10, 0, 0));
   rect.size = CGSizeMake( 60, 20);

   titleRect = rect;
   title     = [MulleTextLayer layerWithFrame:titleRect];
   [title setCString:"title"];
   [title setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];
//   [title setBackgroundColor:MulleColorMake( 0x00)];
   [title setInsets:UIEdgeInsetsMake( 2, 4, 1, 4)];
   [title setAlignmentMode:CAAlignmentCenter];

   /*
    * Do animation construction by hand. It's a bit clumsier than implicit
    * animation using CATransaction. Therefore we just don't do a lot here.
    */
   [someText setOpacity:0.0];
   [background setOpacity:0.0];
   [title setOpacity:0.0];

   memset( &options, 0, sizeof( options));

   options.timeRange   = CARelativeTimeRangeMake( 2, 0.666);
   options.repeatCount = INFINITY;
   options.bits        = CAAnimationReverses;
   options.curve       = MulleQuadraticForAnimationCurve( CAAnimationCurveEaseInOut);

   animation = [[[CAAnimation alloc] initWithPropertySetter:@selector( setOpacity:)
                                            startFloatValue:0.1
                                              endFloatValue:1.0
                                                    options:&options] autorelease];
   [someText addAnimation:[[animation copy] autorelease]];
   [background addAnimation:[[animation copy] autorelease]];
   [title addAnimation:animation];

   /* Loop until the user closes the window */
   while( ! glfwWindowShouldClose(window))
   {
      /* Animate here */

      now = CAAbsoluteTimeNow();

      fprintf( stderr, "%.3f: animate\n", now);

      [someText animateWithAbsoluteTime:now];
      [background animateWithAbsoluteTime:now];
      [title animateWithAbsoluteTime:now];

      /* Render here */

      memset( &info, 0, sizeof( info));

      /*
       * One would update the information here, if the
       * monitor resolution  or window size changes
       */
      info.size                   = frame.size;
      info.viewportFrame.size     = frame.size;
      info.framebufferSize        = frame.size;
      info.UIScale                = CGVectorMake( 1, 1);
      info.pixelRatio             = 1.0;

      fprintf( stderr, "%.3f: render\n", CAAbsoluteTimeNow());

      [context clearFramebuffer];
      [context beginRenderWithFrameInfo:&info];
      {
         [background renderInContext:context];
         [someText renderInContext:context];
         [title renderInContext:context];
      }
      [context endRender];

      /* Swap front and back buffers */
      fprintf( stderr, "%.3f: swap\n", CAAbsoluteTimeNow());
      glfwSwapBuffers( window);

      /* Poll for and process events */
      fprintf( stderr, "%.3f: poll\n", CAAbsoluteTimeNow());
      glfwPollEvents();
   }

   // pedantic
   glfwMakeContextCurrent( NULL);
   glfwDestroyWindow( window);
   glfwTerminate();

   return( 0);
}

