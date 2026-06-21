#import <MulleCA/MulleCA.h>


@interface Foo : NSObject <CAAnimationDelegate>

@property( assign) NSInteger   x;

@end


@implementation Foo

- (void) setX:(NSInteger) value
{
   _x = value;
   mulle_printf( "%td\n", value);
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
   mulle_printf( "didStop %s\n", finished ? "finished" : "interrupted");
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
   mulle_printf( "t=0.0: ");
   [animation animateObject:foo absoluteTime:0.0 animationRate:0.0];
   mulle_printf( "t=0.5: ");
   [animation animateObject:foo absoluteTime:0.5 animationRate:0.0];

   // finish mid-flight — should jump to end value
   mulle_printf( "finish: ");
   [animation finish];
   mulle_printf( "x=%td\n", [foo x]);

   return( 0);
}
