#import <MulleCA/MulleCA.h>


@interface Foo : NSObject <CAImplicitlyAnimatableObject, CAAnimationDelegate>
{
   CAImplicitlyAnimatableObjectIvars;
}
@property( observable, assign) NSInteger    value;

CAImplicitlyAnimatableObjectInterface;

@end


@implementation Foo

CAImplicitlyAnimatableObjectImplementation;

- (void) animationWillStart:(CAAnimation *) animation
{
   mulle_printf( "willStart\n");
}

- (void) animationDidStart:(CAAnimation *) animation
{
}

- (void) animationDidStop:(CAAnimation *) animation
                 finished:(BOOL) finished
{
   mulle_printf( "didStop %s\n", finished ? "finished" : "interrupted");
}

@end


int   main( int argc, char *argv[])
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;
   CAAnimator         *animator;
   Foo                *foo;
   mulle_absolutetime_t  timestamp;

   foo = [Foo instance];
   [foo setValue:0];

   transaction = [CATransaction instance];
   assert( transaction);

   [transaction begin];
   {
      [transaction setAnimationDuration:1.0];
      [foo setValue:1848];
   }
   group = [transaction commit];
   [group setDelegate:foo];
   mulle_printf( "%td\n", [group numberOfAnimations]);

   animator = [CAAnimator instance];
   [animator addAnimation:group];

   for( timestamp = 0.0; timestamp <= 2.0; timestamp += 0.5)
      [animator animateWithAbsoluteTime:timestamp
                         animationRate:0.0];
   return( 0);
}
