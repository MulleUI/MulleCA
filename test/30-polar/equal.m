#include <MulleCA/_MulleCA-include.h>
#include <MulleCA/_MulleCA-provide.h>

#include <stdio.h>




int   main( int argc, char *argv[])
{
   CAPolarPoint   a, b;

   a = CAPolarPointMake( -10, CAAngleDegreesToRadians( 45.0));
   b = CAPolarPointMake( +10, CAAngleDegreesToRadians( 45.0 + 180.0));

   printf( "%s\n", CAPolarPointEqualToPolarPoint( a, b) ? "YES" : "NO");
   printf( "%s\n", CAPolarPointEqualToPolarPoint2( a, b) ? "YES" : "NO");

   return( 0);
}
