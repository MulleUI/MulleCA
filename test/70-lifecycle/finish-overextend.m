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
   mulle_printf( "didStop %s\n", finished ? "finished" : "interrupted");
}

@end


int   main( void)
{
   Foo                              *foo;
   CABasicAnimation                 *child;
   CAAnimationGroup                 *group;
   struct CABasicAnimationOptions   childOptions;
   struct CAAnimationOptions        groupOptions;
   struct _mulle_objc_property      *property;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));

   // child: 0 -> 1000 over 2 seconds (overextends group)
   childOptions = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 2),
                                                     1.0,
                                                     NO);
   child = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:0
                                        endIntegerValue:1000
                                                options:&childOptions] autorelease];
   [child setAnimationObject:foo];

   // group: duration=1 (shorter than child)
   groupOptions = CA_ANIMATION_OPTIONS_DATA( 0, 1, 0, 1, 0);
   group = [CAAnimationGroup animationWithAnimationOptions:&groupOptions];
   [group setDelegate:foo];
   [group addAnimation:child];

   // animate to t=0.5 (group at midpoint, child at quarter)
   [group animateObject:foo absoluteTime:0.0 animationRate:0.0];
   [group animateObject:foo absoluteTime:0.5 animationRate:0.0];

   mulle_printf( "before finish x=%td\n", [foo x]);

   // finish the group — child should jump to its end value
   [group finish];

   mulle_printf( "after finish x=%td\n", [foo x]);

   return( 0);
}
