//
//  CAPathAnimation.h
//  MulleCA
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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
   case CAPathAnimationValueRotation           : return( "CAPathAnimationValueRotation");
   case CAPathAnimationValueAngle              : return( "CAPathAnimationValueAngle");
   case CAPathAnimationValueTangentAngle       : return( "CAPathAnimationValueTangentAngle");
   case CAPathAnimationValueXPosition          : return( "CAPathAnimationValueXPosition");
   case CAPathAnimationValueYPosition          : return( "CAPathAnimationValueYPosition");
   case CAPathAnimationValueDistance           : return( "CAPathAnimationValueDistance");
   case CAPathAnimationValuePosition           : return( "CAPathAnimationValuePosition");
   case CAPathAnimationValueNormal             : return( "CAPathAnimationValueNormal");
   case CAPathAnimationValueTangent            : return( "CAPathAnimationValueTangent");
   case CAPathAnimationValuePositionPlusNormal : return( "CAPathAnimationValuePositionPlusNormal");
   case CAPathAnimationValuePositionAsOrigin   : return( "CAPathAnimationValuePositionAsOrigin");
   case CAPathAnimationValuePositionAsSize     : return( "CAPathAnimationValuePositionAsSize");
   case CAPathAnimationValuePose               : return( "CAPathAnimationValuePose");
   default                                     : return( "???");
   }

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
MULLE_CA_GLOBAL
CAAnimationValueType CAPathAnimationGetAnimationValueType(CAPathAnimationValueType pathValueType);
