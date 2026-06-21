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
   CABasicAnimation                 *anim3;
   CAAnimationSequence              *sequence;
   struct CABasicAnimationOptions   options;
   struct _mulle_objc_property      *property;
   mulle_absolutetime_t             timestamp;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));

   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1.0),
                                                1.0,
                                                NO);

   // anim1: 0 -> 100
   anim1 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:0
                                        endIntegerValue:100
                                                options:&options] autorelease];
   [anim1 setAnimationObject:foo];

   // anim3: 200 -> 300
   anim3 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:200
                                        endIntegerValue:300
                                                options:&options] autorelease];
   [anim3 setAnimationObject:foo];

   // Build sequence: anim1, anim3
   sequence = [[[CAAnimationSequence alloc] initWithAnimationOptions:NULL] autorelease];
   [sequence setAnimationObject:foo];
   [sequence addAnimation:anim1];
   [sequence addAnimation:anim3];

   // Now insert anim2 (100 -> 200) between them
   anim2 = [[[CABasicAnimation alloc] initWithProperty:property
                                      startIntegerValue:100
                                        endIntegerValue:200
                                                options:&options] autorelease];
   [anim2 setAnimationObject:foo];
   [sequence insertAnimation:anim2 afterAnimation:anim1];

   printf( "sequenceDuration: %.1f\n", [sequence sequenceDuration]);

   // Animate — should be same as basic sequence test (3 seconds total)
   for( timestamp = 0.0; timestamp <= 3.2; timestamp += 0.5)
   {
      printf( "t=%.1f: ", timestamp);
      [sequence animateObject:foo
                 absoluteTime:timestamp
                animationRate:0.0];
   }

   return( 0);
}
