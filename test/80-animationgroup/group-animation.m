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

- (void) start:(char *) animationID
        object:(id) obj
{
   printf( "start\n");
}

- (void) stop:(char *) animationID
        object:(id) obj
{
   printf( "stop\n");
}

@end


int   main( void)
{
   CAAnimator                       *animator;
   CAAnimationGroup                 *group;
   CABasicAnimation                 *animation;
   Foo                              *foo;
   mulle_absolutetime_t             timestamp;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;

   // create object, get property, create an animation for this property

   foo      = [Foo object];
   property = MulleObjCInstanceSearchProperty( foo, @selector( someIntegerValue));

   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1),
                                                 0.0,
                                                 NO);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:1000
                                                   options:&options] autorelease];
   [animation setAnimationObject:foo];

   group = [CAAnimationGroup object];

   // weird delegate interface
   [group setAnimationDelegate:foo];
   [group setAnimationWillStartSelector:@selector( start:object:)];
   [group setAnimationDidStopSelector:@selector( stop:object:)];
   [group addAnimation:animation];

   /*
    * animator now runs animation with our fake timestamps
    */
   animator = [CAAnimator object];
   [animator addAnimation:group];

   for( timestamp = 0.0; timestamp <= 1.2; timestamp += 0.2)
      [animator animateWithAbsoluteTime:timestamp
                         animationRate:0.0];
   return( 0);
}
