#import <MulleCA/MulleCA.h>


@interface Foo : NSObject <CAAnimationDelegate>

@property( assign) NSInteger   x;

@end


@implementation Foo

- (void) setX:(NSInteger) value
{
   _x = value;
}

- (void) animationWillStart:(CAAnimation *) animation
{
}

- (void) animationDidStart:(CAAnimation *) animation
{
}

- (void) animationDidStop:(CAAnimation *) animation
                 finished:(BOOL) finished
{
   mulle_printf( "didStop %s\n", finished ? "finished" : "cancelled");
}

@end


int   main( void)
{
   Foo                              *foo;
   CABasicAnimation                 *anim1;
   CABasicAnimation                 *anim2;
   CAAnimationSequence              *sequence;
   struct CABasicAnimationOptions   options;
   struct _mulle_objc_property      *property;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));
   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1),
                                                 1.0,
                                                 NO);

   // anim1: 0 -> 100 over 1s
   anim1 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:0
                                        endIntegerValue:100
                                                options:&options] autorelease];
   [anim1 setAnimationObject:foo];

   // anim2: 100 -> 200 over 1s
   anim2 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:100
                                        endIntegerValue:200
                                                options:&options] autorelease];
   [anim2 setAnimationObject:foo];

   sequence = [[[CAAnimationSequence alloc] initWithAnimationOptions:&(struct CAAnimationOptions){ { 0, 2.0 }, 0, 1.0, 0 }] autorelease];
   [sequence setAnimationObject:foo];
   [sequence setDelegate:foo];
   [sequence addAnimation:anim1];
   [sequence addAnimation:anim2];

   // animate into second animation (t=1.5 is midpoint of anim2)
   [sequence animateObject:foo absoluteTime:0.0 animationRate:0.0];
   [sequence animateObject:foo absoluteTime:0.5 animationRate:0.0];
   [sequence animateObject:foo absoluteTime:1.0 animationRate:0.0];
   [sequence animateObject:foo absoluteTime:1.5 animationRate:0.0];
   mulle_printf( "at midpoint of anim2 x=%td\n", [foo x]);

   // cancel — reverse order: anim2 writes start (100), anim1 writes start (0)
   [sequence cancel];
   mulle_printf( "after cancel x=%td\n", [foo x]);

   // next animate call reports done
   [sequence animateObject:foo absoluteTime:1.6 animationRate:0.0];

   return( 0);
}
