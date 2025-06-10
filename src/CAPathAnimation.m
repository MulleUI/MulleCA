#import "CAPathAnimation.h"

#import "import-private.h"

#import "CAAnimation+DebugPrivate.h"

// Forward declaration of our custom interpolation functions
static void CAPathAnimationSetInterpolated2D(CABasicAnimation *self, id object, double x);
static void CAPathAnimationSetInterpolated2DAdditive(CABasicAnimation *self, id object, double x);
static void CAPathAnimationSetInterpolated1D(CABasicAnimation *self, id object, double x);
static void CAPathAnimationSetInterpolated1DAdditive(CABasicAnimation *self, id object, double x);
static void CAPathAnimationSetInterpolated4D(CABasicAnimation *self, id object, double x);
static void CAPathAnimationSetInterpolated4DAdditive(CABasicAnimation *self, id object, double x);

CAAnimationValueType CAPathAnimationGetAnimationValueType(CAPathAnimationValueType pathValueType)
{
   switch (pathValueType)
   {
   case CAPathAnimationValuePoint:
   case CAPathAnimationValueNormal:
   case CAPathAnimationValueTangent:
   case CAPathAnimationValuePointPlusNormal:
      return CAAnimationValueCGFloat2;

   case CAPathAnimationValueNormalAngle:
   case CAPathAnimationValueTangentAngle:
   case CAPathAnimationValueXPosition:
   case CAPathAnimationValueYPosition:
   case CAPathAnimationValueDistance:
      return CAAnimationValueCGFloat;

   case CAPathAnimationValueFrameOrigin:
   case CAPathAnimationValueFrameSize:
   case CAPathAnimationValueBoundsOrigin:
   case CAPathAnimationValueBoundsSize:
      return CAAnimationValueCGRect;

   default:
      return CAAnimationValueCGFloat2;
   }
}

@implementation CAPathAnimation

+ (instancetype) pathAnimationWithProperty:(struct _mulle_objc_property *) property
                                      path:(CGPathRef) path
                             pathValueType:(CAPathAnimationValueType) pathValueType
                                   options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                                     path:path
                            pathValueType:pathValueType
                                  options:options] autorelease];
}

- (id) initWithProperty:(struct _mulle_objc_property *) property
                   path:(CGPathRef) path
          pathValueType:(CAPathAnimationValueType) pathValueType
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;
   CAAnimationValueType          animValueType;

   if (!path || !property)
   {
      [self release];
      return nil;
   }

   // Determine the animation value type based on path value type
   animValueType = CAPathAnimationGetAnimationValueType(pathValueType);

   // Initialize with dummy start/end values
   if (animValueType == CAAnimationValueCGFloat2)
   {
      range.start = CAAnimationValueMakeWithPoint(CGPointZero);
      range.end   = CAAnimationValueMakeWithPoint(CGPointZero);
   }
   else
   {
      range.start.floatValue = 0.0f;
      range.end.floatValue   = 1.0f;
   }

   self = [super initWithProperty:property
                        valueType:animValueType
                       valueRange:&range
                          options:options];
   if (self)
   {
      _path = path;
      _pathValueType = pathValueType;

      // Choose interpolation functions based on value type
      if (animValueType == CAAnimationValueCGFloat2)
      {
         _interpolate = CAPathAnimationSetInterpolated2D;
         _interpolateAdditive = CAPathAnimationSetInterpolated2DAdditive;
      }
      else if (animValueType == CAAnimationValueCGRect)
      {
         _interpolate = CAPathAnimationSetInterpolated4D;
         _interpolateAdditive = CAPathAnimationSetInterpolated4DAdditive; // Need to implement this too
      }
      else
      {
         _interpolate = CAPathAnimationSetInterpolated1D;
         _interpolateAdditive = CAPathAnimationSetInterpolated1DAdditive;
      }

      CAAnimationLog("path animation created for property: \"%s\" valueType: %d",
                     mulle_objc_property_get_name(property), pathValueType);
   }
   return self;
}

- (void) setPath:(CGPathRef) path
{
   _path = path;
}

- (CGPathRef) path
{
   return( _path);
}

- (void) setPathValueType:(CAPathAnimationValueType) pathValueType
{
   _pathValueType = pathValueType;
}

- (CAPathAnimationValueType) pathValueType
{
   return _pathValueType;
}

- (char *) UTF8String
{
   char *valueTypeNames[] = {
      "Point", "Normal", "Tangent", "PointPlusNormal",
      "NormalAngle", "TangentAngle", "XPosition", "YPosition", "Distance"
   };
   char *valueTypeName = (_pathValueType < 9) ? valueTypeNames[_pathValueType] : "Unknown";

   char *s = MulleObjC_asprintf("<%s %p: path=%p valueType=%s %s>",
                                MulleObjCInstanceGetClassNameUTF8String(self),
                                self,
                                _path,
                                valueTypeName,
                                CAAnimationBitsUTF8String(self->_state.bits));
   return s;
}

// 2D interpolation function
static void CAPathAnimationSetInterpolated2D(CABasicAnimation *self,
                                             id object,
                                             double x)
{
   CAPathAnimation *pathAnim = (CAPathAnimation *)self;

   if (!pathAnim->_path)
      return;

   CGPathPointAndNormal pointAndNormal = CGPathGetPointAndNormalAtFraction(pathAnim->_path, (float)x);
   struct CGFloat2 value;

   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValuePoint:
      value.v0 = pointAndNormal.point.x;
      value.v1 = pointAndNormal.point.y;
      break;

   case CAPathAnimationValueNormal:
      value.v0 = pointAndNormal.normal.dx;
      value.v1 = pointAndNormal.normal.dy;
      break;

   case CAPathAnimationValueTangent:
      // Tangent is perpendicular to normal
      value.v0 = -pointAndNormal.normal.dy;
      value.v1 = pointAndNormal.normal.dx;
      break;

   case CAPathAnimationValuePointPlusNormal:
      value.v0 = pointAndNormal.point.x + pointAndNormal.normal.dx;
      value.v1 = pointAndNormal.point.y + pointAndNormal.normal.dy;
      break;

   // REMOVED: CAPathAnimationValueFrameOrigin case - it belongs in 4D function

   default:
      value.v0 = pointAndNormal.point.x;
      value.v1 = pointAndNormal.point.y;
      break;
   }

   {
      mulle_metaabi_union_void_return(struct CGFloat2) param;
      param.p = value;
      mulle_objc_object_call_variable(object, self->_property->setter, &param);
   }
}

// 1D interpolation function
static void CAPathAnimationSetInterpolated1D(CABasicAnimation *self,
                                             id object,
                                             double x)
{
   CAPathAnimation *pathAnim = (CAPathAnimation *)self;

   if (!pathAnim->_path)
      return;

   CGPathPointAndNormal pointAndNormal = CGPathGetPointAndNormalAtFraction(pathAnim->_path, (float)x);
   CGFloat value;

   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValueNormalAngle:
      value = atan2(pointAndNormal.normal.dy, pointAndNormal.normal.dx);
      break;

   case CAPathAnimationValueTangentAngle:
      // Tangent is perpendicular to normal
      value = atan2(pointAndNormal.normal.dx, -pointAndNormal.normal.dy);
      break;

   case CAPathAnimationValueXPosition:
      value = pointAndNormal.point.x;
      break;

   case CAPathAnimationValueYPosition:
      value = pointAndNormal.point.y;
      break;

   case CAPathAnimationValueDistance:
      value = x * CGPathGetLength(pathAnim->_path);
      break;

   default:
      value = 0.0f;
      break;
   }

   {
      mulle_metaabi_union_void_return(CGFloat) param;
      param.p = value;
      mulle_objc_object_call_variable(object, self->_property->setter, &param);
   }
}

// 2D additive interpolation
static void CAPathAnimationSetInterpolated2DAdditive(CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   CAPathAnimation *pathAnim = (CAPathAnimation *)self;

   if (!pathAnim->_path)
      return;

   CGPathPointAndNormal pointAndNormal = CGPathGetPointAndNormalAtFraction(pathAnim->_path, (float)x);
   struct CGFloat2 diff;
   struct CGFloat2 value;
   struct CGFloat2 newValue;

   // Calculate current difference based on path value type
   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValuePoint:
      diff.v0 = pointAndNormal.point.x;
      diff.v1 = pointAndNormal.point.y;
      break;

   case CAPathAnimationValueNormal:
      diff.v0 = pointAndNormal.normal.dx;
      diff.v1 = pointAndNormal.normal.dy;
      break;

   case CAPathAnimationValueTangent:
      // Tangent is perpendicular to normal
      diff.v0 = -pointAndNormal.normal.dy;
      diff.v1 = pointAndNormal.normal.dx;
      break;

   case CAPathAnimationValuePointPlusNormal:
      diff.v0 = pointAndNormal.point.x + pointAndNormal.normal.dx;
      diff.v1 = pointAndNormal.point.y + pointAndNormal.normal.dy;
      break;

   default:
      diff.v0 = pointAndNormal.point.x;
      diff.v1 = pointAndNormal.point.y;
      break;
   }

   // Get current value from object
   {
      mulle_metaabi_union_void_parameter(struct CGFloat2) param;
      mulle_objc_object_call_variable(object, self->_property->getter, &param);
      value = param.r;
   }

   // Calculate new value: current - previous + diff
   newValue.v0 = value.v0 - self->_previous.float2Value.v0 + diff.v0;
   newValue.v1 = value.v1 - self->_previous.float2Value.v1 + diff.v1;

   // Update previous diff
   self->_previous.float2Value = diff;

   // Set new value
   {
      mulle_metaabi_union_void_return(struct CGFloat2) param;
      param.p = newValue;
      mulle_objc_object_call_variable(object, self->_property->setter, &param);
   }
}

// 1D additive interpolation
static void CAPathAnimationSetInterpolated1DAdditive(CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   CAPathAnimation       *pathAnim = (CAPathAnimation *)self;
   CGPathPointAndNormal  pointAndNormal;
   CGFloat               diff;
   CGFloat               value;
   CGFloat               newValue;
   CGVector              tangent;

   if (!pathAnim->_path)
      return;

   pointAndNormal = CGPathGetPointAndNormalAtFraction(pathAnim->_path, (float)x);

   // Calculate current difference based on path value type
   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValueNormalAngle:
      diff = CGVectorGetAngle(pointAndNormal.normal);
      break;

   case CAPathAnimationValueTangentAngle:
      // Tangent is perpendicular to normal
      tangent = CGVectorMake(-pointAndNormal.normal.dy, pointAndNormal.normal.dx);
      diff = CGVectorGetAngle(tangent);
      break;

   case CAPathAnimationValueXPosition:
      diff = pointAndNormal.point.x;
      break;

   case CAPathAnimationValueYPosition:
      diff = pointAndNormal.point.y;
      break;

   case CAPathAnimationValueDistance:
      diff = x * CGPathGetLength(pathAnim->_path);
      break;

   default:
      diff = 0.0f;
      break;
   }

   // Get current value from object
   {
      mulle_metaabi_union_void_parameter(CGFloat) param;
      mulle_objc_object_call_variable(object, self->_property->getter, &param);
      value = param.r;
   }

   // Calculate new value: current - previous + diff
   newValue = value - self->_previous.floatValue + diff;

   // Update previous diff
   self->_previous.floatValue = diff;

   // Set new value
   {
      mulle_metaabi_union_void_return(CGFloat) param;
      param.p = newValue;
      mulle_objc_object_call_variable(object, self->_property->setter, &param);
   }
}

// 4D interpolation function for CGRect values
static void CAPathAnimationSetInterpolated4D(CABasicAnimation *self,
                                             id object,
                                             double x)
{
   CAPathAnimation *pathAnim = (CAPathAnimation *)self;

   if (!pathAnim->_path)
      return;

   CGPathPointAndNormal pointAndNormal = CGPathGetPointAndNormalAtFraction(pathAnim->_path, (float)x);
   struct CGFloat4 value;

   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValueFrameOrigin:
      // Get current frame to preserve size
      {
         mulle_metaabi_union_void_parameter(struct CGFloat4) currentParam;
         mulle_objc_object_call_variable(object, self->_property->getter, &currentParam);

         // Set origin directly from path point, keep existing size
         value.v0 = pointAndNormal.point.x; // frame.origin.x = path point x
         value.v1 = pointAndNormal.point.y; // frame.origin.y = path point y
         value.v2 = currentParam.r.v2; // Keep existing width
         value.v3 = currentParam.r.v3; // Keep existing height
      }
      break;

   case CAPathAnimationValueFrameSize:
      // Get current frame to preserve origin
      {
         mulle_metaabi_union_void_parameter(struct CGFloat4) currentParam;
         mulle_objc_object_call_variable(object, self->_property->getter, &currentParam);

         value.v0 = currentParam.r.v0; // Keep existing origin.x
         value.v1 = currentParam.r.v1; // Keep existing origin.y
         value.v2 = pointAndNormal.point.x; // width from path
         value.v3 = pointAndNormal.point.y; // height from path
      }
      break;

   default:
      // Get current frame for sensible defaults
      {
         mulle_metaabi_union_void_parameter(struct CGFloat4) currentParam;
         mulle_objc_object_call_variable(object, self->_property->getter, &currentParam);

         value.v0 = pointAndNormal.point.x;
         value.v1 = pointAndNormal.point.y;
         value.v2 = currentParam.r.v2; // Keep existing width
         value.v3 = currentParam.r.v3; // Keep existing height
      }
      break;
   }

   {
      mulle_metaabi_union_void_return(struct CGFloat4) param;
      param.p = value;
      mulle_objc_object_call_variable(object, self->_property->setter, &param);
   }
}

// 4D additive interpolation
static void CAPathAnimationSetInterpolated4DAdditive(CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   CAPathAnimation *pathAnim = (CAPathAnimation *)self;

   if (!pathAnim->_path)
      return;

   CGPathPointAndNormal pointAndNormal = CGPathGetPointAndNormalAtFraction(pathAnim->_path, (float)x);
   struct CGFloat4 diff;
   struct CGFloat4 value;
   struct CGFloat4 newValue;

   // Calculate current difference based on path value type
   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValueFrameOrigin:
      diff.v0 = pointAndNormal.point.x; // No magic offset
      diff.v1 = pointAndNormal.point.y;
      diff.v2 = 0; // Don't change size
      diff.v3 = 0;
      break;

   case CAPathAnimationValueFrameSize:
      diff.v0 = 0; // Don't change origin
      diff.v1 = 0;
      diff.v2 = pointAndNormal.point.x; // Size from path
      diff.v3 = pointAndNormal.point.y;
      break;

   default:
      diff.v0 = pointAndNormal.point.x;
      diff.v1 = pointAndNormal.point.y;
      diff.v2 = 0;
      diff.v3 = 0;
      break;
   }

   // Get current value from object
   {
      mulle_metaabi_union_void_parameter(struct CGFloat4) param;
      mulle_objc_object_call_variable(object, self->_property->getter, &param);
      value = param.r;
   }

   // Calculate new value: current - previous + diff
   newValue.v0 = value.v0 - self->_previous.float4Value.v0 + diff.v0;
   newValue.v1 = value.v1 - self->_previous.float4Value.v1 + diff.v1;
   newValue.v2 = value.v2 - self->_previous.float4Value.v2 + diff.v2;
   newValue.v3 = value.v3 - self->_previous.float4Value.v3 + diff.v3;

   // Update previous diff
   self->_previous.float4Value = diff;

   // Set new value
   {
      mulle_metaabi_union_void_return(struct CGFloat4) param;
      param.p = newValue;
      mulle_objc_object_call_variable(object, self->_property->setter, &param);
   }
}

@end
