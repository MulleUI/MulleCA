#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) NSInteger   x;

@end


@implementation Foo

- (void) setX:(NSInteger) x
{
   _x = x;
   printf( "x=%td\n", x);
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
   struct _mulle_objc_property      *property;
   mulle_absolutetime_t             timestamp;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));

   // Animation 1: x 0 -> 100 over 0.6s (shorter than group)
   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 0.6),
                                                1.0,
                                                NO);
   anim1 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:0
                                        endIntegerValue:100
                                                options:&options] autorelease];
   [anim1 setAnimationObject:foo];

   // Animation 2: x 100 -> 0 instantly at 0.65s (reset)
   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0.65, 0.01),
                                                1.0,
                                                NO);
   anim2 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:100
                                        endIntegerValue:0
                                                options:&options] autorelease];
   [anim2 setAnimationObject:foo];

   // Group duration=2.5s, repeatCount=INFINITY
   // Children finish at 0.6s and 0.66s, group has 1.84s of dead time
   groupOptions = (struct CAAnimationOptions){ { 0, 2.5 }, 0, INFINITY, 0 };
   group = [[[CAAnimationGroup alloc] initWithAnimationOptions:&groupOptions] autorelease];
   [group setAnimationObject:foo];
   [group addAnimation:anim1];
   [group addAnimation:anim2];

   // Animate for 6 seconds — expect children to replay on each 2.5s cycle
   for( timestamp = 0.0; timestamp <= 6.0; timestamp += 0.5)
   {
      printf( "t=%.1f: ", timestamp);
      [group animateObject:foo
                absoluteTime:timestamp
               animationRate:0.0];
   }

   return( 0);
}
