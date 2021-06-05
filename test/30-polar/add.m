#include <MulleCA/_MulleCA-include.h>
#include <MulleCA/_MulleCA-provide.h>

#include <stdio.h>



// step 5 produces 200MB output!

#define STEP   50

int   main( int argc, char *argv[])
{
   CGPoint        a, b;
   CAPolarPoint   p;
   CGPoint        r1, r2, r3;
   int            x1, y1;
   int            x2, y2;

   for( x1 = -100; x1 <= 100; x1 += STEP)
      for( x2 = -100; x2 <= 100; x2 += STEP)
         for( y1 = -100; y1 <= 100; y1 += STEP)
            for( y2 = -100; y2 <= 100; y2 += STEP)
            {
               a = CGPointMake( x1, y1);
               b = CGPointMake( x2, y2);
               r1 = CGPointAdd( a, b);
               printf( "[%.1f %.1f] + [%.1f %.1f] = [%.1f %.1f]",
                        a.x, a.y,
                        b.x, b.y,
                        r1.x, r1.y);

               p = CAPolarPointAdd1( CGPointAsPolarPoint( a), CGPointAsPolarPoint( b));
               r2 = CAPolarPointAsPoint( p);
               printf( ", [%.1f %.1f]", r2.x, r2.y);

               p = CAPolarPointAdd2( CGPointAsPolarPoint( a), CGPointAsPolarPoint( b));
               r3 = CAPolarPointAsPoint( p);
               printf( ", [%.1f %.1f]", r3.x, r3.y);

               if( roundf( r1.x) != roundf(r2.x))
                  printf( "!");
               if( roundf(r1.y) != roundf(r2.y))
                  printf( "!");
               if( roundf(r2.x) != roundf(r3.x))
                  printf( "!");
               if( roundf(r2.y) != roundf(r3.y))
                  printf( "!");
               if( roundf(r1.x) != roundf(r3.x))
                  printf( "!");
               if( roundf(r1.y) != roundf(r3.y))
                  printf( "!");
               printf( "\n");
            }

   return( 0);
}