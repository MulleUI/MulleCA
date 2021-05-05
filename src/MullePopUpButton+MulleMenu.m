//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "MullePopUpButton+MulleMenu.h"

#import "import-private.h"

#import "UIWindow.h"
#import "MulleMenu.h"
#import "MulleLayout.h"
#import "UIView+CGGeometry.h"
#import "UIView+Layout.h"
#import "UIView+CAAnimation.h"


@implementation MullePopUpButton ( MulleMenu)

- (MulleMenu *) menu
{
   MulleWindowPlane   *menuPlane;
   UIWindow           *window;
   MulleMenu          *menuView;

   if( _menu)
      return( _menu);

   menuView = [MulleMenu viewWithFrame:CGRectMake( 0, 0, 200, 75)];
   [menuView setTarget:self];
   [menuView setAction:@selector( outsideMenuClicked:)];
   [menuView setHidden:YES];

   window = [self window];
   [menuView addMenuButtonsWithTitleCStrings:_titles
                                       count:_titlesCount
                                      target:self
                                      window:window];


   menuPlane = [window menuPlane];

   [menuPlane addSubview:menuView];
   [menuPlane setNeedsLayout];
   [menuPlane setHidden:NO];

   [self setMenu:menuView];

   return( menuView);
}

//
// positions and sizes
// the menu has been layouted already, so the size is known
//
- (void) positionAndSizeMenu:(MulleMenu *) menu
{
   CGRect              frame;
   CGRect              buttonFrame;
   CGRect              menuFrame;
   CGRect              animFrame;
   CGRect              space;
   MulleWindowPlane   *plane;

   static unsigned char    menu_placement_preferences[] =
   {
      _MulleLayoutPlacementMake( MulleLayoutPlacementLeftAligned,  MulleLayoutPlacementDown),
      _MulleLayoutPlacementMake( MulleLayoutPlacementLeftAligned,  MulleLayoutPlacementUp),
      _MulleLayoutPlacementMake( MulleLayoutPlacementRightAligned, MulleLayoutPlacementDown),
      _MulleLayoutPlacementMake( MulleLayoutPlacementRightAligned, MulleLayoutPlacementUp),
      _MulleLayoutPlacementMake( MulleLayoutPlacementCenter,       MulleLayoutPlacementDown),
      _MulleLayoutPlacementMake( MulleLayoutPlacementCenter,       MulleLayoutPlacementUp),
      _MulleLayoutPlacementMake( MulleLayoutPlacementCenter,       MulleLayoutPlacementMiddle)
   };

   // this positions the menu origin and size relative to the button, so
   // a) it looks nice
   // b) enough entries are visible

   // 1. look at spaces to left, right, top an bottom

   plane        = [self mulleWindowPlane];
   space.origin = CGPointZero;
   space.size   = [plane bounds].size;

   frame        = [self frame];
   buttonFrame  = [[self superview] convertRect:frame
                                        toView:plane];

   // now we look at the plane and divide it up

   menuFrame      = [menu frame];
   menuFrame.size = [menu sizeThatFits:CGSizeMake( CGFLOAT_MAX, CGFLOAT_MAX)];

   //  0   4   8  12   16
   //  +---------------+
   //  | t :   o   : p |
   //  |...+-------+...| bounds
   //  |   | frame |   |
   //  |...+-------+...|
   //  |   :       :   |
   //  +---------------+

   menuFrame.origin =  MullePlaceRectNextToRectInSpace( menuFrame,
                                                        buttonFrame,
                                                        space,
                                                        sizeof( menu_placement_preferences),
                                                        menu_placement_preferences,
                                                        sizeof( menu_placement_preferences) - 1);
   if( menuFrame.origin.x == CGFLOAT_MIN)
      abort();

   // the origin can be in the negative though, if this is the case we need
   // to resize the menu a bit. We also leave a little border ?
   if( CGRectGetMinX( menuFrame) < 0.0)
      menuFrame.origin.x = 0.0;

   if( CGRectGetMinY( menuFrame) < 0.0)
      menuFrame.origin.y = 0.0;

   if( CGRectGetMaxX( menuFrame) > space.size.width)
      menuFrame.size.width = space.size.width;

   if( CGRectGetMaxY( menuFrame) > space.size.height)
      menuFrame.size.height = space.size.height;

   //
   // so ideally the menu covers vertically as much space as possible
   // the items are placed in a scrollView to handle overflow, this will
   // then resize accordingly: Should we do it here already ?
   //

   // a popup menu must have an entry, otherwise the popupmenu shouldn't
   // show it
   assert( menuFrame.size.height > 0.0);

   animFrame             = menuFrame;
   animFrame.size.height = 10.0;
   [menu setFrame:animFrame];
   [menu setBounds:CGRectMake( 0, 0, menuFrame.size.width, menuFrame.size.height)];
   [menu layout];

   // UIView -> CAAnimation
   [UIView beginAnimations:"animation"
                    context:NULL];
      [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
      [UIView setAnimationDuration:0.1];
      [menu setFrame:menuFrame];
      [menu setBounds:CGRectMake( 0, 0, menuFrame.size.width, menuFrame.size.height)];
      [menu layout];
   [UIView commitAnimations];
}

@end
