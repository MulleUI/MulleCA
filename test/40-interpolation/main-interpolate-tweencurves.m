#import <MulleCA/MulleCA.h>

#include <math.h>
#include <stdio.h>


int   main( int argc, char *argv[])
{
   static CAAnimationCurve   curves[] =
   {
      CAAnimationCurveEaseInOut,
      CAAnimationCurveEaseIn,
      CAAnimationCurveEaseOut,
      CAAnimationCurveLinear,
      CAAnimationCurveEaseInQuadratic,
      CAAnimationCurveEaseOutQuadratic,
      CAAnimationCurveEaseInOutQuadratic,
      CAAnimationCurveEaseInCubic,
      CAAnimationCurveEaseOutCubic,
      CAAnimationCurveEaseInOutCubic,
      CAAnimationCurveEaseInQuartic,
      CAAnimationCurveEaseOutQuartic,
      CAAnimationCurveEaseInOutQuartic,
      CAAnimationCurveEaseInQuintic,
      CAAnimationCurveEaseOutQuintic,
      CAAnimationCurveEaseInOutQuintic,
      CAAnimationCurveEaseInSine,
      CAAnimationCurveEaseOutSine,
      CAAnimationCurveEaseInOutSine,
      CAAnimationCurveEaseInExponential,
      CAAnimationCurveEaseOutExponential,
      CAAnimationCurveEaseInOutExponential,
      CAAnimationCurveEaseInCircular,
      CAAnimationCurveEaseOutCircular,
      CAAnimationCurveEaseInOutCircular,
      CAAnimationCurveEaseInBack,
      CAAnimationCurveEaseOutBack,
      CAAnimationCurveEaseInOutBack,
      CAAnimationCurveEaseInBounce,
      CAAnimationCurveEaseOutBounce,
      CAAnimationCurveEaseInOutBounce,
      CAAnimationCurveEaseInElastic,
      CAAnimationCurveEaseOutElastic,
      CAAnimationCurveEaseInOutElastic
   };
   CATweenFunction          *tween;
   CACubic                  cubic;
   CGFloat                  t0;
   CGFloat                  t1;
   NSUInteger               i;
   NSUInteger               n;

   MULLE_C_UNUSED( argc);
   MULLE_C_UNUSED( argv);

   n = sizeof( curves) / sizeof( curves[ 0]);
   for( i = 0; i < n; i++)
   {
      cubic = CACubicForAnimationCurve( curves[ i]);
      tween = CATweenForAnimationCurve( curves[ i]);
      if( ! tween)
         tween = CACubicGetValue;

      t0 = (*tween)( &cubic, 0.0);
      t1 = (*tween)( &cubic, 1.0);

      if( fabs( t0) > 0.0001 || fabs( t1 - 1.0) > 0.0001)
      {
         printf( "FAIL %s: %.6f %.6f\n",
                 CAAnimationCurveUTF8String( curves[ i]),
                 t0,
                 t1);
         return( 1);
      }
   }

   printf( "%td curves endpoint-ok\n", (intptr_t) n);
   return( 0);
}
