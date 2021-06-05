#ifndef CA_QUADRATIC_H__
#define CA_QUADRATIC_H__


#include "include.h"

#include <assert.h>



typedef struct CAQuadratic
{
   CGFloat   value[ 4];
} CAQuadratic;


static inline CAQuadratic
   CAQuadraticMake( CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3)
{
   return( (struct CAQuadratic) {
                                  .value[ 0] = p0,
                                  .value[ 1] = p1,
                                  .value[ 2] = p2,
                                  .value[ 3] = p3
                                });
}


static inline void   CAQuadraticInit( CAQuadratic *q,
                                      CGFloat p0,
                                      CGFloat p1,
                                      CGFloat p2,
                                      CGFloat p3)
{
   assert( p0 >= 0.0 && p0 <= 1.0);
   assert( p1 >= 0.0 && p1 <= 1.0);
   assert( p2 >= 0.0 && p2 <= 1.0);
   assert( p3 >= 0.0 && p3 <= 1.0);

   q->value[ 0] = p0;
   q->value[ 1] = p1;
   q->value[ 2] = p2;
   q->value[ 3] = p3;
}


#define CAQuadraticLinear    ((struct CAQuadratic) { 0.0f, 0.333f, 0.666f, 1.0f })
#define CAQuadraticEaseInOut ((struct CAQuadratic) { 0.0f, 0.025f, 0.975f, 1.0f })
#define CAQuadraticEaseOut   ((struct CAQuadratic) { 0.0f, 0.9f, 0.9f, 1.0f })
#define CAQuadraticEaseIn    ((struct CAQuadratic) { 0.0f, 0.0f, 0.1f, 1.0f })


//
// possibly too large for inlining ca. 100 bytes!
//
static inline CGFloat   _CAQuadraticGetValue( CAQuadratic *b, CGFloat t)
{
   CGFloat   value;

   assert( t >= 0.0 && t <= 1.0);

   value = (1 - t) * (1 - t) * (1 - t) * b->value[0] +
       3 * (1 - t) * (1 - t) * t * b->value[1] +
       3 * (1 - t) * t * t * b->value[2] +
       t * t * t * b->value[3];
   return( value);
}

static inline CGFloat   CAQuadraticGetValue( CAQuadratic *b, CGFloat t)
{
   if( ! b)
      return( 0.0);
   return( _CAQuadraticGetValue( b, t));
}


typedef struct CAQuadraticBezier
{
   CAQuadratic   x;
   CAQuadratic   y;
} CAQuadraticBezier;  // not CGPoint for supposed improved CPU caching


static inline CAQuadraticBezier
   CAQuadraticBezierMake( CGPoint p0, CGPoint p1, CGPoint p2, CGPoint p3)
{
   return( (struct CAQuadraticBezier)
               {
                .x = CAQuadraticMake( p0.x, p1.x, p2.x, p3.x),
                .y = CAQuadraticMake( p0.y, p1.y, p2.y, p3.y)
               });
}



static inline void   CAQuadraticBezierInit( CAQuadraticBezier *b,
                                            CGPoint p0,
                                            CGPoint p1,
                                            CGPoint p2,
                                            CGPoint p3)
{
   CAQuadraticInit( &b->x, p0.x, p1.x, p2.x, p3.x);
   CAQuadraticInit( &b->y, p0.y, p1.y, p2.y, p3.y);
}

CGPoint   CAQuadraticBezierGetPoint( CAQuadraticBezier *b, CGFloat t);


typedef CGFloat   CATweenFunction( struct CAQuadratic *q, CGFloat t);


#endif
