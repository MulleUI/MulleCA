#import <MulleCA/MulleCA.h>


@interface Foo : NSObject

@property( assign) NSInteger   x;

@end


@implementation Foo

- (void) setX:(NSInteger) value
{
   _x = value;
   mulle_printf( "%td\n", value);
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

   // animate to midpoint
   mulle_printf( "t=0.0: ");
   [animation animateObject:foo absoluteTime:0.0 animationRate:0.0];
   mulle_printf( "t=0.5: ");
   [animation animateObject:foo absoluteTime:0.5 animationRate:0.0];

   // reset mid-flight — animation restarts from beginning
   [animation reset];
   mulle_printf( "after reset x=%td\n", [foo x]);

   // animate again from scratch — should start fresh
   mulle_printf( "t=0.0: ");
   [animation animateObject:foo absoluteTime:0.0 animationRate:0.0];
   mulle_printf( "t=0.5: ");
   [animation animateObject:foo absoluteTime:0.5 animationRate:0.0];
   mulle_printf( "t=1.0: ");
   [animation animateObject:foo absoluteTime:1.0 animationRate:0.0];

   return( 0);
}
