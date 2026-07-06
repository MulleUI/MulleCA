#import "CAPathAnimation.h"

#import "import-private.h"

#import "CAAnimation+DebugPrivate.h"
#include <mulle-objc-runtime/mulle-metaabi-call.h>


// Forward declaration of our custom interpolation functions
static void   CAPathAnimationSetInterpolated2D( CABasicAnimation *self,
                                                id object,
                                                double x);
static void   CAPathAnimationSetInterpolated2DAdditive( CABasicAnimation *self,
                                                        id object,
                                                        double x);
static void   CAPathAnimationSetInterpolated1D( CABasicAnimation *self,
                                                id object,
                                                double x);
static void   CAPathAnimationSetInterpolated1DAdditive( CABasicAnimation *self,
                                                        id object,
                                                        double x);
static void   CAPathAnimationSetInterpolated4D( CABasicAnimation *self,
                                                id object,
                                                double x);
static void   CAPathAnimationSetInterpolated4DAdditive( CABasicAnimation *self,
                                                        id object,
                                                        double x);


CAAnimationValueType CAPathAnimationGetAnimationValueType( CAPathAnimationValueType pathValueType)
{
   switch( pathValueType)
   {
   case CAPathAnimationValueRotation           :
   case CAPathAnimationValueAngle              :
   case CAPathAnimationValueTangentAngle       :
   case CAPathAnimationValueXPosition          :
   case CAPathAnimationValueYPosition          :
   case CAPathAnimationValueDistance           :
      return CAAnimationValueCGFloat;

   case CAPathAnimationValuePosition           :
   case CAPathAnimationValueNormal             :
   case CAPathAnimationValueTangent            :
   case CAPathAnimationValuePositionPlusNormal :
      return CAAnimationValueCGFloat2;

   case CAPathAnimationValuePositionAsOrigin   :
   case CAPathAnimationValuePositionAsSize     :
   case CAPathAnimationValuePose               :
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
   animValueType = CAPathAnimationGetAnimationValueType( pathValueType);

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
      _path          = path;
      _pathValueType = pathValueType;

      // Choose interpolation functions based on value type
      if( animValueType == CAAnimationValueCGFloat2)
      {
         _interpolate         = CAPathAnimationSetInterpolated2D;
         _interpolateAdditive = CAPathAnimationSetInterpolated2DAdditive;
      }
      else if (animValueType == CAAnimationValueCGRect)
      {
         _interpolate         = CAPathAnimationSetInterpolated4D;
         _interpolateAdditive = CAPathAnimationSetInterpolated4DAdditive; // Need to implement this too
      }
      else
      {
         _interpolate         = CAPathAnimationSetInterpolated1D;
         _interpolateAdditive = CAPathAnimationSetInterpolated1DAdditive;
      }

      CAAnimationLog("path animation created for property: \"%s\" valueType: %d",
                     mulle_objc_property_get_name(property), pathValueType);
   }
   return self;
}



- (char *) UTF8String
{
   char *s;

   s = MulleObjC_asprintf("<%s %p: path=%p valueType=%s %s>",
                                MulleObjCInstanceGetClassNameUTF8String(self),
                                self,
                                _path,
                                CAPathAnimationValueTypeUTF8String( _pathValueType),
                                CAAnimationBitsUTF8String(self->_state.bits));
   return( s);
}

// 1D interpolation function
static void CAPathAnimationSetInterpolated1D( CABasicAnimation *self,
                                              id object,
                                              double x)
{
   CGFloat           value;
   CAPathAnimation   *pathAnim = (CAPathAnimation *)self;
   CAPose            pose;

   if( ! pathAnim->_path)
      return;

   pose = CGPathGetPoseAtFraction( pathAnim->_path, (float) x);

   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValueRotation:
      value = CAPoseGetAngle( pose);
      break;

   case CAPathAnimationValueAngle:
      value = CAPoseGetAngle( pose);
      break;

   case CAPathAnimationValueTangentAngle:
      // Tangent is perpendicular to normal
      value = CAPoseGetRotation( pose);
      break;

   case CAPathAnimationValueXPosition:
      value = CAPoseGetPosition( pose).x;
      break;

   case CAPathAnimationValueYPosition:
      value = CAPoseGetPosition( pose).y;
      break;

   case CAPathAnimationValueDistance:
      value = x * CGPathGetLength( pathAnim->_path);
      break;

   default:
      abort();
   }

   mulle_metaabi_call( mulle_metaabi_void, object, self->_property->setter, value);
}


// 1D additive interpolation
static void CAPathAnimationSetInterpolated1DAdditive(CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   CAPathAnimation       *pathAnim = (CAPathAnimation *)self;
   CAPose  pose;
   CGFloat               diff;
   CGFloat               value;
   CGFloat               newValue;
   CGVector              tangent;

   if( ! pathAnim->_path)
      return;

   pose = CGPathGetPoseAtFraction(pathAnim->_path, (float)x);

   // Calculate current difference based on path value type
   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValueRotation:
      diff = CAPoseGetRotation(pose);
      break;

   case CAPathAnimationValueAngle:
      diff = CAPoseGetAngle( pose);
      break;

   case CAPathAnimationValueTangentAngle:
      // Tangent is perpendicular to normal
      tangent = CGVectorMake(-pose.normal.dy, pose.normal.dx);
      diff    = CGVectorGetAngle(tangent);
      break;

   case CAPathAnimationValueXPosition:
      diff = pose.position.x;
      break;

   case CAPathAnimationValueYPosition:
      diff = pose.position.y;
      break;

   case CAPathAnimationValueDistance:
      diff = x * CGPathGetLength(pathAnim->_path);
      break;

   default:
      abort();
      break;
   }

   mulle_metaabi_call( &value, object, self->_property->getter, object);

   // Calculate new value: current - previous + diff
   newValue = value - self->_previous.floatValue + diff;

   // Update previous diff
   self->_previous.floatValue = diff;

   mulle_metaabi_call( mulle_metaabi_void, object, self->_property->setter, newValue);
}


// 2D interpolation function
static void CAPathAnimationSetInterpolated2D(CABasicAnimation *self,
                                             id object,
                                             double x)
{
   struct CGFloat2   value;
   CAPose            pose;
   CAPathAnimation   *pathAnim = (CAPathAnimation *)self;

   if( ! pathAnim->_path)
      return;

   pose = CGPathGetPoseAtFraction(pathAnim->_path, (float)x);

   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValuePosition:
      value.v0 = pose.position.x;
      value.v1 = pose.position.y;
      break;

   case CAPathAnimationValueNormal:
      value.v0 = pose.normal.dx;
      value.v1 = pose.normal.dy;
      break;

   case CAPathAnimationValueTangent:
      // Tangent is perpendicular to normal
      value.v0 = -pose.normal.dy;
      value.v1 = pose.normal.dx;
      break;

   case CAPathAnimationValuePositionPlusNormal:
      value.v0 = pose.position.x + pose.normal.dx;
      value.v1 = pose.position.y + pose.normal.dy;
      break;

   default:
      abort();
   }

   mulle_metaabi_call( mulle_metaabi_void, object, self->_property->setter, value);
}


// 2D additive interpolation
static void CAPathAnimationSetInterpolated2DAdditive(CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CGFloat2   diff;
   struct CGFloat2   value;
   struct CGFloat2   newValue;
   CAPathAnimation   *pathAnim = (CAPathAnimation *)self;
   CAPose            pose;

   if( ! pathAnim->_path)
      return;

   pose = CGPathGetPoseAtFraction( pathAnim->_path, (float) x);

   // Calculate current difference based on path value type
   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValuePosition:
      diff.v0 = pose.position.x;
      diff.v1 = pose.position.y;
      break;

   case CAPathAnimationValueNormal:
      diff.v0 = pose.normal.dx;
      diff.v1 = pose.normal.dy;
      break;

   case CAPathAnimationValueTangent:
      // Tangent is perpendicular to normal
      diff.v0 = -pose.normal.dy;
      diff.v1 = pose.normal.dx;
      break;

   case CAPathAnimationValuePositionPlusNormal:
      diff.v0 = pose.position.x + pose.normal.dx;
      diff.v1 = pose.position.y + pose.normal.dy;
      break;

   default:
      diff.v0 = pose.position.x;
      diff.v1 = pose.position.y;
      break;
   }

   mulle_metaabi_call( &value, object, self->_property->getter, object);

   // Calculate new value: current - previous + diff
   newValue.v0 = value.v0 - self->_previous.float2Value.v0 + diff.v0;
   newValue.v1 = value.v1 - self->_previous.float2Value.v1 + diff.v1;

   // Update previous diff
   self->_previous.float2Value = diff;


   mulle_metaabi_call( mulle_metaabi_void, object, self->_property->setter, newValue);
}


// 4D interpolation function for CGRect values
static void CAPathAnimationSetInterpolated4D( CABasicAnimation *self,
                                              id object,
                                              double x)
{
   struct CGFloat4   value;
   CAPathAnimation   *pathAnim = (CAPathAnimation *)self;
   CAPose            pose;

   if( ! pathAnim->_path)
      return;

   pose = CGPathGetPoseAtFraction(pathAnim->_path, (float)x);

   switch( pathAnim->_pathValueType)
   {
   case CAPathAnimationValuePositionAsOrigin:
      // Get current frame to preserve size
      {
         mulle_metaabi_union_void_parameter(struct CGFloat4) currentParam;
         mulle_objc_object_call_variable(object, self->_property->getter, &currentParam);

         // Set origin directly from path point, keep existing size
         value.v0 = pose.position.x; // frame.origin.x = path point x
         value.v1 = pose.position.y; // frame.origin.y = path point y
         value.v2 = currentParam.r.v2; // Keep existing width
         value.v3 = currentParam.r.v3; // Keep existing height
      }
      break;

   case CAPathAnimationValuePositionAsSize:
      // Get current frame to preserve origin
      {
         mulle_metaabi_union_void_parameter(struct CGFloat4) currentParam;
         mulle_objc_object_call_variable(object, self->_property->getter, &currentParam);

         value.v0 = currentParam.r.v0; // Keep existing origin.x
         value.v1 = currentParam.r.v1; // Keep existing origin.y
         value.v2 = pose.position.x; // width from path
         value.v3 = pose.position.y; // height from path
      }
      break;

      case CAPathAnimationValuePose:
      {
         mulle_metaabi_union_void_parameter(struct CGFloat4) currentParam;
         mulle_objc_object_call_variable(object, self->_property->getter, &currentParam);

         value.v0 = pose.position.x;
         value.v1 = pose.position.y;
         value.v2 = pose.normal.dx;
         value.v3 = pose.normal.dy;
      }
      break;

      default:
         abort();
   }

   mulle_metaabi_call( mulle_metaabi_void, object, self->_property->setter, value);
}


// 4D additive interpolation
static void   CAPathAnimationSetInterpolated4DAdditive(CABasicAnimation *self,
                                                       id object,
                                                       double x)
{
   struct CGFloat4   diff;
   struct CGFloat4   value;
   struct CGFloat4   newValue;
   CAPose            pose;
   CAPathAnimation   *pathAnim = (CAPathAnimation *) self;

   if( ! pathAnim->_path)
      return;

   pose = CGPathGetPoseAtFraction(pathAnim->_path, (float) x);

   // Calculate current difference based on path value type
   switch (pathAnim->_pathValueType)
   {
   case CAPathAnimationValuePositionAsOrigin:
      diff.v0 = pose.position.x; // No magic offset
      diff.v1 = pose.position.y;
      diff.v2 = 0; // Don't change size
      diff.v3 = 0;
      break;

   case CAPathAnimationValuePositionAsSize:
      diff.v0 = 0; // Don't change origin
      diff.v1 = 0;
      diff.v2 = pose.position.x; // Size from path
      diff.v3 = pose.position.y;
      break;

   case CAPathAnimationValuePose:
      diff.v0 = pose.position.x;
      diff.v1 = pose.position.y;
      diff.v2 = pose.normal.dx;;
      diff.v3 = pose.normal.dy;
      break;

   default:
      abort();
   }

   mulle_metaabi_call( &value, object, self->_property->getter, object);

   // Calculate new value: current - previous + diff
   newValue.v0 = value.v0 - self->_previous.float4Value.v0 + diff.v0;
   newValue.v1 = value.v1 - self->_previous.float4Value.v1 + diff.v1;
   newValue.v2 = value.v2 - self->_previous.float4Value.v2 + diff.v2;
   newValue.v3 = value.v3 - self->_previous.float4Value.v3 + diff.v3;

   // Update previous diff
   self->_previous.float4Value = diff;

   mulle_metaabi_call( mulle_metaabi_void, object, self->_property->setter, newValue);
}

@end
