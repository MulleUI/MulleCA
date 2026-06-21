#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) CGFloat   flip;

@end


@implementation Foo

- (void) setFlip:(CGFloat) flip
{
   _flip = flip;
}

@end


// Reproduces MulleMemoryGame issue: animator calls at ~1ms intervals
// but animationRate is 16.67ms (60fps). The sequence takes much longer
// than expected to complete.
int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *closeAnim;
   CABasicAnimation                 *openAnim;
   CAAnimationSequence              *sequence;
   struct CAAnimationOptions         seqOptions;
   struct CABasicAnimationOptions    closeOptions;
   struct CABasicAnimationOptions    openOptions;
   struct _mulle_objc_property      *property;
   mulle_absolutetime_t             timestamp;
   NSUInteger                       state;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( flip));

   seqOptions = CAAnimationOptionsMake(
      mulle_relativetimerange_make( 0.0, 0.3), 0.0, 1.0, 0);
   sequence = [[[CAAnimationSequence alloc] initWithAnimationOptions:&seqOptions] autorelease];
   [sequence setAnimationObject:foo];

   closeOptions = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0.0, 0.15), 1.0, NO);
   closeAnim = [[[CABasicAnimation alloc] initWithProperty:property
                                          startFloatValue:0.0
                                            endFloatValue:1.0
                                                  options:&closeOptions] autorelease];
   [closeAnim setAnimationObject:foo];
   [sequence addAnimation:closeAnim];

   openOptions = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0.0, 0.15), 1.0, NO);
   openAnim = [[[CABasicAnimation alloc] initWithProperty:property
                                         startFloatValue:1.0
                                           endFloatValue:0.0
                                                 options:&openOptions] autorelease];
   [openAnim setAnimationObject:foo];
   [sequence addAnimation:openAnim];

   // Simulate animator calling at ~1ms intervals with large absolute timestamps
   // like the real app (timestamps around 10000+)
   state = 0;
   for( timestamp = 10000.0; timestamp <= 10002.0; timestamp += 0.001)
   {
      state = [sequence animateObject:foo
                         absoluteTime:timestamp
                        animationRate:0.01667];
      if( state == CAAnimationReturnStateDone)
         break;
   }

   mulle_printf( "finished at t=%.3f (expected ~10000.3)\n", timestamp);
   if( timestamp - 10000.0 > 0.5)
      mulle_printf( "BUG: sequence took %.3fs instead of 0.3s\n", timestamp - 10000.0);

   return( 0);
}
