#ifdef __has_include
# if __has_include( "CGBase.h")
#  include "CGBase.h"
# endif
#endif

#ifdef __has_include
# if __has_include( "MulleEdgeInsets.h")
#  include "MulleEdgeInsets.h"
# endif
#endif


#include "include.h"

#include <string.h>



typedef enum
{
   UIViewContentModeScaleToFill,
   UIViewContentModeScaleAspectFit,
   UIViewContentModeScaleAspectFill,

//   UIViewContentModeRedraw,  // not supported

   UIViewContentModeCenter,

   UIViewContentModeTop,
   UIViewContentModeBottom,
   UIViewContentModeLeft,
   UIViewContentModeRight,

   UIViewContentModeTopLeft,
   UIViewContentModeTopRight,
   UIViewContentModeBottomLeft,
   UIViewContentModeBottomRight
} UIViewContentMode;
#define N_UIViewContentModeNames 12


extern char       *UIViewContentModeNames[ N_UIViewContentModeNames];
char              *UIViewContentModeCStringDescription( UIViewContentMode mode);
UIViewContentMode  UIViewContentModeParseCString( char *s);


static inline CGPoint   MulleRectGetCenter( CGRect rect)
{
   return( CGPointMake( CGRectGetMidX( rect), CGRectGetMidY( rect)));
}

// MulleSize_CenterInRect lesbarer ?
static inline CGPoint   MulleSizeGetCenterInRect( CGSize size, CGRect rect)
{
   CGPoint   origin;

   origin.x = CGRectGetMidX( rect) - size.width / 2.0;
   origin.y = CGRectGetMidY( rect) - size.height / 2.0;

   return( origin);
}

CGFloat   MulleSizeGetAspectFitFactor( CGSize dstSize, CGSize srcSize);
CGFloat   MulleSizeGetAspectFillFactor( CGSize dstSize, CGSize srcSize);

CGRect  MulleSizeAspectLayoutInRect( CGSize size, CGRect rect, BOOL fill);

//
// a rect of a certain size is positioned and possibly stretched into a
// given frame using contentMode. If the size is larger than the frame
// it may overlap (or shrink)
//
CGRect   MulleSizeApplyContentModeInRect( CGSize size,
                                          UIViewContentMode contentMode,
                                          CGRect rect);


//void   MulleRectSplitVertically( CGRect frame, CGRect *frame1, CGRect *frame2)
//void   MulleRectSplitHorizontally( CGRect frame, CGRect *frame1, CGRect *frame2);

//
// take frame and partition into 'n' equal sized rects and spaced apart rects
// n must be >= 1.
//
void   MulleRectPartititonVertically( CGRect frame, NSUInteger n, CGRect *rects, CGFloat space);
void   MulleRectPartititonHorizontally( CGRect frame, NSUInteger n, CGRect *rects, CGFloat space);


//
// Basically follow the definitions set in here
// https://yogalayout.com/
// except we don't do padding (which is insets used by UIView for the content)
// The margin handling is different, in that we merge margins.
// i.e. ---| |----   will be a distance of 20 and not of 30 like in Yoga
//       10   20
//

// keep this simple.. any additional layouting like centering or justifying
// should be done in a second pass

struct MulleLayout
{
   CGRect            originalRect;
   MulleEdgeInsets   originalMargins;

   CGRect            rect;      // growing rect of the current row
   MulleEdgeInsets   margins;  // growing margins of the current row

   CGFloat           maxMarginY;
};


static inline void  _MulleLayoutInitWithRect( struct MulleLayout *p,
                                              CGRect rect,
                                              MulleEdgeInsets margins)
{
   // read only (in algorithm)
   p->originalRect    = rect;
   p->originalMargins = margins;

   p->rect.origin     = rect.origin;
   p->rect.size       = CGSizeMake( 0, 0);
   p->margins         = margins;
}


static inline void  _MulleLayoutDone( struct MulleLayout *p)
{
}


static inline void  MulleLayoutDone( struct MulleLayout *p)
{
}


//
// +++.......
// + +   ++ .
// +++   ++ .
// .........+
//
// ###
// # #
// ###

static inline CGSize  _MulleLayoutGetRemainingRowSize( struct MulleLayout *p)
{
   CGSize   size;

   size.width  = CGRectGetMaxX( p->originalRect) - (CGRectGetMaxX( p->rect) + p->margins.right);
   size.height = CGRectGetMaxY( p->originalRect) - (CGRectGetMaxY( p->rect) + p->margins.bottom);

   return( size);
}


// Each row starts at 0,0. The origin is added to the returned rect on return.
// When a row is done, the height of the row is added to the origin.
//
// +-------------------+
// |                   |
// +-------------------+
//
static inline void   _MulleLayoutNewRow( struct MulleLayout *p)
{
   p->margins.top    = p->originalMargins.top > p->margins.bottom
                         ? p->originalMargins.top
                         : p->margins.bottom;
   p->margins.bottom = p->originalMargins.bottom;
   p->margins.left   = p->originalMargins.left;
   p->margins.right  = p->originalMargins.right;

   p->rect.origin.x  = p->originalRect.origin.x;
   p->rect.origin.y += p->rect.size.height;
   p->rect.size      = CGSizeZero;
}


//
// Straightforward, except when space runs out. The margin handling is also
// a bit complicated. Size doesn't fit, if there isn't room enough for margins,
// which is also the right edge of the space. The larger margin wins.
// Returns zerosized rect, if it doesn't fit. Does not attempt to change 'y'
//
CGRect   _MulleLayoutAddToRow( struct MulleLayout *p,
                               CGSize size,
                               MulleEdgeInsets margins);

CGRect   _MulleLayoutAddToRowWithOverflow( struct MulleLayout *p,
                                           CGSize size,
                                           MulleEdgeInsets margins);


// so adjust x, so that centers align
static inline CGRect   MulleRectAlignCenterInColumn( CGRect rect,
                                                     CGPoint otherCenter)
{
   rect.origin.x += otherCenter.x - CGRectGetMidX( rect);
   return( rect);
}


static inline CGRect   MulleRectAlignCenterInRow( CGRect rect,
                                                  CGPoint otherCenter)
{
   rect.origin.y += otherCenter.y - CGRectGetMidY( rect);
   return( rect);
}


//
//    Up
//    Down
//    Left
//    Right
//
enum MulleLayoutVerticalPlacement
{
   MulleLayoutPlacementKeepY         = 0,    // aligns bottom of rect with other top
   MulleLayoutPlacementUp            = 1,    // aligns bottom of rect with other top
   MulleLayoutPlacementDown          = 2,    // aligns top of rect with other bottom
   MulleLayoutPlacementMiddle        = 3,    // aligns middle (H) of rect with other middle
   MulleLayoutPlacementTopAligned    = 4,    // aligns bottom of rect with other top
   MulleLayoutPlacementBottomAligned = 5,    // aligns bottom of rect with other top
};

enum MulleLayoutHorizontalPlacement
{
   MulleLayoutPlacementKeepX         = 0,    // aligns bottom of rect with other top
   MulleLayoutPlacementLeft          = 1,    // aligns right edge of rect with other left
   MulleLayoutPlacementRight         = 2,    // aligns left edge of rect with other right
   MulleLayoutPlacementCenter        = 3,    // aligns center (V) of rect with other center
   MulleLayoutPlacementLeftAligned   = 4,    // aligns left edge of rect with other left
   MulleLayoutPlacementRightAligned  = 5    // aligns right edge of rect with other right
};

typedef NSUInteger    MulleLayoutPlacement;

static inline  MulleLayoutPlacement
   MulleLayoutPlacementMake( enum MulleLayoutHorizontalPlacement h,
                             enum MulleLayoutVerticalPlacement v)
{
   return( (NSUInteger) h << 4 | v);
}

static inline enum MulleLayoutVerticalPlacement
   MulleLayoutPlacementGetVerticalPlacement( MulleLayoutPlacement value)
{
   return( value & 0xF);
}

static inline enum MulleLayoutHorizontalPlacement
   MulleLayoutPlacementGetHorizontalPlacement( MulleLayoutPlacement value)
{
   return( value >> 4);
}


static inline CGPoint   MullePlaceRectNextToRect( CGRect rect,
                                                  CGRect other,
                                                  MulleLayoutPlacement placement)
{
   CGPoint      origin;
   NSUInteger   hAxis;
   NSUInteger   vAxis;

   assert( placement <= MulleLayoutPlacementMake( MulleLayoutPlacementRightAligned,
                                                  MulleLayoutPlacementBottomAligned));

   switch( MulleLayoutPlacementGetHorizontalPlacement( placement))
   {
   default :
      origin.x = rect.origin.x;
      break;

   case MulleLayoutPlacementLeft :
      origin.x = CGRectGetMinX( other) - rect.size.width;
      break;

   case MulleLayoutPlacementRight :
      origin.x = CGRectGetMaxX( other);
      break;

   case MulleLayoutPlacementMiddle :
      origin.x = CGRectGetMidX( other) - rect.size.width / 2;
      break;

   case MulleLayoutPlacementLeftAligned :
      origin.x = other.origin.x;
      break;

   case MulleLayoutPlacementRightAligned :
      origin.x =  CGRectGetMaxX( other) - rect.size.width;
      break;
   }

   switch( MulleLayoutPlacementGetVerticalPlacement( placement))
   {
   default :
      origin.y = rect.origin.y;
      break;

   case MulleLayoutPlacementUp :
      origin.y = CGRectGetMinY( other) - rect.size.height;
      break;

   case MulleLayoutPlacementDown :
      origin.y = CGRectGetMaxY( other);
      break;

   case MulleLayoutPlacementCenter :
      origin.y = CGRectGetMidY( other) - rect.size.height / 2;
      break;

   case MulleLayoutPlacementTopAligned :
      origin.y = other.origin.y;
      break;

   case MulleLayoutPlacementBottomAligned :
      origin.y =  CGRectGetMaxY( other) - rect.size.height;
      break;
   }

   return( origin);
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
                                           NSInteger fallback);

// TODO: more to come...