#ifndef cg_geometry_ca_animation_h__
#define cg_geometry_ca_animation_h__

// want to get M_PI, but are we included before math?

#include "include.h"

#include <math.h>
#include <assert.h>



#ifndef M_PI_f
# define M_PI_f     ((float) 3.141592653589793238462643383279502884L)
#endif
#ifndef M_PI_2f
# define M_PI_2f    (M_PI_f / 2.0)
#endif

// this doesn't exist usually (or name it M_2_PI_f ??)
#ifndef M_2_PIf
# define M_2_PIf    (M_PI_f * 2.0)
#endif


// Angles with orientation.
// With radians and degrees '0' is actually three o clock.
// But when thinking about rotation, you want the orientation like with an
// analog clock, that is CAAngleHour.
//
// Conversion between Radians and Degrees and back is lossless (within FP
// limitations). Conversion from and to CAAngleHour and CAAngleDirectional are
// lossy though.
//
// You will lose the amplitude of the rotation (i.e.  15* M_PI can
// be thought of as 15 turns) and the sign (CAAngleHour).
//
// If you have an indicator needle, that is usually centered and goes left
// (negative) or right (positive), the CAAngleDirectional is nice.
//
//          -M_PI/2
//        .---------.
// +/-M_PI| radians |0.0
//        '---------'
//           M_PI/2

typedef CGFloat     CAAngleRadians;

//           270
//       .---------.
//    180| degrees |0
//       '---------'
//           90

typedef CGFloat   CAAngleDegrees;


//
// There are no negative values (usually)
//
//            0 (12)
//        .------.
//       9| hour |3
//        '------'
//            6

typedef CGFloat     CAAngleHour;

//              0.0
//        .-------------.
//    -0.5| directional |0.5
//        '-------------'
//         -0.999  0.999

typedef CGFloat     CAAngleDirectional;



// MEMO: use CANormalizedFloatToRadians and not CANormalizedFloatAsRadians
//       because there is a calculation involved. Could also use a Get
//       but...
static inline CAAngleRadians   CANormalizedFloatToRadians( CGFloat x)
{
   assert( x >= 0.0 && x <= 1.0);
//   deg = fmodf( deg, 360.0f);
   return( x * M_PI_2f);
}



static inline CAAngleRadians   CAAngleDegreesToRadians( CAAngleDegrees deg)
{
//   deg = fmodf( deg, 360.0f);
   return( deg * M_PI_f / 180.0f);
}


static inline CAAngleDegrees   CAAngleRadiansToDegrees( CAAngleRadians rad)
{
//   rad = fmodf( rad, M_2_PIf);
   return( (CGFloat) (rad * 360.0f / M_2_PIf));
}


static inline CAAngleHour   CAAngleRadiansToHour( CAAngleRadians rad)
{
   CAAngleHour   hour;

   hour = (rad + M_PI_2f) * 12.0f / M_2_PIf;
   hour = fmod( hour, 12.0f);
   return( hour < 0.0f ? 12.0f + hour : hour);
}


static inline CAAngleRadians   CAAngleHourToRadians( CAAngleHour hour)
{
   CAAngleRadians   rad;

   assert( hour >= 0.0f && hour <= 12.0f);

   rad = hour / 12.0 * M_2_PIf;
   return( rad - M_PI_2f);
}


//
// an angle from -180 to +180 this is converted to  -1.0 - 1.0 (actually -0.9999 - 0.99999)
//
static inline CAAngleDirectional   CAAngleDegreesToDirectional( CAAngleDegrees deg)
{
   CAAngleDirectional   dir;

   dir = fmodf( (deg + 90.0f) / 360.0, 1.0f);
   return( dir);
}


//
// this can be used to discern full left CAAngleDirectional
//
static inline int  CAIsNegativeZero( CGFloat x)
{
   if( x != 0.0f)
      return( 1);

   if( sizeof( CGFloat) == sizeof( int32_t))
   {
      return( (*(int32_t *) &x) < 0);
   }
   if( sizeof( CGFloat) == sizeof( int64_t))
   {
      return( (*(int64_t *) &x) < 0);
   }
   assert( 0);
}


//
// degrees will be always positive, to this is a lossy conversion
//
static inline CAAngleDegrees   CAAngleDirectionalToDegrees( CAAngleDirectional dir)
{
   CAAngleDegrees   deg;

   deg = fmodf( dir * 360.0f, 360.0f);
   deg = deg - 90.0f; //  deg < 0.0 ? deg + 360.0f : deg);
   if( deg < 0.0f)
      return( 360.0f + deg);
   return( deg);
}




// mulle addition:
static inline CGPoint   CGPointMakeRandomInRect( CGRect r)
{
   return( CGPointMake( r.size.width * CGFloatMakeRandom() + r.origin.x,
                        r.size.height * CGFloatMakeRandom() + r.origin.y));
}


// mulle addition:
static inline CGSize   CGSizeMakeRandom( CGSize minSize, CGSize maxSize)
{
   assert( minSize.width <= maxSize.width);
   assert( minSize.height <= maxSize.height);

   return( CGSizeMake( minSize.width  + (maxSize.width - minSize.width)  * CGFloatMakeRandom(),
                       minSize.height + (maxSize.height - minSize.width) * CGFloatMakeRandom()));
}


// mulle addition:
static inline CGRect   CGRectMakeRandomInRect( CGRect r, CGSize minSize, CGSize maxSize)
{
   CGRect   rect;

   rect.size   = CGSizeMakeRandom( minSize, maxSize);
   rect.origin = CGPointMakeRandomInRect( CGRectMake( r.origin.x,
                                                      r.origin.y,
                                                      r.size.width - rect.size.width,
                                                      r.size.height - rect.size.height));
   return( rect);
}



// mulle addition:
static inline CGFloat   CGPointGetPolarRadius( CGPoint p)
{
   return( sqrtf( p.x * p.x + p.y * p.y));
}



// mulle addition:
static inline CAAngleRadians   CGPointGetPolarAngle( CGPoint p)
{
   if( CGPointEqualToPoint( p, CGPointZero))
      return( 0.0);
   return( atan2f( p.y, p.x));
}


//
// mulle addition (neg. size values possible due to OpenGl code) and flipping
// and the like
//
static inline CGPoint  CGPointClampToSize( CGPoint offset, CGSize size)
{
   if( size.width > 0.0)
   {
      if( offset.x < 0.0)
         offset.x = 0.0;
      if( offset.x >= size.width)
         offset.x = size.width;
   }
   else
   {
      if( offset.x > 0.0)
         offset.x = 0.0;
      if( offset.x <= size.width)
         offset.x = size.width;
   }

   if( size.height > 0.0)
   {
      if( offset.y < 0.0)
         offset.y = 0.0;
      if( offset.y >= size.height)
         offset.y = size.height;
   }
   else
   {
      if( offset.y > 0.0)
         offset.y = 0.0;
      if( offset.y <= size.height)
         offset.y = size.height;
   }

   return( offset);
}


static inline CGPoint   CGPointAdd( CGPoint p, CGPoint q)
{
   return( CGPointMake( p.x + q.x, p.y + q.y));
}


static inline CGPoint   CGPointSubtract( CGPoint p, CGPoint q)
{
   return( CGPointMake( p.x - q.x, p.y - q.y));
}


static inline CGPoint   CGPointMultiply( CGPoint p, CGPoint q)
{
   return( CGPointMake( p.x * q.x, p.y * q.y));
}


static inline CGFloat    CGPointGetDistanceToPoint( CGPoint p, CGPoint q)
{
   CGPoint  r;

   r = CGPointSubtract( q, p);
   return( CGPointGetPolarRadius( r));
}

#endif


