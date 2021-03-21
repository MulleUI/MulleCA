#ifndef cg_color_h__
#define cg_color_h__

#include "CGBase.h"
#include <math.h>
#include "nanovg.h"
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>


typedef NVGcolor   CGColorRef;
typedef void       *CGColorSpaceRef;


// NVGColor is a float[ 4] in reality
static inline NVGcolor getNVGColor( uint32_t color) 
{
	return nvgRGBA(
		(color >> 24) & 0xff,
		(color >> 16) & 0xff,
		(color >> 8) & 0xff,
		(color >> 0) & 0xff);
}

static inline CGColorRef   MulleColorCreate( uint32_t color)
{
   return( getNVGColor( color));
}


static inline CGColorRef   MulleColorCreateRandom( uint32_t color, uint32_t mask)
{
   uint32_t  value;

   color &= ~mask;
   color |= ((uint32_t) rand()) & mask;
   return( getNVGColor( color));
}

static inline CGColorRef   MulleColorCreateRandomOpaque( void)
{
   return( MulleColorCreateRandom( 0xFF, 0xFFFFFF00));
}


// Returns color value specified by hue, saturation and lightness.
// HSL values are all in range [0..1], alpha will be set to 255.
static inline CGColorRef   
   MulleColorCreateHSL( CGFloat h, CGFloat s, CGFloat l)
{
   assert( h >= 0.0 && h <= 1.0);
   assert( s >= 0.0 && s <= 1.0);
   assert( l >= 0.0 && l <= 1.0);

   return( nvgHSL( h, s, l));
}

// here alpha is not like nvg 0-255 but 0-1
static inline CGColorRef   
   MulleColorCreateHSLA( CGFloat h, CGFloat s, CGFloat l, CGFloat a)
{
   assert( h >= 0.0 && h <= 1.0);
   assert( s >= 0.0 && s <= 1.0);
   assert( l >= 0.0 && l <= 1.0);
   assert( a >= 0.0 && a <= 1.0);

   return( nvgHSLA( h, s, l, a * 255.0));
}



static inline CGColorRef 
   CGColorCreateGenericRGB( CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
   assert( r >= 0.0 && r <= 1.0);
   assert( g >= 0.0 && g <= 1.0);
   assert( b >= 0.0 && g <= 1.0);
   assert( a >= 0.0 && a <= 1.0);

   return( nvgRGBA( (uint32_t) round( 0xff * r),
                    (uint32_t) round( 0xff * g),
                    (uint32_t) round( 0xff * b),
                    (uint32_t) round( 0xff * a)));
}


static inline CGColorRef CGColorCreate( CGColorSpaceRef space, const CGFloat *components)
{
   return( CGColorCreateGenericRGB( components[ 0], 
                                    components[ 1], 
                                    components[ 2],
                                    components[ 3]));
}


static inline int    CGColorGetNumberOfComponents(CGColorRef color)
{
   return( 4);
}


static inline void   MulleColorGetComponents(CGColorRef color, CGFloat *components)
{
   components[ 0] = color.r;
   components[ 1] = color.g;
   components[ 2] = color.b;
   components[ 3] = color.a;
}


static inline CGFloat   CGColorGetAlpha( CGColorRef color)
{
   return( color.a);
}


static inline CGColorRef   CGColorDim( CGColorRef color, CGFloat factor)
{
   assert( factor > 0.0 && factor < 1.0);
   color.a = color.a * factor;
   return( color);
}


static inline int   MulleColorIsTransparent( CGColorRef color)
{
   return( color.a < 0.5 / 32767.0);  // assume rounding up and 16 bit color depth
}

static inline int   MulleColorIsOpaque( CGColorRef color)
{
   return( color.a >= 1.0 - 0.5 / 32767.0);  // assume rounding up and 16 bit color depth
}


static inline int   CGColorEqualToColor( CGColorRef color, CGColorRef other)
{
   // CGColorRef is not really a ref..
   return( ! memcmp( &color, &other, sizeof( CGColorRef)));
}


CGColorRef   MulleColorCreateFromCString( char *s);

#endif
