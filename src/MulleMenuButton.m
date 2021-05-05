//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "MulleMenuButton.h"

#import "import-private.h"

#import "CALayer.h"
#import "UIView+Layout.h"
#import "CGGeometry+CString.h"


@implementation MulleMenuButton

+ (CALayer *) mulleTitleBackgroundLayerWithFrame:(CGRect) frame
{
   CALayer   *layer;

   layer = [[[CALayer alloc] initWithFrame:frame] autorelease];

   [layer setBackgroundColor:getNVGColor( 0xFFFFFFFF)];
   // this ensures that the background fill does not antialias into the
   // outside
   [layer setBorderWidth:0.0];
   [layer setBorderColor:getNVGColor( 0x7F7FFFFF)];
   [layer setCornerRadius:0.0];
   [layer setDebugNameCString:"UIButton titleBackgroundLayer"];

   return( layer);
}


- (CGRect) mulleInsetTextLayerFrameInRect:(CGRect) frame
{
   CGRect   rect;

   rect             = [super mulleInsetTextLayerFrameInRect:frame];
   rect.origin.x   += 48.0;
   rect.size.width -= 48.0;
   rect.size.width -= 96.0;
   return( rect);
}


//
// TODO: need space on right as computed by Keyboard shortcut string
//
-(CGSize) sizeThatFits:(CGSize) size
               context:(CGContext *) context
{
   CGSize   result;

   result = [super sizeThatFits:size
                        context:context];
//   fprintf( stderr, "%s: %s\n",
//                  __PRETTY_FUNCTION__, CGSizeCStringDescription( result));

   result.width += 48.0 + 96.0;
   assert( result.height > 0.0);
   return( result);
}

@end
