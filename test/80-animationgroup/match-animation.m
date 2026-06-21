#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) CGFloat   alpha;
@property( assign) CGRect    bounds;

@end


@implementation Foo
@end


int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *flash;
   CABasicAnimation                 *bounce;
   CAAnimationGroup                 *group;
   struct CAAnimationOptions         groupOptions;
   struct CABasicAnimationOptions    flashOptions;
   struct CABasicAnimationOptions    bounceOptions;
   struct _mulle_objc_property      *alphaProp;
   struct _mulle_objc_property      *boundsProp;
   mulle_absolutetime_t             timestamp;
   NSUInteger                       state;
   CGRect                           bounds;
   CGRect                           largeBounds;

   foo = [Foo instance];
   [foo setAlpha:1.0];
   [foo setBounds:CGRectMake( 0, 0, 100, 100)];

   alphaProp  = MulleObjCInstanceSearchProperty( foo, @selector( alpha));
   boundsProp = MulleObjCInstanceSearchProperty( foo, @selector( bounds));

   // Group duration = 0.8 to cover bounce reversal
   groupOptions = CAAnimationOptionsMake(
      mulle_relativetimerange_make( 0.0, 0.8), 0.0, 1.0, 0);
   group = [CAAnimationGroup animationWithAnimationOptions:&groupOptions];
   [group setAnimationObject:foo];

   // Flash alpha: 1.0 -> 0.4, repeat 4x (even = returns to start), autoreverses
   flashOptions = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0.0, 0.15), 4.0, YES);
   flash = [[[CABasicAnimation alloc] initWithProperty:alphaProp
                                      startFloatValue:1.0
                                        endFloatValue:0.4
                                              options:&flashOptions] autorelease];
   [flash setAnimationObject:foo];
   [group addAnimation:flash];

   // Bounce bounds: normal -> large, repeat 2x (out+back), autoreverses
   bounds      = CGRectMake( 0, 0, 100, 100);
   largeBounds = CGRectMake( -10, -10, 120, 120);

   bounceOptions = CABasicAnimationOptionsMakeEaseInOut(
      mulle_relativetimerange_make( 0.0, 0.4), 2.0, YES);
   bounce = [[[CABasicAnimation alloc] initWithProperty:boundsProp
                                       startRectValue:bounds
                                         endRectValue:largeBounds
                                              options:&bounceOptions] autorelease];
   [bounce setAnimationObject:foo];
   [group addAnimation:bounce];

   // Run animation
   for( timestamp = 0.0; timestamp <= 1.5; timestamp += 0.016)
   {
      state = [group animateObject:foo
                      absoluteTime:timestamp
                     animationRate:0.01667];
      if( state == CAAnimationReturnStateDone)
         break;
   }

   mulle_printf( "finished at t=%.3f\n", timestamp);
   mulle_printf( "alpha=%.2f (expected 1.00)\n", (double) [foo alpha]);

   CGRect finalBounds = [foo bounds];
   mulle_printf( "bounds=[%.0f %.0f %.0f %.0f] (expected [0 0 100 100])\n",
                 (double) finalBounds.origin.x, (double) finalBounds.origin.y,
                 (double) finalBounds.size.width, (double) finalBounds.size.height);

   return( 0);
}
