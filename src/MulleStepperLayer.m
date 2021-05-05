#import "MulleStepperLayer.h"

#import "CGContext.h"
#import "CGContext+CGFont.h"
#import "CGFont.h"


@implementation MulleStepperLayer : CALayer


- (void) setFontNameCString:(char *) s
{
   MulleObjCObjectSetDuplicatedCString( self, &_fontName, s);
}


- (void) setCString:(char *) s
{
   MulleObjCObjectSetDuplicatedCString( self, &_cString, s);
}


- (void) dealloc
{
   MulleObjCInstanceDeallocateMemory( self, _fontName);
   MulleObjCInstanceDeallocateMemory( self, _cString);

   [super dealloc];
}


- (void) drawInContext:(CGContext *) context
{
   CGFloat             fontPixelSize;
   CGFloat             midX;
   CGFloat             strokeWidth;
   CGFont              *font;
   CGRect              canvas;
   CGRect              canvas1;
   CGRect              canvas2;
   char                *name;
   struct NVGcontext   *vg;

   vg     = [context nvgContext];
   canvas = [self canvas];

   strokeWidth = 2.0;

   // calculate two inner frames without surrounding box/border/divider
   canvas1.origin.x    = canvas.origin.x + strokeWidth;
   canvas1.origin.y    = canvas.origin.y + strokeWidth;
   canvas1.size.width  = (canvas.size.width - strokeWidth) / 2.0 - strokeWidth;
   canvas1.size.height = canvas.size.height - strokeWidth * 2;;

   canvas2 = canvas1;
   canvas2.origin.x    = canvas1.origin.x + canvas1.size.width + strokeWidth;

   // draw surrounding box and the divider
   nvgBeginPath( vg);
   nvgRoundedRect( vg, canvas.origin.x,
                       canvas.origin.y,
                       canvas.size.width - strokeWidth,
                       canvas.size.height - strokeWidth,
                       2.0);

   midX = canvas2.origin.x - strokeWidth / 2.0;
   nvgMoveTo( vg, midX, canvas.origin.y);
   nvgLineTo( vg, midX, canvas.origin.y + canvas.size.height - 1.0);
   nvgStrokeColor( vg, nvgRGBA(255,127,127,255));
   nvgStrokeWidth( vg, (int) strokeWidth);
   nvgStroke( vg);

   // draw two text labels in each side

   font = [context fontWithNameCString:_fontName ? _fontName : "sans"];
   name = [font nameCString];  // get actual name, which could have different address

   fontPixelSize = [self fontPixelSize];
   if( fontPixelSize == 0.0)
      fontPixelSize = canvas.size.height;

	nvgFontSize( vg, fontPixelSize);
	nvgFontFace( vg, name);
   nvgTextColor( vg, nvgRGBA(255,255,255,255), [self backgroundColor]); // TODO: use textColor

	nvgTextAlign( vg,NVG_ALIGN_CENTER|NVG_ALIGN_MIDDLE);
	nvgText( vg, canvas1.origin.x + canvas1.size.width / 2.0,
                canvas1.origin.y + canvas1.size.height *0.5f,
                "-",
                NULL);
	nvgText( vg, canvas2.origin.x + canvas2.size.width / 2.0,
                canvas2.origin.y + canvas2.size.height *0.5f,
                "+",
                NULL);
}

@end
