#import "UIView.h"

#import "UIEdgeInsets.h"

#import "CGGeometry+CString.h"


/*
 * The scrollable content (views) of a UIScrollview is actually contained
 * and managed by it's UIScrollContentView. That way the UIScrollview can
 * have non-scrollable views like the MulleScrollIndicatorViews on top.
 *
 *
 *     UIScrollView
 *    .---------------------------------------.
 *    |.---------------------------------.---.|
 *    || UIScrollContentView             | M ||
 *    ||  .---.                          | u ||
 *    ||  |   |     .---.                | l ||
 *    ||  '---'     |   |                | l ||
 *    ||            '---'                | e ||
 *    ||                                 | S ||
 *    ||                                 | c ||
 *    ||                                 | r ||
 *    ||                                 | o ||
 *    ||                                 | l ||
 *    ||                                 | l ||
 *    ||                                 | . ||
 *    |.--------------------------------.| . ||
 *    || MulleScrollIndicatorView       || . ||
 *    |'--------------------------------''---'|
 *    '---------------------------------------'
 *
 */
@class UIScrollContentView;
@class UIScrollView;
@class MulleScrollIndicatorView;

@protocol UIScrollViewDelegate

@optional
- (void) scrollViewDidScroll:(UIScrollView *) scrollView;
- (void) scrollViewDidZoom:(UIScrollView *) scrollView;
- (void) scrollViewWillBeginDragging:(UIScrollView *) scrollView;
- (void) scrollViewWillEndDragging:(UIScrollView *) scrollView
                      withVelocity:(CGPoint) velocity
               targetContentOffset:(CGPoint *) targetContentOffset;
- (void) scrollViewDidEndDragging:(UIScrollView *) scrollView
                   willDecelerate:(BOOL)decelerate;
- (void) scrollViewWillBeginDecelerating:(UIScrollView *) scrollView;
- (void) scrollViewDidEndDecelerating:(UIScrollView *) scrollView;
- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *) scrollView;
- (UIView *) viewForZoomingInScrollView:(UIScrollView *) scrollView;
- (void) scrollViewWillBeginZooming:(UIScrollView *) scrollView
                           withView:(UIView *) view;
- (void) scrollViewDidEndZooming:(UIScrollView *) scrollView
                        withView:(UIView *) view
                         atScale:(CGFloat) scale;
- (BOOL) scrollViewShouldScrollToTop:(UIScrollView *) scrollView;
- (void) scrollViewDidScrollToTop:(UIScrollView *) scrollView;

@end

#include "MullePointHistory.h"


//
// If you remove a UIScrollView from its window hierarchy, be sure to
// setMomentum:CGPointZero timestamp:0 to avoid crashers
//
@interface UIScrollView : UIView
{
	UIScrollContentView         *_contentView;
	MulleScrollIndicatorView    *_horIndicatorView;
	MulleScrollIndicatorView    *_verIndicatorView;

// Event handling state
   CGPoint                     _momentum;
   CGPoint                     _locationInWindow;
   CGPoint                     _bubbleDragOffset;
   CAAbsoluteTime              _scrollStartTime;
   CAAbsoluteTime              _momentumTimestamp;

   struct MullePointHistory    _locationInWindowHistory;
}

@property( assign) id <UIScrollViewDelegate>   delegate;
@property( assign, getter=isDragging) BOOL     dragging;
@property( assign, getter=isZoomEnabled) BOOL  zoomEnabled;
@property( assign) BOOL                        showsHorizontalScrollIndicator;
@property( assign) BOOL                        showsVerticalScrollIndicator;


// passed to contentView

- (CGPoint) contentOffset;
- (void) setContentOffset:(CGPoint) offset;
- (CGSize) contentSize;
- (void) setContentSize:(CGSize) size;

- (void) scrollContentOffsetBy:(CGPoint) diff;

// move this into category
- (void) scrollRectToVisible:(CGRect) rect
                    animated:(BOOL) animated;

// add subviews to contentView not to UIScrollView
- (UIScrollContentView *) contentView;
- (UIView *) horizontalScrollIndicatorView;
- (UIView *) verticalScrollIndicatorView;

+ (UIScrollContentView *) mulleScrollContentsViewWithFrame:(CGRect) frame;

- (CGPoint) zoomFactor;

// returns YES if there is momentum
- (BOOL) setMomentum:(CGPoint) momentum
           timestamp:(CAAbsoluteTime) timestamp;

@end


/*
 * UIScrollContentView geometry
 *
 * The UIScrollContentView uses the bounds rect to pick out a rectangle for
 * display in its frame. It clips the rest. As the bounds.size is equal to
 * the frame.size (unless you hack it), there is no scrolling involved.
 * Only panning. This pretty much the same idea as CALayer, where the canvas
 * is the content. But then again a UIView does no drawing!
 *
 *
 * content.origin (0.0,0.0)
 *      .----------------------------------.
 *      |                                  |
 *      | bounds.origin (contentOffset)    |   frame.origin
 *      |       .------------------.       |        .------------------.
 *      | .---. |                  |       |        |                  |
 *      | |   | |                  |       |        |                  |
 *      | '---' |      .---.       |       |        |      .---.       |
 *      |       |      |   |       |--------------->|      |   |       |
 *      |       |      '---'       |       |        |      '---'       |
 *      |       |                  |       |        |                  |
 *      |       '------------------'       |        '------------------'
 *      |                    bounds.size   |                       frame.size
 *      |                                  |
 *      '----------------------------------'- (void) centerOnPoint:(CGPoint) point

 *                                    content.size (contentSize)
 */
@interface UIScrollContentView : UIView

@property( assign) CGSize   contentSize;

- (CGPoint) contentOffset;  // same as bounds.origin
- (void) setContentOffset:(CGPoint) offset;

- (void) scrollContentOffsetBy:(CGPoint) diff;
- (CGPoint) clampedContentOffset:(CGPoint) offset;
- (CGRect) clampedBounds:(CGRect) bounds;

- (void) centerOnPoint:(CGPoint) point;

@end
