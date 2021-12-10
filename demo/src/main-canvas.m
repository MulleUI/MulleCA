#import "import-private.h"


enum
{
   even,
   odd
};

static void   drawStuff1( CALayer *layer, CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;
   CGPoint             point;
   int                 oddEvenStart;
   int                 oddEvenLine;
   int                 oddEvenField;

   vg = CGContextGetNVGContext( context);

   canvas = [layer canvas];

   for( oddEvenStart = even; oddEvenStart <= odd; oddEvenStart++)
   {
      nvgBeginPath( vg);
      oddEvenLine = oddEvenStart;
      for( point.y = 0; point.y < canvas.size.height; point.y += 8)
      {
         oddEvenLine  = ! oddEvenLine;
         oddEvenField = odd;
         for( point.x = 0; point.x < canvas.size.width; point.x += 8)
         {
            oddEvenField = ! oddEvenField;
            if( oddEvenField != oddEvenLine)
               continue;
            nvgRect( vg, point.x, point.y, 8, 8);
         }
      }

      if( oddEvenStart == even)
         nvgFillColor( vg, nvgRGBAf( 0.25, 1.0, 0.25, 1.0));
      else
         nvgFillColor( vg, nvgRGBAf( 1.0, 0.5, 0.0, 1.0));
      nvgFill( vg);
   }
}


int   main( int argc, char *argv[])
{
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   @autoreleasepool
   {
      [app runWindowForDrawCallback:drawStuff1
                         canvasSize:CGSizeMake( 200, 200)
                         windowSize:CGSizeZero   // CGSizeMake( 200, 400)
                    titleUTF8String:NULL
                        frameRateHz:100.0];
   }
   [app terminate];
}
