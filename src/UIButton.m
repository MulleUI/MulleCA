#import "UIButton.h"

#import "UIImage.h"
#import "CALayer.h"
#import "MulleTextLayer.h"
#import "UIView+UIResponder.h"
#import "UIEdgeInsets.h"
#import "CGGeometry+CString.h"

// implemented by UIResponder protocol class, but mulle-clang can't figure
// it out (yet)
@interface UIView( ProtocolClass)

- (void) mulleToggleSelectedState;

@end


@implementation UIButton

#define BORDER_WIDTH    1.5
#define TEXT_MARGIN     1.0
#define CORNER_RADIUS   8

+ (MulleTextLayer *) titleLayerWithFrame:(CGRect) frame
 {
    MulleTextLayer   *layer;

   layer = [[[MulleTextLayer alloc] initWithFrame:frame] autorelease];

   //
   // if we composite on top of an image and leave the background
   // transparent, then the cleartype font looks very ugly. It needs a
   // solid background. (White on black seems best ?)
   //
   // Idea: text layer could shrink to minimum required size and then center
   //       itself.
   //
   //       Do not use cleartype font for UIButton, if the background is not
   //       opaque ?
   //

   // [self setTitleCString:"Title"];
   [layer setFontName:"sans"];
   //
   // Even with pixel size full frame, we won't cover the button. I suspect
   // because the font leaves vertical room for a previous row of text
   // Fontsize is probably usefully set by the user anyway
   [layer setFontPixelSize:frame.size.height / 2];
   [layer setBackgroundColor:getNVGColor( 0x0000000)];
   [layer setTextColor:getNVGColor( 0x000000FF)];
   [layer setAlignmentMode:CAAlignmentCenter];
   // set this as we are transparent
   [layer setTextBackgroundColor:getNVGColor( 0xFFFF00FF)];
   [layer setHidden:YES];

   return( layer);
}

/* Selection and highlight colors are currently hardcoded in
 * UIButton+UIResponder.
 */
+ (CALayer *) mulleTitleBackgroundLayerWithFrame:(CGRect) frame
{
   CALayer   *layer;

   layer = [[[CALayer alloc] initWithFrame:frame] autorelease];

   [layer setBackgroundColor:getNVGColor( 0xFFFFFFFF)];
   // this ensures that the background fill does not antialias into the
   // outside
   [layer setBorderWidth:BORDER_WIDTH];
   [layer setBorderColor:getNVGColor( 0x7F7FFFFF)];
   [layer setCornerRadius:CORNER_RADIUS];
   [layer setDebugNameCString:"UIButton titleBackgroundLayer"];
   return( layer);
}


- (void) setupLayersInRect:(CGRect) frame
{
   Class   cls;

   cls = [self class];

   _titleBackgroundLayer = [cls mulleTitleBackgroundLayerWithFrame:frame];
   [_titleBackgroundLayer setDebugNameCString:"UIButton titleBackgroundLayer"];
   [self addLayer:_titleBackgroundLayer];

   _titleLayer = [cls titleLayerWithFrame:frame];
   [_titleLayer setDebugNameCString:"UIButton titleLayer"];
   [self addLayer:_titleLayer];
}


- (instancetype) initWithLayer:(CALayer *) layer
                         frame:(CGRect) frame
{
   Class   cls;
   CGRect  bounds;

   self = [super initWithLayer:layer
                         frame:frame];
   if( self)
   {
      cls = [self class];

      bounds.origin = CGPointZero;
      bounds.size   = frame.size;

      [self setupLayersInRect:bounds];
      _titleBackgroundLayer = [cls mulleTitleBackgroundLayerWithFrame:frame];
      [_titleBackgroundLayer setDebugNameCString:"UIButton titleBackgroundLayer"];
      [self addLayer:_titleBackgroundLayer];

      _titleLayer = [cls titleLayerWithFrame:frame];
      [_titleLayer setDebugNameCString:"UIButton titleLayer"];
      [self addLayer:_titleLayer];
   }
   return( self);
}


#if DEBUG
- (void) renderWithContext:(CGContext *) context
{
   [super renderWithContext:context];
}
#endif


- (void) setTitleCString:(char *) s
{
   [_titleLayer setCString:s];
   [self hideUnhideTitleLayers];
}

- (char *) titleCString
{
   return( [_titleLayer cString]);
}


- (void) setContentHorizontalAlignment:(enum CATextLayerAlignmentMode) value
{
   [_titleLayer setAlignmentMode:value];
}


- (enum CATextLayerAlignmentMode) contentHorizontalAlignment
{
   return( [_titleLayer alignmentMode]);
}


- (void) getBackgroundImageIVar:(UIImage ***) ivar
{
  *ivar = _backgroundImage;
}

- (void) setBackgroundImage:(UIImage *) image
{
   CALayer   *layer;
   Class     preferredLayerClass;
   Class     layerClass;

   assert( ! image || [image isKindOfClass:[UIImage class]]);

   if( ! image)
      return;

   // hackish cast, fix later
   layer               = [self layer];
   layerClass          = [layer class];
   preferredLayerClass = [image preferredLayerClass];

   if( [layerClass isSubclassOfClass:preferredLayerClass])
      [(CALayer<CAImageLayer> *) layer setImage:image];
   else
      abort();
}


//
// When using Yoga to do the layout. It will change the frame of the
// UIButton. This frame is identical to the frame of the mainLayer.
// But the other layers are not affected.
// One could mark the button as needing a layout, but we are doing this
// immediately. Note that Yoga is the layouting step and doing another
// layouting is kinda weird.
//
- (CGRect) mulleInsetTextLayerFrameInRect:(CGRect) frame
{
   UIEdgeInsets   insets;
   CGFloat        borderWidth;

   borderWidth = [_titleBackgroundLayer borderWidth];
   insets      = UIEdgeInsetsMake( borderWidth / 2.0f + TEXT_MARGIN,
                                   borderWidth / 2.0f + TEXT_MARGIN,
                                   borderWidth / 2.0f + TEXT_MARGIN,
                                   borderWidth / 2.0f + TEXT_MARGIN);

   return( UIEdgeInsetsInsetRect( frame, insets));
}


- (void) hideUnhideTitleLayers
{
   char  *s;
   BOOL   visible;

   s = [_titleLayer cString];

   visible = s && *s;

   [_titleLayer setHidden:! visible];
   [_titleBackgroundLayer setHidden:! visible];
   [_titleLayer setCString:visible ? s : ""];
}


- (void) layoutLayers
{
   CGRect   bounds;
   CGRect   textLayerFrame;

   bounds = [self bounds];

   [_mainLayer setFrame:bounds];
   [_titleBackgroundLayer setFrame:bounds];

   textLayerFrame = [self mulleInsetTextLayerFrameInRect:bounds];
   [_titleLayer setFrame:textLayerFrame];
   [self hideUnhideTitleLayers];
}


// TODO: reverse scale size or transformation
- (CGSize) sizeThatFits:(CGSize) size
                context:(CGContext *) context
{
   CGSize    result;
   CGFloat   borderWidth;
   CALayer   *layer;
   CGRect    frame;

   result        = [_titleLayer sizeThatFits:size
                                     context:context];
   borderWidth   = [_titleBackgroundLayer borderWidth];
   result.width += borderWidth + 2 * TEXT_MARGIN;
//   result.height += borderWidth + 2 * TEXT_MARGIN;

   layer = [self layer];
   assert( layer);
   frame = [layer frame];
   assert( frame.size.height > 0.0);
   result.height = frame.size.height;

//   fprintf( stderr, "%s: %s\n",
//                  __PRETTY_FUNCTION__, CGSizeCStringDescription( result));
   return( result);
}

@end
