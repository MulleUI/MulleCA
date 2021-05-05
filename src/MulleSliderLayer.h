#import "CALayer.h"
#import "MulleEdgeInsets.h"


@interface MulleSliderLayer : CALayer

@property(assign) float  value;
@property(assign) float  minimumValue;
@property(assign) float  maximumValue;

@property( observable) CGColorRef        controlColor;
@property( observable) MulleEdgeInsets   controlInsets;


// the visible rect for control value, the knob
// overshoots this by its radius though (minus some border pixels)
- (CGRect) controlRectForRect:(CGRect) rect;
- (CGFloat) knobRadiusForRect:(CGRect) rect;

@end
