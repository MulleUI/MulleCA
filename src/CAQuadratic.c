#include "CAQuadratic.h"

//
// t is 0 to 1
//
//
// stolen from: https://stackoverflow.com/questions/5634460/quadratic-b%C3%A9zier-curve-calculate-points
//

CGPoint   CAQuadraticBezierGetPoint( CAQuadraticBezier *b, CGFloat t)
{
   CGPoint curvePoint;

   curvePoint.x = CAQuadraticGetValue( &b->x, t);
   curvePoint.y = CAQuadraticGetValue( &b->y, t);

   return( curvePoint);
}
