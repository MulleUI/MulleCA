#import <MulleCA/MulleCA.h>
#import <stdio.h>

#define DURATION        1.0
#define REPEATS         1.0
#define ANIMATION_RATE  (1.0 / 10.0)

// Mock object to test animation on
@interface TestObject : NSObject
{
   CGPoint _center;
}
@property CGPoint center;
@end

@implementation TestObject
- (CGPoint) center { return _center; }
- (void) setCenter:(CGPoint) center { _center = center; }
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
   CGPoint                         initialCenter;

   printf("CAPathAnimation Test 3: Additive Animation\n");
   printf("==========================================\n");

   // Create a simple path from (0,0) to (50,0) - horizontal line
   path = CGPathCreateMutable();
   CGPathMoveToPoint(path, CGPointMake(0, 0));
   CGPathAddLineToPoint(path, CGPointMake(50, 0));

   options = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make(0, DURATION),
      REPEATS,
      NO  // don't reverse
   );

   // Enable additive animation
   CABasicAnimationOptionsSetBit(&options, CAAnimationAdditive);

   testObject = [[TestObject alloc] init];
   initialCenter = CGPointMake(100, 200); // Start at (100, 200)
   [testObject setCenter:initialCenter];

   animation = [[CAPathAnimation alloc] initWithProperty:MulleObjCInstanceSearchProperty( testObject, @selector( center))
                                                    path:path
                                           pathValueType:CAPathAnimationValuePosition
                                                 options:&options];

   if (!animation) {
      printf("ERROR: Failed to create CAPathAnimation\n");
      return 1;
   }

   printf("Initial center: (%g, %g)\n", initialCenter.x, initialCenter.y);
   printf("Path: (0,0) -> (50,0)\n");
   printf("Expected: additive motion from (100,200) to (150,200)\n\n");

   i = 0;
   CAAnimationStart(animation, 0.0, ANIMATION_RATE);

   for (elapsed = 0.0; elapsed <= DURATION; elapsed += ANIMATION_RATE) {
      info = CAAnimationComputeFrameInfo(animation, elapsed, 0.0);

      // Animate the test object
      [animation animateObject:testObject animationFrameInfo:&info];

      CGPoint currentCenter = [testObject center];

      // For additive animation, the center should move from (100,200) to (150,200)
      float expectedX = 100.0f + (info.t * 50.0f);
      float expectedY = 200.0f; // Y should not change

      printf("%2td: t=%5.3f center=(%7.2f,%7.2f) expected=(%7.2f,%7.2f)",
             i, info.t, currentCenter.x, currentCenter.y, expectedX, expectedY);

      // Verify additive behavior
      if (fabs(currentCenter.x - expectedX) > 0.1 ||
          fabs(currentCenter.y - expectedY) > 0.1) {
         printf(" ERROR!\n");
         return 1;
      } else {
         printf(" OK\n");
      }

      CAAnimationDidAnimate(animation, elapsed, info);
      i++;
   }

   [animation release];
   [testObject release];
   CGPathDestroy(path);

   printf("Test 3: PASSED\n");
   return 0;
}