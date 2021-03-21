/* example1.c                                                      */
/*                                                                 */
/* This small program shows how to print a rotated string with the */
/* FreeType 2 library.                                             */
#include "include-private.h"

#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#include <ft2build.h>
#include FT_FREETYPE_H


#define WIDTH   48
#define HEIGHT  48


/* origin is the upper left corner */
unsigned char image[HEIGHT][WIDTH];


/* Replace this function with something useful. */

void
draw_bitmap( FT_Bitmap*  bitmap,
             FT_Int      x,
             FT_Int      y)
{
  FT_Int  i, j, p, q;
  FT_Int  x_max = x + bitmap->width;
  FT_Int  y_max = y + bitmap->rows;


  /* for simplicity, we assume that `bitmap->pixel_mode' */
  /* is `FT_PIXEL_MODE_GRAY' (i.e., not a bitmap font)   */

  for ( i = x, p = 0; i < x_max; i++, p++ )
  {
    for ( j = y, q = 0; j < y_max; j++, q++ )
    {
      if ( i < 0      || j < 0       ||
           i >= WIDTH || j >= HEIGHT )
        continue;

      image[j][i] |= bitmap->buffer[q * bitmap->width + p];
    }
  }
}


void
show_image( int w, int h)
{
  int  i, j;


  if( w > WIDTH)
     w = WIDTH;
  if( h > HEIGHT)
     h = HEIGHT;

  for ( i = 0; i < h; i++ )
  {
    for ( j = 0; j < w; j++ )
      putchar( image[i][j] == 0 ? '.'
                                : image[i][j] < 128 ? '+'
                                                    : '*' );
    putchar( '\n' );
  }
}


//
// SIGNED INTEGER FRACTIONAL CONVERSIONS
//

// GENERIC

static inline int32_t  int32_make_int_fract_generic( int32_t i, uint32_t f, int shift)
{
   assert( f < (0x1 << shift));
   if( i < 0)
      return( (i << shift) | (~f & ((0x1 << shift) - 1)));
   return( (i << shift) | f);
}


static inline int32_t  int32_get_int_generic( int32_t value, int shift)
{
   return( value >> shift);
}


static inline int32_t  int32_get_fract_generic( int32_t value, int shift)
{
   return( (value < 0 ? -value : value) & ((0x1 << shift) - 1));
}


static inline float  int32_get_float_generic( int32_t value, int shift)
{
   return( (float) int32_get_int_generic( value, shift) +
           (float) int32_get_fract_generic( value, shift) / (float) (0x1 << shift));
}

static inline int32_t  float_get_int32_generic( float value, int shift)
{
   float   i;
   float   f;

   i = truncf( value);
   if( value >= 0)
      f = floorf( (value - i) * (0x1 << shift));
   else
      f = floorf( (i - value) * (0x1 << shift));
   return( int32_make_int_fract_generic( (int32_t) i, (uint32_t) f, shift));
}


// 26.6

static inline int32_t  int32_get_int_26_6( int32_t value)
{
   return( int32_get_int_generic( value, 6));
}

static inline int32_t  int32_get_fract_26_6( int32_t value)
{
   return( int32_get_fract_generic( value, 6));
}

static inline float  int32_get_float_26_6( int32_t value)
{
   return( int32_get_float_generic( value, 6));
}

static inline int32_t  float_get_int32_26_6( float value)
{
   return( float_get_int32_generic( value, 6));
}


// 16.16

static inline int32_t  int32_get_int_16_16( int32_t value)
{
   return( int32_get_int_generic( value, 16));
}

static inline int32_t  int32_get_fract_16_16( int32_t value)
{
   return( int32_get_fract_generic( value, 16));
}

static inline float  int32_get_float_16_16( int32_t value)
{
   return( int32_get_float_generic( value, 16));
}

static inline int32_t  float_get_int32_16_16( float value)
{
   return( float_get_int32_generic( value, 16));
}



//
// UNSIGNED INTEGER FRACTIONAL CONVERSIONS
//

// GENERIC

static inline int32_t  uint32_make_int_fract_generic( uint32_t i, uint32_t f, int shift)
{
   assert( (i << shift) >= i);
   assert( f < (0x1 << shift));

   return( (i << shift) | f);
}

static inline uint32_t  uint32_get_int_generic( uint32_t value, int shift)
{
   return( value >> shift);
}


static inline uint32_t  uint32_get_fract_generic( uint32_t value, int shift)
{
   return( value & ((0x1 << shift) - 1));
}


static inline float  uint32_get_float_generic( uint32_t value, int shift)
{
   return( (float) uint32_get_int_generic( value, shift) +
           (float) uint32_get_fract_generic( value, shift) / (float) (0x1 << shift));
}


static inline uint32_t  float_get_uint32_generic( float value, int shift)
{
   float   i;
   float   f;
   assert( value >= 0.0);

   i = floorf( value);
   f = floorf( (value - i) * (0x1 << shift));
   return( uint32_make_int_fract_generic( (uint32_t) i, (uint32_t) f, shift));
}



// 26.6

static inline uint32_t  uint32_get_int_26_6( uint32_t value)
{
   return( uint32_get_int_generic( value, 6));
}

static inline uint32_t  uint32_get_fract_26_6( uint32_t value)
{
   return( uint32_get_fract_generic( value, 6));
}

static inline float  uint32_get_float_26_6( uint32_t value)
{
   return( uint32_get_float_generic( value, 6));
}

static inline uint32_t  float_get_uint32_26_6( float value)
{
   return( float_get_uint32_generic( value, 6));
}


// 16.16


static inline uint32_t  uint32_get_int_16_16( uint32_t value)
{
   return( uint32_get_int_generic( value, 16));
}

static inline uint32_t  uint32_get_fract_16_16( uint32_t value)
{
   return( uint32_get_fract_generic( value, 16));
}

static inline float  uint32_get_float_16_16( uint32_t value)
{
   return( uint32_get_float_generic( value, 16));
}

static inline uint32_t  float_get_uint32_16_16( float value)
{
   return( float_get_uint32_generic( value, 16));
}






int
main( int argc, char**  argv )
{
  FT_Library    library;
  FT_Face       face;
  FT_GlyphSlot  slot;
  FT_Error      error;
  char*         filename;
  int           c;
  float         height;
  float         ascender;
  float         descender;
  float         scale;
  int32_t       value;

  if ( argc != 3)
  {
    fprintf ( stderr, "usage: %s <font> <character>\n", argv[0] );
    exit( 1 );
  }

  filename = argv[1];                           /* first argument     */
  c        = argv[2][ 0];

  error = FT_Init_FreeType( &library );              /* initialize library */
  /* error handling omitted */

  error = FT_New_Face( library, filename, 0, &face );/* create face object */
  /* error handling omitted */

  error = FT_Set_Pixel_Sizes( face, WIDTH, HEIGHT);               /* set character size */
  /* error handling omitted */

  fprintf( stderr, "Font metrics\n");
  fprintf( stderr, "   ascender     : %d.%d\n",
         int32_get_int_26_6( face->ascender),
         int32_get_fract_26_6( face->ascender));
  fprintf( stderr, "   descender    : %d.%d\n",
         int32_get_int_26_6( face->descender),
         int32_get_fract_26_6( face->descender));
  fprintf( stderr, "   height       : %d.%d\n",
         int32_get_int_26_6( face->height),
         int32_get_fract_26_6( face->height));

  // pretty much useless
  fprintf( stderr, "Font Size metrics\n");
  fprintf( stderr, "   ascender     : %d.%d\n",
         int32_get_int_26_6( face->size->metrics.ascender),
         int32_get_fract_26_6( face->size->metrics.ascender));
  fprintf( stderr, "   descender    : %d.%d\n",
         int32_get_int_26_6( face->size->metrics.descender),
         int32_get_fract_26_6( face->size->metrics.descender));
  fprintf( stderr, "   height       : %d.%d\n",
         int32_get_int_26_6( face->size->metrics.height),
         int32_get_fract_26_6( face->size->metrics.height));

  // where is our baseline though ? Need to compute it myself ?
  height     = uint32_get_float_26_6( face->height);
  scale      = HEIGHT / height;

  descender  = int32_get_float_26_6( face->descender);
  descender *= scale;
  ascender   = int32_get_float_26_6( face->ascender);
  ascender  *= scale;

  fprintf( stderr, "Font metrics computed:\n");
  value  = float_get_int32_26_6( ascender);
  fprintf( stderr, "   ascender     : %d.%d\n",
         int32_get_int_26_6( value),
         int32_get_fract_26_6( value));

  value  = float_get_int32_26_6( descender);
  fprintf( stderr, "   descender    : %d.%d\n",
         int32_get_int_26_6( value),
         int32_get_fract_26_6( value));

  /* load glyph image into the slot (erase previous one) */
  error = FT_Load_Char( face, c, FT_LOAD_RENDER);
  if ( error )
    return 1;                 /* ignore errors */

// https://www.freetype.org/freetype2/docs/tutorial/step2.html

  slot = face->glyph;

  fprintf( stderr, "Glyph metrics\n");
  fprintf( stderr, "   width        : %u.%u\n",
         uint32_get_int_26_6( slot->metrics.width),
         uint32_get_fract_26_6( slot->metrics.width));
  fprintf( stderr, "   height       : %u.%u\n",
         uint32_get_int_26_6( slot->metrics.height),
         uint32_get_fract_26_6( slot->metrics.height));
  fprintf( stderr, "   horiBearingX : %d.%d\n",
         int32_get_int_26_6( slot->metrics.horiBearingX),
         int32_get_fract_26_6( slot->metrics.horiBearingX));
  fprintf( stderr, "   horiBearingY : %d.%d\n",
         int32_get_int_26_6( slot->metrics.horiBearingY),
         int32_get_fract_26_6( slot->metrics.horiBearingY));
  fprintf( stderr, "   horiAdvance  : %d.%d\n",
         int32_get_int_26_6( slot->metrics.horiAdvance),
         int32_get_fract_26_6( slot->metrics.horiAdvance));
  fprintf( stderr, "   vertBearingX : %d.%d\n",
         int32_get_int_26_6( slot->metrics.vertBearingX),
         int32_get_fract_26_6( slot->metrics.vertBearingX));
  fprintf( stderr, "   vertBearingY : %d.%d\n",
         int32_get_int_26_6( slot->metrics.vertBearingY),
         int32_get_fract_26_6( slot->metrics.vertBearingY));
  fprintf( stderr, "   vertAdvance  : %d.%d\n",
         int32_get_int_26_6( slot->metrics.vertAdvance),
         int32_get_fract_26_6( slot->metrics.vertAdvance));


  fprintf( stderr, "Glyph metrics computed\n");
  fprintf( stderr, "   descender     : %d.%d\n",
         int32_get_int_26_6( slot->metrics.height - slot->metrics.horiBearingY),
         int32_get_fract_26_6( slot->metrics.height - slot->metrics.horiBearingY));

  draw_bitmap( &slot->bitmap, 0, 0);
  show_image( uint32_get_int_26_6( slot->metrics.width),
              uint32_get_int_26_6( slot->metrics.height));

  putchar( '\n');

  /* try to draw "properly" */
  memset( image, 0, sizeof( image));

  draw_bitmap( &slot->bitmap, slot->bitmap_left, HEIGHT + ceil( descender) - slot->bitmap_top);
  show_image( uint32_get_int_26_6( slot->metrics.horiAdvance),
              HEIGHT);

  putchar( '\n');

/*

  draw_bitmap( &slot->bitmap,
               slot->bitmap_left,
               HEIGHT - slot->bitmap_top);
  show_image();
*/
  FT_Done_Face    ( face );
  FT_Done_FreeType( library );

  return 0;
}

/* EOF */


// y = 36, hY 26  (desc=10)
// i = 38, hY 38  (desc=0)