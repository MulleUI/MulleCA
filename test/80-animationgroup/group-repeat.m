#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) NSInteger   x;
@property( assign) NSInteger   y;

@end


@implementation Foo

- (void) setX:(NSInteger) x
{
   _x = x;
   printf( "x=%td\n", x);
}

- (void) setY:(NSInteger) y
{
   _y = y;
   printf( "y=%td\n", y);
}

@end


int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *anim1;
   CABasicAnimation                 *anim2;
   CAAnimationGroup                 *group;
   struct CABasicAnimationOptions   options;
   struct CAAnimationOptions        groupOptions;
   struct _mulle_objc_property      *xProperty;
   struct _mulle_objc_property      *yProperty;
   mulle_absolutetime_t             timestamp;

   foo       = [Foo instance];
   xProperty = MulleObjCInstanceSearchProperty( foo, @selector( x));
   yProperty = MulleObjCInstanceSearchProperty( foo, @selector( y));

   // Animation 1: x 0 -> 100 over 1 second
   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1.0),
                                                1.0,
                                                NO);
   anim1 = [[[CABasicAnimation alloc] initWithProperty:xProperty
                                      startIntegerValue:0
                                        endIntegerValue:100
                                                options:&options] autorelease];
   [anim1 setAnimationObject:foo];

   // Animation 2: y 0 -> 200 over 1 second
   anim2 = [[[CABasicAnimation alloc] initWithProperty:yProperty
                                      startIntegerValue:0
                                        endIntegerValue:200
                                                options:&options] autorelease];
   [anim2 setAnimationObject:foo];

   // Group with duration=1.0, repeatCount=INFINITY (should cycle forever)
   groupOptions = (struct CAAnimationOptions){ { 0, 1.0 }, 0, INFINITY, 0 };
   group = [[[CAAnimationGroup alloc] initWithAnimationOptions:&groupOptions] autorelease];
   [group setAnimationObject:foo];
   [group addAnimation:anim1];
   [group addAnimation:anim2];

   // Animate for 3 seconds — expect 3 full cycles
   for( timestamp = 0.0; timestamp <= 3.0; timestamp += 0.5)
   {
      printf( "t=%.1f:\n", timestamp);
      [group animateObject:foo
                absoluteTime:timestamp
               animationRate:0.0];
   }

   return( 0);
}
