#import <MulleCA/MulleCA.h>
#import <stdio.h>

#define DURATION        1.0
#define REPEATS         1.0
#define ANIMATION_RATE  (1.0 / 8.0)

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

   printf("CAPathAnimation Test 2: Curved Path\n");
   printf("===================================\n");

   // Create a curved path (quarter circle arc)
   path = CGPathCreateMutable();
   CGPathMoveToPoint(path, CGPointMake(100, 0));
   CGPathAddArcWithCenter(path, CGPointMake(0, 0), 100.0f,
                         CARadiansToAngle(0), 0.25f); // Quarter turn CCW

   options = CABasicAnimationOptionsMakeEaseInOut(
      mulle_relativetimerange_make(0, DURATION),
      REPEATS,
      NO  // don't reverse
   );

   testObject = [[TestObject alloc] init];
   [testObject setCenter:CGPointMake(-999, -999)]; // Initial position

   animation = [[CAPathAnimation alloc] initWithProperty:MulleObjCInstanceSearchProperty( testObject, @selector( center))
                                                    path:path
                                           pathValueType:CAPathAnimationValuePosition
                                                 options:&options];

   if (!animation) {
      printf("ERROR: Failed to create CAPathAnimation\n");
      return 1;
   }

   i = 0;
   CAAnimationStart(animation, 0.0, ANIMATION_RATE);

   printf("Animating along curved path:\n");
   for (elapsed = 0.0; elapsed <= DURATION; elapsed += ANIMATION_RATE) {
      info = CAAnimationComputeFrameInfo(animation, elapsed, 0.0);

      // Animate the test object
      [animation animateObject:testObject animationFrameInfo:&info];

      CGPoint currentCenter = [testObject center];

      printf("%2td: t=%5.3f center=(%7.2f,%7.2f)",
             i, info.t, currentCenter.x, currentCenter.y);

      // Basic sanity check - point should be roughly on circle of radius 100
      float distance = sqrt(currentCenter.x * currentCenter.x +
                           currentCenter.y * currentCenter.y);
      if (fabs(distance - 100.0f) > 5.0f) { // Allow some tolerance
         printf(" ERROR: Point not on circle! distance=%f\n", distance);
         return 1;
      } else {
         printf(" OK (dist=%5.1f)\n", distance);
      }

      CAAnimationDidAnimate(animation, elapsed, info);
      i++;
   }

   [animation release];
   [testObject release];
   CGPathDestroy(path);

   printf("Test 2: PASSED\n");
   return 0;
}