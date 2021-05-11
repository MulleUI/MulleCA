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
// same as coregraphics just animated a little
//
int   main()
{
   CALayer                 *background;
   CGContext               *context;
   CGRect                  frame;
   CGRect                  rect;
   CGRect                  fitRect;
   CGRect                  titleRect;
   CGRect                  someTextRect;
   CGRect                  backgroundRect;
   GLFWwindow              *window;
   MulleTextLayer          *someText;
   MulleTextLayer          *title;
   struct MulleFrameInfo   info;
   CAAbsoluteTime          now;
   CATransaction           *transaction;

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
   [title setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];
//   [title setBackgroundColor:MulleColorMake( 0x00)];
   [title setInsets:UIEdgeInsetsMake( 2, 4, 1, 4)];
   [title setAlignmentMode:CAAlignmentCenter];

   //
   // We use implicit animation, meaning we prime the layers
   // then we actually make some changes and then let the layers
   // build the animations themselves
   //
   transaction = [CATransaction object];
   [transaction setAnimationDuration:0.5];
   [transaction setAnimationDelay:1.0];
   [transaction setAnimationRepeatCount:INFINITY];

   // set up initial values
   [background setBackgroundColor:MulleColorMake( 0xAAAAAAFF)];
   [someText setOpacity:0.1];
   [title setOpacity:0.1];
   set_title( title, "", titleRect, context);
   [someText setTextRange:NSMakeRange( 0, 0)];

   [transaction begin];
   {
      [background setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];
      [someText setOpacity:1.0];
      [someText setTextRange:NSMakeRange( 0, 9)];
      [title setOpacity:1.0];
      set_title( title, "title", titleRect, context);
   }
   [transaction commit];  // now all layers have animations
   /* Loop until the user closes the window */
   while( ! glfwWindowShouldClose(window))
   {
      /* Animate here */

      now = CAAbsoluteTimeNow();

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

      [context clearFramebuffer];
      [context beginRenderWithFrameInfo:&info];
      {
         [background renderInContext:context];
         [someText renderInContext:context];
         [title renderInContext:context];
      }
      [context endRender];

      /* Swap front and back buffers */
      glfwSwapBuffers( window);

      /* Poll for and process events */
      glfwPollEvents();
   }

   // pedantic
   glfwMakeContextCurrent( NULL);
   glfwDestroyWindow( window);
   glfwTerminate();

   return( 0);
}

