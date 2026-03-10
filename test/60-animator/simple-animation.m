#import <MulleCA/MulleCA.h>

// the object class with a property we want to animate
@interface Foo : NSObject

@property NSUInteger   someIntegerValue;

@end


@implementation Foo

- (void) setSomeIntegerValue:(NSUInteger) value
{
   printf( "%td\n", value);
   _someIntegerValue = value;
}

@end


int   main( void)
{
   CAAnimator                       *animator;
   CABasicAnimation                 *animation;
   Foo                              *foo;
   mulle_absolutetime_t             timestamp;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;

   // create object, get property, create an animation for this property

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( someIntegerValue));

   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1),
                                                 1.0,
                                                 NO);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:1000
                                                   options:&options] autorelease];
   [animation setAnimationObject:foo];

   /*
    * animator now runs animation with our fake timestamps
    */
   animator = [CAAnimator instance];
   [animator addAnimation:animation];

   for( timestamp = 0.0; timestamp <= 1.2; timestamp += 0.2)
      [animator animateWithAbsoluteTime:timestamp
                          animationRate:0.0];
   return( 0);
}
