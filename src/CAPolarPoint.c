#include "CAPolarPoint.h"



// these functions get fairly huge!
CAPolarPoint   CAPolarPointAdd1( CAPolarPoint p, CAPolarPoint q)
{
   CGPoint   tmp;

   tmp = CGPointAdd( CAPolarPointAsPoint( p), CAPolarPointAsPoint( q));
   return( CGPointAsPolarPoint( tmp));
}

//
// https://math.stackexchange.com/questions/1365622/adding-two-polar-vectors
// implemented from: https://math.stackexchange.com/a/1365667
//
CAPolarPoint   CAPolarPointAdd2( CAPolarPoint p, CAPolarPoint q)
{
   CAPolarPoint   r;
   CGFloat        a;
   CGFloat        b;
   CGFloat        u;
   CGFloat        v;

   a        = q.angle - p.angle;
   u        = q.radius * cosf( a);
   v        = q.radius * sinf( a);
   r.radius = sqrtf( (p.radius + u) * (p.radius + u) + (v * v));
   r.angle  = p.angle + atan2( v, p.radius + u);
   return( r);
}



// these functions get fairly huge!
CAPolarPoint   CAPolarPointSubtract1( CAPolarPoint p, CAPolarPoint q)
{
   CGPoint   tmp;

   tmp = CGPointSubtract( CAPolarPointAsPoint( p), CAPolarPointAsPoint( q));
   return( CGPointAsPolarPoint( tmp));
}



CAPolarPoint   CAPolarPointSubtract2( CAPolarPoint p, CAPolarPoint q)
{
   CAPolarPoint   r;
   CGFloat        a;
   CGFloat        b;
   CGFloat        u;
   CGFloat        v;

   a        = q.angle - p.angle;
   u        = q.radius * cosf( a);
   v        = q.radius * sinf( a);
   r.radius = sqrtf( (p.radius - u) * (p.radius - u) + (v * v));
   r.angle  = p.angle - atan2( v, p.radius - u);
   return( r);
}
