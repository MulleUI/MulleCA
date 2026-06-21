#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) CGFloat   flip;

@end


@implementation Foo

- (void) setFlip:(CGFloat) flip
{
   _flip = flip;
   mulle_printf( "flip=%.2f\n", (double) flip);
}

@end


int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *closeAnim;
   CABasicAnimation                 *openAnim;
   CAAnimationSequence              *sequence;
   struct CABasicAnimationOptions    closeOptions;
   struct CABasicAnimationOptions    openOptions;
   struct _mulle_objc_property      *property;
   mulle_absolutetime_t             timestamp;
   NSUInteger                       state;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( flip));

   // NULL options like MulleMemoryGame originally had
   sequence = [[[CAAnimationSequence alloc] initWithAnimationOptions:NULL] autorelease];
   [sequence setAnimationObject:foo];

   // First: flip 0→1 over 0.15s
   closeOptions = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0.0, 0.15), 1.0, NO);
   closeAnim = [[[CABasicAnimation alloc] initWithProperty:property
                                          startFloatValue:0.0
                                            endFloatValue:1.0
                                                  options:&closeOptions] autorelease];
   [closeAnim setAnimationObject:foo];
   [sequence addAnimation:closeAnim];

   // Second: flip 1→0 over 0.15s
   openOptions = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0.0, 0.15), 1.0, NO);
   openAnim = [[[CABasicAnimation alloc] initWithProperty:property
                                         startFloatValue:1.0
                                           endFloatValue:0.0
                                                 options:&openOptions] autorelease];
   [openAnim setAnimationObject:foo];
   [sequence addAnimation:openAnim];

   mulle_printf( "sequenceDuration: %.3f\n", [sequence sequenceDuration]);

   // Simulate 60fps with animationRate
   for( timestamp = 0.0; timestamp <= 1.2; timestamp += 0.016)
   {
      mulle_printf( "t=%.3f: ", timestamp);
      state = [sequence animateObject:foo
                         absoluteTime:timestamp
                        animationRate:0.01667];
      mulle_printf( " state=%u\n", state);
      if( state == CAAnimationReturnStateDone)
      {
         mulle_printf( "DONE\n");
         break;
      }
   }

   if( state != CAAnimationReturnStateDone)
      mulle_printf( "ERROR: sequence never finished!\n");

   return( 0);
}
