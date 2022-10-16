#import "import-private.h"


static void   drawStuff1( CALayer *layer, CGContext *context);
static void   drawStuff2( CALayer *layer, CGContext *context);


static void    flipDraw( CALayer *layer, CGContext *context)
{
   NSUInteger              frames;
   CALayerDrawCallback_t   *callback;

   frames = [context numberOfFrames];
   if( (frames % (100 * 3)) == 299)
   {
      callback = ([layer drawCallback] == drawStuff1) ? drawStuff2 : drawStuff1;
      [layer setDrawCallback:callback];
   }
}


static void   drawStuff1( CALayer *layer, CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;

   vg = CGContextGetNVGContext( context);

   canvas               = [layer canvas];
   canvas.size.height  /= 3.0;

   // red stripe
   nvgBeginPath( vg);
   nvgRect( vg, canvas.origin.x,
                canvas.origin.y,
                canvas.size.width,
                canvas.size.height);
   nvgFillColor( vg, nvgRGBAf( 0.0, 0.95, 0.0, 1.0));
   nvgFill( vg);

   // white stripe
   nvgBeginPath( vg);
   nvgRect( vg, canvas.origin.x,
                canvas.origin.y + canvas.size.height * 1,
                canvas.size.width,
                canvas.size.height);
   nvgFillColor( vg, nvgRGBAf( 0.0, 0.66, 0.0, 1.0));
   nvgFill( vg);

   // blue stripe
   nvgBeginPath( vg);
   nvgRect( vg, canvas.origin.x,
                canvas.origin.y + canvas.size.height * 2,
                canvas.size.width,
                canvas.size.height);
   nvgFillColor( vg, nvgRGBAf( 0.0, 0.3, 0.0, 1.0));
   nvgFill( vg);

   flipDraw( layer, context);
}


static void   drawStuff2( CALayer *layer, CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;
   NSUInteger          i;

   vg = CGContextGetNVGContext( context);

   canvas               = [layer canvas];
   canvas.size.height  /= 5.0;

   for( i = 0; i < 5; i++)
   {
      nvgBeginPath( vg);
      nvgRect( vg, canvas.origin.x,
                   canvas.origin.y + canvas.size.height * i,
                   canvas.size.width,
                   canvas.size.height);
      nvgFillColor( vg, nvgRGBAf( 0.0, 1.0 - i / 5.0, 0.0, 1.0));
      nvgFill( vg);
   }

   flipDraw( layer, context);
}


int   main( int argc, char *argv[])
{
   return( UIApplicationRunDrawCallbackHz( (CALayerDrawCallback_t *) drawStuff,
                                           CGSizeMake( 200, 200),
                                           NULL, 
                                           100.f));     
}
