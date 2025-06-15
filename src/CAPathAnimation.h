#import "CABasicAnimation.h"


typedef NS_ENUM( NSUInteger, CAPathAnimationValueType)
{
   // 1D values (CGFloat) - for rotation, position, etc.
   CAPathAnimationValueRotation,        // Rotation of normal vector
   CAPathAnimationValueAngle,           // Angle of normal vector
   CAPathAnimationValueTangentAngle,    // Angle of tangent vector
   CAPathAnimationValueXPosition,       // Just X coordinate of point
   CAPathAnimationValueYPosition,       // Just Y coordinate of point
   CAPathAnimationValueDistance,        // Distance traveled along path

   // 2D values (CGFloat2) - for CGPoint, CGSize, CGVector properties
   CAPathAnimationValuePosition,        // Point along path (x,y)
   CAPathAnimationValueNormal,          // Normal vector (dx,dy)
   CAPathAnimationValueTangent,         // Tangent vector (direction of travel)
   CAPathAnimationValuePositionPlusNormal, // Point offset by normal

   // CGRect values - vary origin or size while keeping the other constant
   CAPathAnimationValuePose,             // store Pose as is
   CAPathAnimationValuePositionAsOrigin, // Move frame origin along path (keep size)
   CAPathAnimationValuePositionAsSize    // Vary frame size along path (keep origin)
};


static inline char  *_CAPathAnimationValueTypeUTF8String( CAPathAnimationValueType type)
{
   switch( type)
   {
   case CAPathAnimationValueRotation:           return( "rotation");
   case CAPathAnimationValueAngle:              return( "Angle");
   case CAPathAnimationValueTangentAngle:       return( "TangentAngle");
   case CAPathAnimationValueXPosition:          return( "XPosition");
   case CAPathAnimationValueYPosition:          return( "YPosition");
   case CAPathAnimationValueDistance:           return( "Distance");
   case CAPathAnimationValuePosition:           return( "Position");
   case CAPathAnimationValueNormal:             return( "Normal");
   case CAPathAnimationValueTangent:            return( "Tangent");
   case CAPathAnimationValuePositionPlusNormal: return( "PositionPlusNormal");
   case CAPathAnimationValuePositionAsOrigin:   return( "PositionAsOrigin");
   case CAPathAnimationValuePositionAsSize:     return( "PositionAsSize");
   case CAPathAnimationValuePose:               return( "Pose");
   }
   return( NULL);
}


static inline char  *CAPathAnimationValueTypeUTF8String( CAPathAnimationValueType type)
{
   char   *s;

   s = _CAPathAnimationValueTypeUTF8String( type);
   return( s ? s : "???");
}


@interface CAPathAnimation : CABasicAnimation

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