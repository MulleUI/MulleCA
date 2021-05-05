//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "MulleMenu.h"

#import "import-private.h"

#import "UIScrollView.h"
#import "UIStackView.h"
#import "MulleMenuButton.h"
#import "CGContext.h"
#import "CGGeometry+CString.h"
#import "MulleTextLayer.h"


// Layouting of MulleMenu
//
// The Menu has a ScrollView and a StackView. The Menuentries are placed
// into the StackView, which grows. If the StackView is complete, we can
// get its size by asking it to "sizeThatFits:" infinity basically, which
// will return a "mininmal" rect.
//
// The Menu will have to be positioned on the screen somewhere though.
// For example on top of another view.
//

@implementation MulleMenu

#define CORNER_RADIUS  2.0
#define SHADOW_TOP     2.0
#define SHADOW_BOTTOM  6.0
#define SHADOW_LEFT    2.0
#define SHADOW_RIGHT   6.0
#define SHADOW_FEATHER (SHADOW_BOTTOM+SHADOW_RIGHT)
#define SHADOW_WIDTH   (SHADOW_LEFT + SHADOW_RIGHT)
#define SHADOW_HEIGHT  (SHADOW_TOP  + SHADOW_BOTTOM)


static void   drawCallback( CALayer *layer, CGContext *ctxt)
{
	NVGpaint     shadowPaint;
   float        x;
   float        y;
   float        w;
   float        h;
   NVGcontext   *vg;
   CGRect       canvas;

   vg = MulleContextGetNVGContext( ctxt);

   canvas = [layer canvas];

   x = CGRectGetMinX( canvas);
   y = CGRectGetMinY( canvas);
   w = CGRectGetWidth( canvas);
   h = CGRectGetHeight( canvas);

	// Drop shadow
	shadowPaint = nvgBoxGradient(vg, x,y+SHADOW_TOP, w,h, CORNER_RADIUS*2, SHADOW_FEATHER,
                                 nvgRGBA(0,0,0,64),
                                 nvgRGBA(0,0,0,0));

	nvgBeginPath(vg);
   	nvgRect(vg, x-SHADOW_LEFT,y-SHADOW_TOP, w+SHADOW_WIDTH,h+SHADOW_HEIGHT);
   	nvgRoundedRect(vg, x,y, w,h, CORNER_RADIUS);
   	nvgPathWinding(vg, NVG_HOLE);
   	nvgFillPaint(vg, shadowPaint);
	nvgFill(vg);

//	// Window
//	nvgBeginPath(vg);
//   	nvgRoundedRect(vg, x,y, w,h, CORNER_RADIUS);
//   	nvgFillColor(vg, nvgRGBA(200,200,200,255));
//	nvgFill(vg);
}


- (instancetype) initWithLayer:(CALayer *) layer
                         frame:(CGRect) frame
{
   CGRect   frame;
   CGSize   size;

   self = [super initWithLayer:layer
                         frame:frame];
   [layer setDrawCallback:drawCallback];

   frame.origin = CGPointMake( 0.0f, 0.0f);
   _stackView   = [UIStackView viewWithFrame:frame];
   [_stackView setAxis:UILayoutConstraintAxisVertical];
   [_stackView setDistribution:MulleStackViewDistributionUnbounded];

   _scrollView = [UIScrollView viewWithFrame:frame];
   [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_scrollView setShowsHorizontalScrollIndicator:NO];
   [[_scrollView contentView] addSubview:_stackView];

   frame.size.height = 1000000.0;
   [_scrollView setContentSize:frame.size];

   [self addSubview:_scrollView];

   return( self);
}


- (void) addMenuButton:(MulleMenuButton *) button
{
   [_stackView addSubview:button];
   [self setNeedsLayout];
}


#ifdef DEBUG
- (void) setHidden:(BOOL) flag
{
   [super setHidden:flag];
}
#endif

// Our layouting scheme is strictly top/down. So the parentview allots space
// for the stackview to size itself. (In our case this is infinite along the
// vertical axis). Once this is done, regular layouting commences and the
// stackview layouts itself.
//
// Now afterwards we can collect what has been done, wrap it into a
// scrollview or shrink it appropriately. The main problem is that we should
// also shrink. So its like bottom up layouting.. The bottom up layouting
// may not expand outside of the alloted space given in top down. If a view
// refused to fit, it can get wrapped into a scrollview (automatically ?) or
// be discard/truncated ?
//
//- (void) layoutSubview:(UIView *) view
//              inRect:(CGRect) bounds
//      autoresizingMask:(UIViewAutoresizing) autoresizingMask
//{
//   // increase size for top/down layout, later in -layout
//   // shrink size to fit
//   if( view == _scrollView)
//   {
//      bounds.size.height = 1000000.0; // large...
//      [_scrollView setContentSize:bounds.size];
//   }
//
//   [super layoutSubview:view
//               inRect:bounds
//       autoresizingMask:autoresizingMask];
//}


// TODO: Das MulleMenu ist der Container für die Scrollview.
//       die MenuButtons in der StackView ergeben die grösse der Stackview
//       die dann auch die contentSize der ScrollView ist.
//       Die Platzierung des Menus ist wegen x/y/w/h abhängig von der
//       dargestellten Grösse. Diese wird vom MullePopUpButton vorgegeben.
//       Dadurch wird ev. die Breite des Menus beinflusst ? Eher nein.
//       Aber der Frame wird gesetzt. Im layout gehts dann nur darum von der
//       Stackview die grösse in die ScrollView zu kopieren.

- (enum UILayoutStrategy) layoutStrategy
{
   return( UILayoutStrategyStop);
}

- (void) layout
{
   CGSize   size;
   CGRect   frame;
   CGRect   contentFrame;
   CGRect   before;
   UIView   *contentView;
   CGSize   contentSize;
   CGFloat  y;

   [super layout];  // just resets needsLayout for us

   contentFrame.origin = CGPointZero;
   contentFrame.size   = [self sizeThatFits:CGSizeMake( INFINITY, INFINITY)];
   [_stackView setFrame:contentFrame];
   [_stackView layout];

   assert( _scrollView);

   frame = [self frame];
   [_scrollView setFrame:CGRectMake( 0, 0, frame.size.width, frame.size.height)];
   [_scrollView setBounds:CGRectMake( 0, 0, frame.size.width, contentFrame.size.height)];
   [_scrollView layout];

   // reflect size in scrollView contentSize
   y = contentFrame.size.height - frame.size.height;
   [_scrollView setContentOffset:CGPointMake( 0, y)];
   [_scrollView setContentSize:contentFrame.size];

   [self dump];
}


- (void) addMenuButtonsWithTitleCStrings:(char **) titles
                                   count:(NSUInteger) n
                                  target:(id) target
                                  window:(UIWindow *) window
{
   NSUInteger        i;
   MulleMenuButton   *menuButton;

   for( i = 0; i < n; i++)
   {
      menuButton = [MulleMenuButton viewWithFrame:CGRectMake( 0, 0, 200, 20)];
      [menuButton setTitleCString:titles[ i]];
      [menuButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
      [menuButton setContentHorizontalAlignment:CAAlignmentLeft];

      [menuButton setTarget:target];
      [menuButton setAction:@selector( menuButtonClicked:)];

      /* TODO: Tricky, if the button resizes then the tracking area must also
               resize. BUT, it's not really dynamic yet.
       */
      [menuButton addTrackingAreaWithRect:CGRectMake( 0, 0, 200, 20)
                                 toWindow:window
                                 userInfo:nil];
      [self addMenuButton:menuButton];
   }
}


-(CGSize) sizeThatFits:(CGSize) size
               context:(CGContext *) context
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   struct mulle_pointerarray             *stackedSubviews;
   CGSize                                result;
   CGSize                                buttonSize;

   assert( context);

   // minwidth is 80 so make that the initial value
   result          = CGSizeMake( 80.0, 0.0);
   stackedSubviews = [_stackView _subviews];

   assert( _stackView);
   assert( mulle_pointerarray_get_count( stackedSubviews) > 0);

   rover = mulle_pointerarray_enumerate( stackedSubviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
   {
      buttonSize = [view sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                              context:context];
      assert( buttonSize.height > 0.0);
      if( buttonSize.width > result.width)
         result.width = buttonSize.width;
      result.height += buttonSize.height;
   }
   mulle_pointerarrayenumerator_done( &rover);

   return( result);
}

- (void) setFrame:(CGRect) frame
{
   fprintf( stderr, "%s\n", CGRectCStringDescription( frame));
   [self setNeedsLayout];
   [super setFrame:frame];
}
@end
