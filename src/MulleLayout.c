#include "MulleLayout.h"

#include "include-private.h"

CGRect   _MulleLayoutAddToRowWithOverflow( struct MulleLayout *p,
                                           CGSize size,
                                           MulleEdgeInsets margins)
{
   CGRect   rect;

   rect = _MulleLayoutAddToRow( p, size, margins);
   if( rect.size.width != 0.0)
      return( rect);

   _MulleLayoutNewRow( p);
   rect = _MulleLayoutAddToRow( p, size, margins);
   return( rect);
}


//
// +++++
// +++++  ++++
//        ++++
//
// this will produce the amount to scale srcSize in both dimensions
// so that everything remains visible in the same aspect
//
CGFloat   MulleSizeGetAspectFitFactor( CGSize dstSize, CGSize srcSize)
{
   CGFloat   srcAspectScale;
   CGFloat   dstAspectScale;

   srcAspectScale = srcSize.width / srcSize.height;
   dstAspectScale = dstSize.width / dstSize.height;

   if( srcAspectScale < dstAspectScale)
      return( dstSize.height / srcSize.height);
   return( dstSize.width / srcSize.width);
}


CGFloat   MulleSizeGetAspectFillFactor( CGSize dstSize, CGSize srcSize)
{
   CGFloat   srcAspectScale;
   CGFloat   dstAspectScale;

   srcAspectScale = srcSize.width / srcSize.height;
   dstAspectScale = dstSize.width / dstSize.height;

   if( srcAspectScale > dstAspectScale)
      return( dstSize.height / srcSize.height);
   return( dstSize.width / srcSize.width);
}


CGRect  MulleSizeAspectLayoutInRect( CGSize size, CGRect rect, BOOL fill)
{
   CGFloat  aspectScale;
   CGRect   result;

   if( size.height == 0.0 || size.width == 0.0  || rect.size.height == 0.0)
      return( CGRectZero);

   if( fill)
      aspectScale = MulleSizeGetAspectFillFactor( rect.size, size);
   else
      aspectScale = MulleSizeGetAspectFitFactor( rect.size, size);

   result.size.width  = size.width * aspectScale;
   result.size.height = size.height * aspectScale;
   // now center
   result.origin.x = CGRectGetMidX( rect) - result.size.width / 2.0;
   result.origin.y = CGRectGetMidY( rect) - result.size.height / 2.0;
   return( result);
}

CGRect   MulleSizeApplyContentModeInRect( CGSize size,
                                          UIViewContentMode contentMode,
                                          CGRect rect)
{
   CGRect   result;
   CGFloat  aspectScale;

   switch( contentMode)
   {
   case UIViewContentModeScaleToFill :
      return( rect);

   case UIViewContentModeScaleAspectFit :
      return( MulleSizeAspectLayoutInRect( size, rect, NO));

   case UIViewContentModeScaleAspectFill :
      return( MulleSizeAspectLayoutInRect( size, rect, YES));

   case UIViewContentModeCenter :
      result.origin.x = CGRectGetMidX( rect) - size.width / 2.0;
      result.origin.y = CGRectGetMidY( rect) - size.height / 2.0;
      result.size     = size;
      return( result);

   case UIViewContentModeTop :
      result.origin.x = CGRectGetMidX( rect) - size.width / 2.0;
      result.origin.y = rect.origin.y;
      result.size     = size;
      return( result);

   case UIViewContentModeBottom :
      result.origin.x = CGRectGetMidX( rect) - size.width / 2.0;
      result.origin.y = CGRectGetMaxY( rect) - size.height;
      result.size     = size;
      return( result);

   case UIViewContentModeLeft :
      result.origin.x = rect.origin.x;
      result.origin.y = CGRectGetMidY( rect) - size.height / 2.0;
      result.size     = size;
      return( result);

   case UIViewContentModeRight :
      result.origin.x = CGRectGetMaxX( rect) - size.width;
      result.origin.y = CGRectGetMidY( rect) - size.height / 2.0;
      result.size     = size;
      return( result);

   case UIViewContentModeTopLeft :
      result.origin = rect.origin;
      result.size   = size;
      return( result);

   case UIViewContentModeTopRight :
      result.origin.x = CGRectGetMaxX( rect) - size.width;
      result.origin.y = rect.origin.y;
      result.size     = size;
      return( result);

   case UIViewContentModeBottomLeft :
      result.origin.x = rect.origin.x;
      result.origin.y = CGRectGetMaxY( rect) - size.height;
      result.size     = size;
      return( result);

   case UIViewContentModeBottomRight :
      result.origin.x = CGRectGetMaxX( rect) - size.width;
      result.origin.y = CGRectGetMaxY( rect) - size.height;
      result.size     = size;
      return( result);
   }
   abort();
}


char  *UIViewContentModeNames[] =
{
   "UIViewContentModeScaleToFill",
   "UIViewContentModeScaleAspectFit",
   "UIViewContentModeScaleAspectFill",
//   "UIViewContentModeRedraw",
   "UIViewContentModeCenter",
   "UIViewContentModeTop",
   "UIViewContentModeBottom",
   "UIViewContentModeLeft",
   "UIViewContentModeRight",
   "UIViewContentModeTopLeft",
   "UIViewContentModeTopRight",
   "UIViewContentModeBottomLeft",
   "UIViewContentModeBottomRight",
};


char  *UIViewContentModeCStringDescription( UIViewContentMode mode)
{
   assert( mode >= UIViewContentModeScaleToFill && mode <= UIViewContentModeBottomRight);
   return( UIViewContentModeNames[ mode]);
}


UIViewContentMode  UIViewContentModeParseCString( char *s)
{
   char     **name;
   char     **sentinel;
   char     *p;
   size_t   len;
   char     *prefix;

   // don't compare common prefix all the time
   prefix = "UIViewContentMode";
   len = strlen( prefix);
   if( strncmp( s, prefix, len))
      return( -1);
   s = &s[ len];

   name = UIViewContentModeNames;
   sentinel = &name[ N_UIViewContentModeNames];
   while( name < sentinel)
   {
      p = &(*name)[ len];
      if( ! strcmp( s, p))
         return( (int) (name - UIViewContentModeNames));
      ++name;
   }
   return( -1);
}

//
// void   MulleRectSplitVertically( CGRect frame, CGRect *frame1, CGRect *frame2)
// {
//    frame1->origin      = frame.origin;
//    frame1->size.width  = frame.size.width;
//    frame1->size.height = frame.size.height / 2.0;
//
//    frame2->origin.x    = frame.origin.x;
//    frame2->origin.y    = frame.origin.y + frame1->size.height;
//    frame2->size        = frame1->size;
// }


void   MulleRectPartititonVertically( CGRect frame,
                                      NSUInteger n,
                                      CGRect *rects,
                                      CGFloat space)
{
   CGRect  *p;
   CGRect  *q;
   CGRect  *sentinel;

   assert( n);

   q              = rects;
   q->origin      = frame.origin;
   q->size.width  = frame.size.width;
   q->size.height = (frame.size.height - (n - 1) * space) / n;

   p        = q + 1;
   sentinel = &q[ n];
   while( p < sentinel)
   {
      p->origin.x = frame.origin.x;
      p->origin.y = CGRectGetMaxY( *q) + space;
      p->size     = rects->size;

      q = p;
      ++p;
   }
}

//
// void   MulleRectSplitHorizontally( CGRect frame, CGRect *frame1, CGRect *frame2)
// {
//    frame1->origin      = frame.origin;
//    frame1->size.width  = frame.size.width / 2.0;
//    frame1->size.height = frame.size.height;
//
//    frame2->origin.x    = frame.origin.x + frame1->size.width;
//    frame2->origin.y    = frame.origin.y;
//    frame2->size        = frame1->size;
// }
//

void   MulleRectPartititonHorizontally( CGRect frame,
                                        NSUInteger n,
                                        CGRect *rects,
                                        CGFloat space)
{
   CGRect  *p;
   CGRect  *q;
   CGRect  *sentinel;

   assert( n);

   q              = rects;
   q->origin      = frame.origin;
   q->size.width  = (frame.size.width - (n - 1) * space) / n;
   q->size.height = frame.size.height;

   p        = q + 1;
   sentinel = &q[ n];
   while( p < sentinel)
   {
      p->origin.x =  CGRectGetMaxX( *q) + space;
      p->origin.y = frame.origin.y;
      p->size     = rects->size;

      q = p;
      ++p;
   }
}


//
// position rect at either side of other, if space fits.
// Gives a list of MulleLayoutPlacement and they are tried until something
// fits.
//
CGPoint   MullePlaceRectNextToRectInSpace( CGRect rect,
                                           CGRect other,
                                           CGRect space,
                                           NSUInteger n_preferences,
                                           unsigned char *preferences,
                                           NSInteger fallback)

{
   unsigned char   *p;
   unsigned char   *sentinel;
   CGRect          placed;

   assert( n_preferences);
   assert( fallback < 0 || fallback < n_preferences);

   p        = preferences;
   sentinel = &p[ n_preferences];

   placed.size = rect.size;
   while( p < sentinel)
   {
      placed.origin = MullePlaceRectNextToRect( rect, other, *p);
      if( CGRectContainsRect( space, placed))
         return( placed.origin);
      ++p;
   }
   if( fallback >= 0)
      return( MullePlaceRectNextToRect( rect, other, preferences[ fallback]));

   return( CGPointMake( CGFLOAT_MIN, CGFLOAT_MIN));
}


CGRect   _MulleLayoutAddToRow( struct MulleLayout *p,
                               CGSize size,
                               MulleEdgeInsets margins)
{
   CGRect    rect;
   CGFloat   margin;

   rect.size   = size;

   margins.top = margins.top > p->margins.top
                     ? margins.top
                     : p->margins.top;

   rect.origin.y = CGRectGetMinY( p->rect) + margins.top;
   if( CGRectGetMaxY( rect) > CGRectGetMaxY( p->originalRect))
      return( CGRectZero);

   margins.left = margins.left > p->margins.right
                     ? margins.left
                     : p->margins.right;
   rect.origin.x = CGRectGetMaxX( p->rect) + margins.left;

   //
   // check that we don't extend over space, we only check against original
   // margins here, so that we can use the full "usable" width
   // The right margin of the rect is ignored.... hmmmm
   //
   if( CGRectGetMaxX( rect) > CGRectGetMaxX( p->originalRect) - p->originalMargins.right)
      return( CGRectZero);

   // left margin is now "fixed" and can be subtracted
   p->margins.right = p->originalMargins.right > margins.right
                         ? p->originalMargins.right
                         : margins.right;

   // we keep track of the maximum Y extents of the margins,
   // NOT the largest margin per se
   if( CGRectGetMaxY( rect) + margins.bottom > CGRectGetMaxY( p->rect) + p->margins.bottom)
      p->margins.bottom = margins.bottom;

   p->rect = CGRectUnion( p->rect, rect);
   return( rect);
}
