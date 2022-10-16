#import "import.h"


@class CAAnimationGroup;


@interface NSObject( CAAnimation)

- (void) generateAnimationsForPropertiesWithSnapshot:(id) snapshot
                        animationGroup:(CAAnimationGroup *) group;

@end

