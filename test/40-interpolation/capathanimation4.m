#import <MulleCA/MulleCA.h>
#import <stdio.h>

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
   struct CABasicAnimationOptions  options;
   CGPathRef                       path;

   printf("CAPathAnimation Test 4: Edge Cases\n");
   printf("==================================\n");

   options = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make(0, 1.0),
      1.0,
      NO
   );

   testObject = [[TestObject alloc] init];

   // Test 1: NULL path
   printf("Test 4a: NULL path... ");
   animation = [[CAPathAnimation alloc] initWithProperty:@property(center)
                                                    path:NULL
                                                 options:&options];
   if (animation == nil) {
      printf("OK (correctly rejected)\n");
   } else {
      printf("ERROR: Should have rejected NULL path\n");
      [animation release];
      return 1;
   }

   // Test 2: NULL property
   printf("Test 4b: NULL property... ");
   path = CGPathCreateMutable();
   CGPathMoveToPoint(path, CGPointMake(0, 0));
   CGPathAddLineToPoint(path, CGPointMake(10, 10));

   animation = [[CAPathAnimation alloc] initWithProperty:NULL
                                                    path:path
                                                 options:&options];
   if (animation == nil) {
      printf("OK (correctly rejected)\n");
   } else {
      printf("ERROR: Should have rejected NULL property\n");
      [animation release];
      return 1;
   }

   CGPathDestroy(path);

   // Test 3: Empty path (just move, no lines)
   printf("Test 4c: Empty path... ");
   path = CGPathCreateMutable();
   CGPathMoveToPoint(path, CGPointMake(5, 5)); // Just a move, no actual path

   animation = [[CAPathAnimation alloc] initWithProperty:@property(center)
                                                    path:path
                                                 options:&options];
   if (animation != nil) {
      printf("OK (accepted empty path)\n");
      [animation release];
   } else {
      printf("ERROR: Should accept empty path\n");
      return