#import <MulleCA/MulleCA.h>


@interface Foo : CAImplicitlyAnimatableObject

@property( observable, assign) NSInteger   value;

@end 

@implementation Foo 
@end 



int   main( int argc, char *argv[])
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;
   Foo                *foo;

   foo = [Foo object];
   [foo setValue:0];

   transaction = [CATransaction object];
   assert( transaction);

   [transaction begin];
   {
      // if duration is 0.0, then no animations are generated
      [transaction setAnimationDuration:1.0];
      [foo setValue:1848];
   }
   group = [transaction commit];
   printf( "%td\n", [group numberOfAnimations]);
   return( 0);
}
