#import <MulleCA/MulleCA.h>


int   main( int argc, char *argv[])
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   transaction = [CATransaction object];
   assert( transaction);

   [transaction begin];
   {
   }
   group = [transaction commit];
   return( 0);
}
