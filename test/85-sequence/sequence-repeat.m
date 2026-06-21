#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) NSInteger   x;

@end


@implementation Foo

- (void) setX:(NSInteger) x
{
   _x = x;
   printf( "%td\n", x);
}

@end


int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *anim1;
   CABasicAnimation                 *anim2;
   CAAnimationSequence              *sequence;
   struct CABasicAnimationOptions   options;
   struct CAAnimationOptions        seqOptions;
   struct _mulle_objc_property      *property;
   mulle_absolutetime_t             timestamp;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));

   // Animation 1: 0 -> 100 over 1 second
   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1.0),
                                                1.0,
                                                NO);
   anim1 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:0
                                        endIntegerValue:100
                                                options:&options] autorelease];

   // Animation 2: 100 -> 200 over 1 second
   anim2 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:100
                                        endIntegerValue:200
                                                options:&options] autorelease];

   // Create sequence with duration=2.0, repeatCount=INFINITY
   seqOptions = (struct CAAnimationOptions){ { 0, 2.0 }, 0, INFINITY, 0 };
   sequence = [[[CAAnimationSequence alloc] initWithAnimationOptions:&seqOptions] autorelease];
   [sequence setAnimationObject:foo];

   [anim1 setAnimationObject:foo];
   [anim2 setAnimationObject:foo];

   [sequence addAnimation:anim1];
   [sequence addAnimation:anim2];

   printf( "sequenceDuration: %.1f\n", [sequence sequenceDuration]);

   // Animate at 0.5s intervals for 5 seconds (should see 2+ cycles)
   for( timestamp = 0.0; timestamp <= 5.0; timestamp += 0.5)
   {
      printf( "t=%.1f: ", timestamp);
      [sequence animateObject:foo
                 absoluteTime:timestamp
                animationRate:0.0];
   }

   return( 0);
}
