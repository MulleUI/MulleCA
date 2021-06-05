#ifndef ca_polar_point_h__
#define ca_polar_point_h__

#include "include.h"

#include "CGGeometry+CAAnimation.h"

#include <math.h>


// TODO: make this CGCAPolarPoint ?

typedef struct CAPolarPoint
{
   CGFloat          radius;
   CAAngleRadians   angle;
} CAPolarPoint;


// apparently the iso norm for spherical is radius first, then angles
// assume this is the way to go for 2D also
static inline CAPolarPoint   CAPolarPointMake( CGFloat r, CAAngleRadians a)
{
   return( (CAPolarPoint) { .radius = r, .angle = a });
}


static inline CGPoint  CAPolarPointAsPoint( CAPolarPoint v)
{
   return( CGPointMake( cosf( v.angle) * v.radius,
                        sinf( v.angle) * v.radius));
}


//
// makes angle between 0 and 2 PI, if radius is negative, flip the vector
//
static CAPolarPoint  CAPolarPointStandardize( CAPolarPoint v)
{
   if( v.radius < 0.0)
   {
      v.angle  = v.angle + M_PI_f;
      v.radius = -v.radius;
   }
   v.angle = fmodf( v.angle, M_2_PIf);
   return( v);
}


static inline int   CAPolarPointEqualToPolarPoint( CAPolarPoint p, CAPolarPoint q)
{
   // as angles can wrap around and so do negative radiuses we could convert to
   // CGPoints which are unique and compare those. Instead we assume that
   // standardization is a little faster
   p = CAPolarPointStandardize( p);
   q = CAPolarPointStandardize( q);
   return( p.radius == q.radius && p.angle == q.angle);
}


static inline CAPolarPoint  CGPointAsPolarPoint( CGPoint p)
{
   return( CAPolarPointMake( CGPointGetPolarRadius( p), CGPointGetPolarAngle( p)));
}


static CGPoint   CGPointAddPolarPoint( CGPoint p, CAPolarPoint v)
{
   return( CGPointAdd( p, CAPolarPointAsPoint( v)));
}


CAPolarPoint   CAPolarPointAdd1( CAPolarPoint p, CAPolarPoint q);
CAPolarPoint   CAPolarPointAdd2( CAPolarPoint p, CAPolarPoint q);

static inline CAPolarPoint   CAPolarPointAdd( CAPolarPoint p, CAPolarPoint q)
{
   return( CAPolarPointAdd2( p, q));  // benched faster
}


CAPolarPoint   CAPolarPointSubtract1( CAPolarPoint p, CAPolarPoint q);
CAPolarPoint   CAPolarPointSubtract2( CAPolarPoint p, CAPolarPoint q);

static inline CAPolarPoint   CAPolarPointSubtract( CAPolarPoint p, CAPolarPoint q)
{
   return( CAPolarPointSubtract2( p, q));  // benched faster
}


static CAPolarPoint  CAPolarPointAddPoint( CAPolarPoint v, CGPoint p)
{
   CGPoint  r;

   r = CGPointAdd( CAPolarPointAsPoint( v), p);
   return( CGPointAsPolarPoint( r));
}


static CAPolarPoint  CAPolarPointSubtractPoint( CAPolarPoint v, CGPoint p)
{
   CGPoint  r;

   r = CGPointSubtract( CAPolarPointAsPoint( v), p);
   return( CGPointAsPolarPoint( r));
}


#endif
