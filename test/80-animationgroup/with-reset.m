#import <MulleCA/MulleCA.h>

// the object class with a property we want to animate
@interface Foo : NSObject <CAAnimationDelegate>

@property NSUInteger   someIntegerValue;

@end


@implementation Foo

- (void) setSomeIntegerValue:(NSUInteger) value
{
   mulle_printf( "%td\n", value);
   _someIntegerValue = value;
}

- (void) animationWillStart:(CAAnimation *) animation
{
   mulle_printf( "start\n");
}

- (void) animationDidStart:(CAAnimation *) animation
{
}

- (void) animationDidStop:(CAAnimation *) animation
                 finished:(BOOL) finished
{
   mulle_printf( "stop\n");
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

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( someIntegerValue));

   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1),
                                                 0.0,
                                                 NO);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:1000
                                                   options:&options] autorelease];
   [animation setAnimationObject:foo];
   // see *1* below
   [animation setRemovedOnCompletion:NO];

   group = [CAAnimationGroup animationWithAnimationOptions:&options.base];
   [group setDelegate:foo];
   [group addAnimation:animation];
   [group setRemovedOnCompletion:NO];

   /*
    * animator now runs animation with our fake timestamps
    */
   animator = [CAAnimator instance];
   [animator addAnimation:group];

   for( timestamp = 0.0; timestamp <= 1.2; timestamp += 0.2)
      [animator animateWithAbsoluteTime:timestamp
                          animationRate:0.0];

   // *1* at this point, the "animation" would be dead, because by default
   // it is removed from the group on completion
   [group reset];

   for( timestamp = 0.0; timestamp <= 1.2; timestamp += 0.2)
      [animator animateWithAbsoluteTime:timestamp
                          animationRate:0.0];

   return( 0);
}
