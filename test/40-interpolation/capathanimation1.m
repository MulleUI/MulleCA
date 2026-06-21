#import <MulleCA/MulleCA.h>
#import <stdio.h>

#define DURATION        2.0
#define REPEATS         1.0
#define ANIMATION_RATE  (1.0 / 10.0)

// Mock object to test animation on
@interface TestObject : NSObject
@property CGPoint center;
@end

@implementation TestObject
@end


int main(int argc, char *argv[])
{
   CAPathAnimation                 *animation;
   TestObject                      *testObject;
   NSInteger                       i;
   struct CABasicAnimationOptions  options;
   struct CAAnimationFrameInfo     info;
   mulle_relativetime_t            elapsed;
   CGPathRef                       path;
   CGPoint                         expectedPoints[21]; // For verification
   struct _mulle_objc_property     *property;

   printf("CAPathAnimation Test 1: Linear Path\n");
   printf("===================================\n");

   // Create a simple linear path from (0,0) to (100,100)
   path = CGPathCreateMutable();
   CGPathMoveToPoint(path, CGPointMake(0, 0));
   CGPathAddLineToPoint(path, CGPointMake(100, 100));

   // Pre-calculate expected points for verification
   for (int j = 0; j <= 20; j++)
   {
      float t = j / 20.0f;
      expectedPoints[j] = CGPointMake(t * 100, t * 100);
   }

   options = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make(0, DURATION),
      REPEATS,
      NO  // don't reverse
   );

   testObject = [TestObject instance];
   [testObject setCenter:CGPointMake(-999, -999)]; // Initial position

   property  = MulleObjCInstanceSearchProperty( testObject, @selector( center));
   animation = [CAPathAnimation pathAnimationWithProperty:property
                                                     path:path
                                            pathValueType:CAPathAnimationValuePosition
                                                  options:&options];
   if( ! animation)
   {
      printf("ERROR: Failed to create CAPathAnimation\n");
      return 1;
   }

   i = 0;
   CAAnimationStart(animation, 0.0, ANIMATION_RATE);

   for (elapsed = 0.0; elapsed <= DURATION; elapsed += ANIMATION_RATE)
   {
      info = CAAnimationComputeFrameInfo(animation, elapsed, 0.0);

      // Animate the test object
      [animation animateObject:testObject
            animationFrameInfo:&info];

      CGPoint currentCenter = [testObject center];
      CGPoint expected = expectedPoints[i];

      printf("%2td: t=%5.3f center=(%6.2f,%6.2f) expected=(%6.2f,%6.2f)",
             i, info.t, currentCenter.x, currentCenter.y, expected.x, expected.y);

      // Verify the point is approximately correct (within 0.1 tolerance)
      if( fabs(currentCenter.x - expected.x) > 0.1 ||
          fabs(currentCenter.y - expected.y) > 0.1)
      {
         printf(" ERROR!\n");
         return 1;
      }
      else
      {
         printf(" OK\n");
      }

      CAAnimationDidAnimate(animation, elapsed, info);
      i++;
   }


   CGPathDestroy(path);

   printf("Test 1: PASSED\n");
   return 0;
}