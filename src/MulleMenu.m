//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "MulleMenu.h"

#import "import-private.h"

#import "UIScrollView.h"
#import "UIStackView.h"
#import "MulleMenuButton.h"
#import "CGGeometry+CString.h"

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

- (instancetype) initWithLayer:(CALayer *) layer
{
   CGRect   frame;
   CGSize   size;

   self         = [super initWithLayer:layer];
   frame.origin = CGPointZero;
   frame.size   = [layer frame].size;

   _stackView  = [UIStackView mulleViewWithFrame:frame];
   [_stackView setAxis:UILayoutConstraintAxisVertical];
   [_stackView setDistribution:MulleStackViewDistributionUnbounded];

   _scrollView = [UIScrollView mulleViewWithFrame:frame];
   [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_scrollView setShowsHorizontalScrollIndicator:NO];
   [[_scrollView contentView] addSubview:_stackView];

   frame.size.height = 1000000.0;
   [_scrollView setContentSize:frame.size];

   [self addSubview:_scrollView];

   return( self);
}


- (void) addMenuButton:(MulleMenuButton *) button;
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
- (void) layoutSubview:(UIView *) view
              inBounds:(CGRect) bounds
      autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   // increase size for top/down layout, later in -layout
   // shrink size to fit
   if( view == _scrollView)
   {
      bounds.size.height = 1000000.0; // large...
      [_scrollView setContentSize:bounds.size];
   }

   [super layoutSubview:view
               inBounds:bounds
       autoresizingMask:autoresizingMask];
}


- (CGSize) sizeThatFits:(CGSize) size 
                context:(CGContext *) context
{
   CGSize   bestSize;

   bestSize = [_stackView sizeThatFits:size
                               context:context];
   if( bestSize.width < size.width)
      size.width = bestSize.width;
   if( bestSize.height < size.height)
      size.height = bestSize.height;
   return( size);
}


- (void) layout
{
   CGSize   size;
   CGRect   frame;
   CGRect   before;
   UIView   *contentView;

   [super layout];

   assert( _stackView);

   //
   // shrink stackView to fit our bounds, which are what exactly ?
   // and why do they matter ?
   frame.origin = CGPointZero;
   size         = CGSizeMake( 10000000.0, 10000000.0);
   frame.size   = [_stackView sizeThatFits:size];
   [_stackView setFrame:frame];

   assert( _scrollView);

   // reflect size in scrollView contentSize
   [_scrollView setContentSize:frame.size];

   // Now make the menu as large as possible. This will resize the scroll
   // View as well.
   //
   // this should be done by the scrollview. Is it necessary to use
   // a separate property for contentSize, if we could use the bounds
   // of the contentView as storage ?
   // 
   //   contentView  = [_scrollView contentView];
   //   frame.origin = [contentView frame].origin;
   //   [contentView setFrame:frame];

   // so scrollview can set indicator views
   [_scrollView layoutSubviews];

   // shrink self to fit if frame.size.height is less than current
   before = [self frame];
   if( before.size.height > frame.size.height)
   {
      frame.origin = before.origin;
      [self setFrame:frame];
   }
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
      menuButton = [MulleMenuButton mulleViewWithFrame:CGRectMake( 0, 0, 200, 20)];
      [menuButton setTitleCString:titles[ i]];
      [menuButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
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

@end
