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
   CABasicAnimation                 *animation;
   struct CABasicAnimationOptions   options;
   struct _mulle_objc_property      *property;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));
   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1),
                                                 1.0,
                                                 NO);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:1000
                                                   options:&options] autorelease];
   [animation setAnimationObject:foo];
   [animation setDelegate:foo];

   // animate to midpoint
   [animation animateObject:foo absoluteTime:0.0 animationRate:0.0];
   [animation animateObject:foo absoluteTime:0.5 animationRate:0.0];
   mulle_printf( "at midpoint x=%td\n", [foo x]);

   // cancel — should revert to start value (0)
   [animation cancel];
   mulle_printf( "after cancel x=%td\n", [foo x]);

   // next animate call reports done
   [animation animateObject:foo absoluteTime:0.6 animationRate:0.0];

   return( 0);
}
