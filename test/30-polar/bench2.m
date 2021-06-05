#include <MulleCA/_MulleCA-include.h>
#include <MulleCA/_MulleCA-provide.h>

#include <stdio.h>


int   main( int argc, char *argv[])
{
   CGPoint        a, b;
   CAPolarPoint   p;
   CGPoint        r1, r2, r3;
   int            x1, y1;
   int            x2, y2;
   CGFloat        total;

   total = 0.0;
   for( x1 = -100; x1 <= 100; x1 += 5)
      for( x2 = -100; x2 <= 100; x2 += 5)
         for( y1 = -100; y1 <= 100; y1 += 5)
            for( y2 = -100; y2 <= 100; y2 += 5)
            {
               a = CGPointMake( x1, y1);
               b = CGPointMake( x2, y2);
               r1 = CGPointAdd( a, b);
   
               // the non-converting method seems faster
               p = CAPolarPointAdd2( CGPointAsPolarPoint( a), CGPointAsPolarPoint( b));
               r2 = CAPolarPointAsPoint( p);

               total += r2.x + r2.y;
            }

   return( total == 18.48);  // it's not
}