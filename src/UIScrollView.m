#import "UIScrollView.h"

#import "CGContext.h"
#import "CGGeometry+CString.h"
#import "UIView+CGGeometry.h"
#import "UIView+Layout.h"
#import "UIView+UIEvent.h"
#import "UIView+UIResponder.h"
#import "UIView+Yoga.h"
#import "UIEvent.h"
#import "UIEdgeInsets.h"
#import "UIWindow.h"
#import "MulleScrollIndicatorView.h"


// #define LAYOUT_DEBUG
// #define EVENT_DEBUG
//#define MOMENTUM_DEBUG

#define SCROLLER_WIDTH			      8
#define SCROLLER_OFFSET_START    	8
#define SCROLLER_OFFSET_END	      (SCROLLER_WIDTH + SCROLLER_OFFSET_START * 1.5)
#define SCROLLER_OFFSET_END_ALONE	SCROLLER_WIDTH


@implementation UIScrollView

// UICollectionView wants to use a different view here
+ (UIScrollContentView *) mulleScrollContentsViewWithFrame:(CGRect) frame
{
   UIScrollContentView   *view;

   view = [UIScrollContentView  viewWithFrame:frame];
   [view setDebugNameCString:"ScrollViewContentView"];
   return( view);
}


- (id) initWithLayer:(CALayer *) layer
               frame:(CGRect) frame
{
   CGRect   frame;
   CGRect   rect;
   Class    cls;

   assert( ! layer || [layer isKindOfClass:[CALayer class]]);

   self = [super initWithLayer:layer
                         frame:frame];

   // default values
   _showsHorizontalScrollIndicator = YES;
   _showsVerticalScrollIndicator   = YES;

/*
   the code depends on the layout being called before the render at least
   once
 */
   rect.origin = CGPointZero;
   rect.size   = frame.size;

   cls          = [self class];
   _contentView = [cls mulleScrollContentsViewWithFrame:rect];
   [_contentView setClipsToBounds:YES];
	[self addSubview:_contentView];

   // hide, and show after relayout
   _horIndicatorView = [[MulleScrollIndicatorView alloc] initWithFrame:CGRectZero];
//   [_horIndicatorView setUserInteractionEnabled:YES];
	[self mulleAddRetainedSubview:_horIndicatorView];

   _verIndicatorView = [[MulleScrollIndicatorView alloc] initWithFrame:CGRectZero];
//   [_verIndicatorView setUserInteractionEnabled:YES];
	[self mulleAddRetainedSubview:_verIndicatorView];

	[self setNeedsLayout];
   // for right drags it doesn't feel right
   // _clickOrDrag._mouseMotionSuppressionDelay = [[self class] mouseMotionSuppressionDelay];

   return( self);
}

// remove as window delegate via setMomentum...
- (void) finalize
{
   [self setMomentum:CGPointZero
           timestamp:0];
   [super finalize];
}


- (CGPoint) zoomFactor
{
   CGRect   contentBounds;
   CGSize   contentSize;
   CGPoint  zoomFactor;

   if( ! _zoomEnabled)
      return( CGPointMake( 1.0, 1.0));

   contentBounds = [_contentView bounds];

   if( contentBounds.size.width <= 0.1 || contentBounds.size.height <= 0.1)
      return( CGPointMake( 0.0, 0.0));

   // the current scroll factor
   contentSize  = [_contentView contentSize];

   zoomFactor.x = contentSize.width / contentBounds.size.width;
   zoomFactor.y = contentSize.height / contentBounds.size.height;

   return( zoomFactor);
}


//
// implicitly resets the zoom back to 1.0 and sets the bounds
// if this is not desired, get old zoomFactor and reset afterwards
//
- (void) setContentSize:(CGSize) size
{
   [_contentView setContentSize:size];
}

// passed to contentView
- (void) setContentOffset:(CGPoint) offset
{
   [_contentView setContentOffset:offset];
}

- (void) scrollContentOffsetBy:(CGPoint) diff
{
   [_contentView scrollContentOffsetBy:diff];
}

- (CGPoint) contentOffset
{
   return( [_contentView contentOffset]);
}


- (CGSize) contentSize
{
   return( [_contentView contentSize]);
}


- (UIScrollContentView *) contentView  // subview index #0
{
	return( _contentView);
}


- (UIView *) horizontalScrollIndicatorView  // subview index #n - 2
{
	return( _horIndicatorView);
}


- (UIView *) verticalScrollIndicatorView    // subview index #n - 1
{
	return( _verIndicatorView);
}


#define HZ60         (1.0/60.0)
#define DRAGFACTOR   0.95

- (BOOL) setMomentum:(CGPoint) momentum
           timestamp:(CAAbsoluteTime) timestamp
{
   BOOL   hadMomentum;
   BOOL   haveMomentum;
   
   hadMomentum  = _momentum.x != 0.0 || _momentum.y != 0.0;
   haveMomentum = momentum.x != 0.0 || momentum.y != 0.0;

#ifdef MOMENTUM_DEBUG
   fprintf( stderr, "momentum (%s) %s -> (%s) %s\n",
                        CGPointCStringDescription( _momentum),
                        hadMomentum ? "YES" : "NO",
                        CGPointCStringDescription( momentum),
                        haveMomentum ? "YES" : "NO");
#endif

   _momentum          = momentum;
   _momentumTimestamp = timestamp;
   if( ! haveMomentum)
   {
      if( hadMomentum)
         [[self window] removeFromDelegateViews:self];
      [self setupIndicatorViews]; // one more time
   }
   else
      if( ! hadMomentum)
         [[self window] addToDelegateViews:self];

   return( haveMomentum);
}


- (BOOL) applyMomentumToContentWithAbsoluteTime:(CAAbsoluteTime) now
{
	CGPoint          offset;
	CGPoint          newOffset;
   CAAbsoluteTime   now;
   CGPoint          momentum;
   CGFloat          diff;
   CGFloat          friction;
   BOOL             haveMomentum;

   diff = CATimeSubtract( now, _momentumTimestamp);

   // 1/60 = 0.166  so if our last render was 0.0s before, we use 1.0
   //                  if the last render was 0.166s before,we use 0.95
   //                  interpolate other numbers

   // diff is 0        : friction is 1
   // diff is 0.5/60.0 : friction is (1-0.95) * diff + 0.95
   // diff is 1.0/60.0 : friction is 0.95
   // diff is 2.0/60.0 : friction is (1-0.95) * diff + 0.95

   diff     = diff / HZ60;
   friction = 1 - (1 - DRAGFACTOR) * diff;

   momentum.x = _momentum.x * friction;
   momentum.y = _momentum.y * friction;
   if( fabs( momentum.x) < 0.01)
      momentum.x = 0.0;
   if( fabs( momentum.y) < 0.01)
      momentum.y = 0.0;

#ifdef MOMENTUM_DEBUG
   if( momentum.x != 0.0 || momentum.y != 0.0)
      fprintf( stderr, "momentum: %.2f,%.2f [d:%.4f f:%.4f] @%.4f\n",
                                    momentum.x, momentum.y,
                                    diff, friction,
                                    CAAbsoluteTimeNow());
#endif

   haveMomentum = [self setMomentum:momentum
                          timestamp:now];
   if( haveMomentum)
   {
   	offset      = [_contentView contentOffset];
      newOffset.x = offset.x + momentum.x;
      newOffset.y = offset.y + momentum.y;

      offset = [_contentView clampedContentOffset:newOffset];
      [_contentView setContentOffset:offset];
   }
   return( haveMomentum);
}


- (BOOL) setupIndicatorViews
{
	CGPoint   contentOffset;
	CGSize    contentSize;
   CGRect    bounds;
   BOOL      wasHiddenH;
   BOOL      wasHiddenV;
   BOOL      isHiddenH;
   BOOL      isHiddenV;

   // TODO: this should be the frameInfo now!
   contentSize   = [_contentView contentSize];
   contentOffset = [_contentView contentOffset];
	bounds        = [_contentView bounds]; 

	[_horIndicatorView setBubbleOffset:contentOffset.x];
	[_horIndicatorView setBubbleLength:bounds.size.width];
	[_horIndicatorView setContentLength:contentSize.width];
   //
   // don't paint scrollbar if content fits inside scrollView
   //
   wasHiddenH = [_horIndicatorView isHidden];
   isHiddenH = ! _showsHorizontalScrollIndicator;
   if( bounds.size.width >= contentSize.width)
      isHiddenH = YES;
   [_horIndicatorView setHidden:isHiddenH];

	[_verIndicatorView setBubbleOffset:contentOffset.y];
	[_verIndicatorView setBubbleLength:bounds.size.height];
	[_verIndicatorView setContentLength:contentSize.height];

   wasHiddenV = [_verIndicatorView isHidden];
   isHiddenV = ! _showsVerticalScrollIndicator;
   if( bounds.size.height >= contentSize.height)
      isHiddenV = YES;
   [_verIndicatorView setHidden:isHiddenV];

   if( isHiddenH ^ wasHiddenH || isHiddenV ^ wasHiddenV)
      return(YES);
   return( NO);
}


- (void) willRenderWithAbsoluteTime:(CAAbsoluteTime) now
{
   fprintf( stderr, "%s %.5f\n", __PRETTY_FUNCTION__, now);
   
   // MEMO: setupIndicatorViews needs to run also, when ContentOffset has
   //       changed or ContentSize has changes, but
   //       applyMomentumToContentWithAbsoluteTime doesn't really know about
   //       this.
   [self applyMomentumToContentWithAbsoluteTime:now];
   [self setupIndicatorViews];
   [self setNeedsLayout];
}


// TODO: if there is only a vertical indicator, enlarge it so that it takes
//       up empty space otherwise used by the horizontal indicator
- (void) layoutSubviews
{
	CGRect         bounds;
	CGRect         horFrame;
	CGRect         verFrame;
	CGRect         contentViewFrame;
	CGFloat        offset;
	UIEdgeInsets   insets;
   CGFloat        end;

	bounds = [self layoutRect];

#ifdef LAYOUT_DEBUG
   fprintf( stderr, "%s %s bounds: %s\n",
   					__PRETTY_FUNCTION__,
                  [self cStringDescription],
                  CGRectCStringDescription( bounds));
#endif

//
// determined solely by contentSize/offset and own bounds
// putting margins on the contentView is not a good thing though
//
	[_contentView setFrame:bounds];

   end = SCROLLER_OFFSET_END;
   if( [_horIndicatorView isHidden] || [_verIndicatorView isHidden])
      end = SCROLLER_OFFSET_END_ALONE;

	// currently these scrollers are 8 pixel wide and 4 pixels offset
	// the 6.0 is so that scrollers don't overlap if both are visible
	insets   = UIEdgeInsetsMake( 0.0, SCROLLER_OFFSET_START, SCROLLER_OFFSET_START, end);
	horFrame = UIEdgeInsetsInsetRect( bounds, insets);

	horFrame.origin.y    = horFrame.size.height + horFrame.origin.y - SCROLLER_WIDTH;
	horFrame.size.height = SCROLLER_WIDTH ;

#ifdef LAYOUT_DEBUG
   fprintf( stderr, "%s %s bounds: %s\n",
   					__PRETTY_FUNCTION__,
                  [_horIndicatorView cStringDescription],
                  CGRectCStringDescription( horFrame));
#endif
	[_horIndicatorView setFrame:horFrame];

	insets   = UIEdgeInsetsMake( SCROLLER_OFFSET_START, 0.0, end, SCROLLER_OFFSET_START);
	verFrame = UIEdgeInsetsInsetRect( bounds, insets);

	verFrame.origin.x   = verFrame.size.width + verFrame.origin.x - SCROLLER_WIDTH;
	verFrame.size.width = SCROLLER_WIDTH;

#ifdef LAYOUT_DEBUG
   fprintf( stderr, "%s %s bounds: %s\n",
   					__PRETTY_FUNCTION__,
                  [_verIndicatorView cStringDescription],
                  CGRectCStringDescription( verFrame));
#endif
	[_verIndicatorView setFrame:verFrame];

   [_contentView layoutSubviews];
   [_horIndicatorView layoutSubviews];
   [_verIndicatorView layoutSubviews];
}

- (void) layout 
{
   [self setupIndicatorViews];
   [super layout];
}


- (void) scrollRectToVisible:(CGRect) rect
                    animated:(BOOL) animated
{
}

@end


@implementation UIScrollContentView : UIView


- (instancetype) initWithLayer:(CALayer *) layer
                         frame:(CGRect) frame
{
   [super initWithLayer:layer
                frame:frame];

   _contentSize = frame.size;
   return( self);
}


- (void) layoutLayer:(CALayer *) layer
              inRect:(CGRect) rect
{
   fprintf( stderr, "layout...\n");
   if( layer == _mainLayer)
   {
      [layer setFrame:rect];
      [layer setBounds:[self bounds]];
   }
}


- (CGRect) contentRect
{
   return( CGRectMake( 0.0f, 0.0f, _contentSize.width, _contentSize.height));
}


- (CGPoint) contentOffset
{
//   CGPoint   offset;
//
//   offset    = _bounds.origin;
//   offset.x *= -1.0;
//   offset.y *= -1.0;
   return( _bounds.origin);
}


- (void) setContentOffset:(CGPoint) offset
{
   _bounds.origin = offset;
   [[self layer] setBounds:[self bounds]];

//   _bounds.origin.x = offset.x * -1.0;
//   _bounds.origin.y = offset.y * -1.0;
//   [[self superview] setNeedsLayout];
}


- (CGPoint) clampedContentOffset:(CGPoint) offset
{
	CGPoint   newOffset;
   CGSize    size;
   CGRect    bounds;

   bounds  = [self bounds];
   size    = CGSizeMake( _contentSize.width - bounds.size.width,
                         _contentSize.height - bounds.size.height);
   newOffset = MulleCGPointClampToSize( offset, size);
   return( newOffset);
}


- (void) scrollContentOffsetBy:(CGPoint) diff
{
	CGPoint   offset;
	CGPoint   newOffset;

   offset      = [self contentOffset];
	newOffset.x = offset.x + diff.x;
	newOffset.y = offset.y + diff.y;
	offset      = [self clampedContentOffset:newOffset];
   [self setContentOffset:offset];
}


- (CGRect) clampedBounds:(CGRect) bounds
{
   CGRect   frame;
   CGRect   oldBounds;
   CGPoint  zoomFactor;
   CGPoint  minZoom;
   CGSize   contentSize;

   oldBounds = [self bounds];
   if( bounds.size.width <= 1.0 || bounds.size.height <= 1.0)
      return( oldBounds);

   contentSize = [self contentSize];
   if( contentSize.width <= 1.0 || contentSize.height <= 1.0)
      return( oldBounds);

   frame        = [self frame];
   zoomFactor.x = frame.size.width / bounds.size.width;
   zoomFactor.y = frame.size.height / bounds.size.height;

   minZoom.x = frame.size.width / contentSize.width;
   minZoom.y = frame.size.height / contentSize.height;

#ifdef DEBUG
   fprintf( stderr, "zoomFactor: %s\n", CGPointCStringDescription( zoomFactor));
   fprintf( stderr, "minZoom: %s\n", CGPointCStringDescription( minZoom));
#endif

   if( zoomFactor.x <= minZoom.x || zoomFactor.y <= minZoom.y)
      return( oldBounds);

   return( bounds);
}


//
// point is within { { 0, 0}, contentSize }
//
- (void) centerOnPoint:(CGPoint) point
{
   CGPoint   contentOffset;
   CGRect    bounds;

   bounds          = [self bounds];

   // center mouse in the middle of the screen
   contentOffset.x = point.x - bounds.size.width / 2.0;
   contentOffset.y = point.y - bounds.size.height / 2.0;

   contentOffset = [self clampedContentOffset:contentOffset];
   [self setContentOffset:contentOffset];
}

@end
