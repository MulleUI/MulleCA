//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "UIButton.h")
#  import "UIButton.h"
# endif
#endif

#import "import.h"

//
// MulleMenuButton: has inset on the left to show possible checkmarks.The 
//                  spacing is ' X '.
//                  has inset on the right for submenu triangle and keyboard
//                  shortcuts. 
//                  Left inset is basically a constant, but right inset is 
//                  dynamic per Button.
//
@interface MulleMenuButton : UIButton

@property( retain) id   representedObject;

@end
