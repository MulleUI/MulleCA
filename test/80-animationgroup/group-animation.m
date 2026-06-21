#import <MulleCA/MulleCA.h>


static CAAnimation   *s_group;
static CAAnimation   *s_animX;
static CAAnimation   *s_animY;


static char  *nameForAnimation( CAAnimation *animation)
{
   if( animation == s_group)
      return( "group");
   if( animation == s_animX)
      return( "x");
   if( animation == s_animY)
      return( "y");
   return( "?");
}


@interface Foo : NSObject <CAAnimationDelegate>

@property( assign) NSInteger   x;
@property( assign) NSInteger   y;

@end


@implementation Foo

- (void) setX:(NSInteger) value
{
   _x = value;
}

- (void) setY:(NSInteger) value
{
   _y = value;
}

- (void) animationWillStart:(CAAnimation *) animation
{
   mulle_printf( "willStart %s\n", nameForAnimation( animation));
}

- (void) animationDidStart:(CAAnimation *) animation
{
}

- (void) animationDidStop:(CAAnimation *) animation
                 finished:(BOOL) finished
{
   mulle_printf( "didStop %s\n", nameForAnimation( animation));
}

@end


int   main( void)
{
   CAAnimator                       *animator;
   CAAnimationGroup                 *group;
   CABasicAnimation                 *animX;
   CABasicAnimation                 *animY;
   Foo                              *foo;
   mulle_absolutetime_t             timestamp;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;

   foo     = [Foo instance];
   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1),
                                                1.0,
                                                NO);

   property = MulleObjCInstanceSearchProperty( foo, @selector( x));
   animX    = [[[CABasicAnimation alloc] initWithProperty:property
                                        startIntegerValue:0
                                          endIntegerValue:100
                                                  options:&options] autorelease];
   [animX setAnimationObject:foo];
   [animX setDelegate:foo];
   s_animX = (CAAnimation *) animX;

   property = MulleObjCInstanceSearchProperty( foo, @selector( y));
   animY    = [[[CABasicAnimation alloc] initWithProperty:property
                                        startIntegerValue:0
                                          endIntegerValue:200
                                                  options:&options] autorelease];
   [animY setAnimationObject:foo];
   [animY setDelegate:foo];
   s_animY = (CAAnimation *) animY;

   group   = [CAAnimationGroup instance];
   s_group = (CAAnimation *) group;
   [group setDelegate:foo];
   [group addAnimation:animX];
   [group addAnimation:animY];

   animator = [CAAnimator instance];
   [animator addAnimation:group];

   for( timestamp = 0.0; timestamp <= 2.0; timestamp += 0.5)
      [animator animateWithAbsoluteTime:timestamp
                         animationRate:0.0];
   return( 0);
}
