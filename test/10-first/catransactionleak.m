#import <MulleCA/MulleCA.h>


int   main( int argc, char *argv[])
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   transaction = [CATransaction instance];
   assert( transaction);

   [transaction begin];
   {
   }
   group = [transaction commit];
   return( 0);
}
