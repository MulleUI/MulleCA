#import "import-private.h"

#import "CALayer.h"
#import "CAAnimation.h"
#import "CGGeometry.h"
#import "CGGeometry+CString.h"
#import "UIEdgeInsets.h"
#import "MulleTextLayer.h"
#import "MulleLayout.h"
#import <string.h>


int   main()
{
   CALayer                 *background;
   CGContext               *context;
   CGRect                  frame;
   CGRect                  rect;
   CGRect                  fitRect;
   GLFWwindow              *window;
   MulleTextLayer          *someText;
   MulleTextLayer          *title;
   struct MulleFrameInfo   info;

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

   background = [CALayer layerWithFrame:rect];
   [background setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];

   rect = UIEdgeInsetsInsetRect( rect, UIEdgeInsetsMake( 14, 4, 4, 4));
   someText = [MulleTextLayer layerWithFrame:rect];
   [someText setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];
   [someText setCString:"Some text"];
   [someText setInsets:UIEdgeInsetsMake( 12, 8, 6, 8)];
   [someText setBorderWidth:1.5];
   [someText setCornerRadius:3.5];
   [someText setBorderColor:MulleColorMake( 0x000000FF)];

   rect      = UIEdgeInsetsInsetRect( rect, UIEdgeInsetsMake( -10, 10, 0, 0));
   rect.size = CGSizeMake( 60, 20);

   title = [MulleTextLayer layerWithFrame:rect];
   [title setBackgroundColor:MulleColorMake( 0xFFFFFFFF)];
//   [title setBackgroundColor:MulleColorMake( 0x00)];
   [title setCString:"title"];
   [title setInsets:UIEdgeInsetsMake( 2, 4, 1, 4)];
   [title setAlignmentMode:CAAlignmentCenter];

   // find required width
   fitRect.size = [title sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                              context:context];
   // keep height stable if there were changes, there shouldnt't be
   fitRect.size   = CGSizeMake( fitRect.size.width, rect.size.height);

   // figure out new origin
   fitRect.origin = MulleOriginOfSizeCenteredInRect( fitRect.size, rect);
   [title setFrame:fitRect];

   /* Loop until the user closes the window */
   while( ! glfwWindowShouldClose(window))
   {
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

