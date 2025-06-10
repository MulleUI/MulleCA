#import "CABasicAnimation.h"


typedef NS_ENUM( NSUInteger, CAPathAnimationValueType)
{
   // 2D values (CGFloat2) - for CGPoint, CGSize, CGVector properties
   CAPathAnimationValuePoint,           // Point along path (x,y)
   CAPathAnimationValueNormal,          // Normal vector (dx,dy)
   CAPathAnimationValueTangent,         // Tangent vector (direction of travel)
   CAPathAnimationValuePointPlusNormal, // Point offset by normal

   // 1D values (CGFloat) - for rotation, position, etc.
   CAPathAnimationValueNormalAngle,     // Angle of normal vector (radians)
   CAPathAnimationValueTangentAngle,    // Angle of tangent vector (radians)
   CAPathAnimationValueXPosition,       // Just X coordinate of point
   CAPathAnimationValueYPosition,       // Just Y coordinate of point
   CAPathAnimationValueDistance,        // Distance traveled along path

   // CGRect values - vary origin or size while keeping the other constant
   CAPathAnimationValueFrameOrigin,     // Move frame origin along path (keep size)
   CAPathAnimationValueFrameSize,       // Vary frame size along path (keep origin)
   CAPathAnimationValueBoundsOrigin,    // Move bounds origin along path (keep size)
   CAPathAnimationValueBoundsSize,      // Vary bounds size along path (keep origin)
};

@interface CAPathAnimation : CABasicAnimation
{
   CGPath                       *_path;           // Path for animation
   CAPathAnimationValueType     _pathValueType; // What to extract from path
}

@property( assign) CGPath                    *path;
@property( assign) CAPathAnimationValueType  pathValueType;

+ (instancetype) pathAnimationWithProperty:(struct _mulle_objc_property *) property
                                      path:(CGPath *) path
                             pathValueType:(CAPathAnimationValueType) pathValueType
                                   options:(struct CABasicAnimationOptions *) options;

// Constructor for path animation
- (id) initWithProperty:(struct _mulle_objc_property *) property
                   path:(CGPath *) path
          pathValueType:(CAPathAnimationValueType) pathValueType
                options:(struct CABasicAnimationOptions *) options;

@end

// Convenience function to get the CAAnimationValueType for a given path value type
CAAnimationValueType CAPathAnimationGetAnimationValueType(CAPathAnimationValueType pathValueType);