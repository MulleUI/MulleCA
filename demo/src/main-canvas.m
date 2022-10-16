#import "import-private.h"


enum
{
   even,
   odd
};

static void   drawStuff( CALayer *layer, void *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;
   CGPoint             point;
   int                 oddEvenStart;
   int                 oddEvenLine;
   int                 oddEvenField;

   vg = CGContextGetNVGContext( (CGContext *) context);

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
   return( UIApplicationRunDrawCallbackHz( (CALayerDrawCallback_t *) drawStuff,
                                           CGSizeMake( 200, 200),
                                           NULL, 
                                           100.f));      
}
