#import "import-private.h"

#include <math.h>

//
// 16-effect animation showcase. Each cell in a 4x4 grid shows a different
// game-UI animation effect using MulleCA primitives.
//
// Effects 1-4 implemented:
//   1. Gradient shine sweep (color animation on a button)
//   2. Rocket orbiting a globe (CAPathAnimation + pose)
//   3. Bouncing emoji button (frame Y bounce)
//   4. Clash Royale squash/stretch (rect + color flash)
//

#define GRID_COLS  4
#define GRID_ROWS  4
#define N_CELLS    (GRID_COLS * GRID_ROWS)


#pragma mark - Grid Layout

static CGRect   cellFrameAtIndex( NSUInteger i, CGRect canvas)
{
   CGRect    frame;
   CGFloat   cellWidth;
   CGFloat   cellHeight;

   frame = UIEdgeInsetsInsetRect( canvas, UIEdgeInsetsMake( 10, 10, 10, 10));

   cellWidth  = CGRectGetWidth( frame) / GRID_COLS;
   cellHeight = CGRectGetHeight( frame) / GRID_ROWS;

   return( CGRectMake( frame.origin.x + (i % GRID_COLS) * cellWidth,
                       frame.origin.y + (i / GRID_COLS) * cellHeight,
                       cellWidth,
                       cellHeight));
}


// inset cell and center a box of given size
static CGRect   centeredBox( CGRect cell, CGSize size)
{
   return( CGRectMake( cell.origin.x + (cell.size.width - size.width) / 2,
                       cell.origin.y + (cell.size.height - size.height) / 2,
                       size.width,
                       size.height));
}


#pragma mark - Effect 1: Gradient Shine Sweep

//
// Simulates a light sweep over a button by cycling backgroundColor
// from dark-blue → bright-cyan → dark-blue with a fast easeInOutSine.
//
static BOOL   shineSweepDraw( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect    bounds;
   CGRect    shineBox;
   CGFloat   offset;
   CGFloat   cornerRadius;

   bounds       = [layer canvas];
   cornerRadius = [layer cornerRadius];
   offset       = [layer borderWidth];  // repurpose borderWidth as shineOffset

   // Draw background
   CGContextFillRoundedRectWithColor( context, bounds, cornerRadius,
                                      CGColorMakeWithRGBA( 0.15, 0.15, 0.25, 1.0));

   // Draw shine: a box gradient (white glow) positioned at offset
   shineBox = CGRectMake( bounds.origin.x + offset - 6,
                          bounds.origin.y,
                          12,
                          bounds.size.height);
   CGContextBeginPath( context);
   CGContextRoundedRect( context, bounds, cornerRadius);
   CGContextSetFillBoxGradient( context, shineBox, 2.0,
                                CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 0.9),
                                8.0,
                                CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 0.0));
   CGContextFill( context);

   return( YES);
}


static void   setupShineSweep( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *button;
   CGRect                           frame;
   CABasicAnimation                 *anim;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;
   CGFloat                          btnW;
   CGFloat                          btnH;

   btnW = 120.0;
   btnH = 36.0;

   frame  = centeredBox( cell, CGSizeMake( btnW, btnH));
   button = [CGGraphicsLayer layerWithFrame:frame];
   [button setCornerRadius:8.0];
   [button setDrawCallback:shineSweepDraw];
   [button setBorderWidth:0.0];  // initial shineOffset = 0 (left edge)
   [[window contentView] addLayer:button];

   // Animate borderWidth as shineOffset (0 → btnW), then pause
   property = MulleObjCInstanceSearchProperty( button, @selector( borderWidth));
   {
      CAAnimationSequence   *seq;

      seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
         &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

      opts = CABasicAnimationOptionsMakeLinear(
         mulle_relativetimerange_make( 0, 1.0),
         1.0, NO);
      anim = [[[CABasicAnimation alloc]
         initWithProperty:property
          startFloatValue:-30.0
            endFloatValue:btnW + 30.0
                  options:&opts] autorelease];
      [anim setAnimationObject:button];
      [seq addAnimation:anim];
      [seq addPause:1.0];

      [button addAnimation:seq];
   }
}


#pragma mark - Effect 2: Rocket Orbiting Globe

//
// A small triangle (rocket) follows a circular path around a globe layer.
// Uses CAPathAnimation with pose so the nose follows the trajectory.
//
static void   setupRocketOrbit( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *globe;
   CAShapeLayer                     *rocket;
   CGPath                           *orbitPath;
   CGPath                           *rocketShape;
   CGPoint                          center;
   CGRect                           globeFrame;
   CGRect                           rocketFrame;
   CAPathAnimation                  *pathAnim;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;

   center = CGRectGetCenter( cell);

   // globe (circle-ish square with big corner radius)
   globeFrame = centeredBox( cell, CGSizeMake( 40, 40));
   globe = [CGGraphicsLayer layerWithFrame:globeFrame];
   [globe setBackgroundColor:CGColorMakeWithRGBA( 0.2, 0.5, 0.9, 1.0)];
   [globe setCornerRadius:20.0];
   [[window contentView] addLayer:globe];

   // rocket (small triangle on path)
   rocketFrame = CGRectMake( center.x - 8, center.y - 8, 16, 16);
   rocket = [CAShapeLayer layerWithFrame:rocketFrame];
   rocketShape = CGPathCreate( NULL);
   {
      // pointing right: triangle
      CGPathMoveToPoint( rocketShape, CGPointMake( 16, 8));
      CGPathAddLineToPoint( rocketShape, CGPointMake( 0, 0));
      CGPathAddLineToPoint( rocketShape, CGPointMake( 4, 8));
      CGPathAddLineToPoint( rocketShape, CGPointMake( 0, 16));
      CGPathCloseSubpath( rocketShape);
   }
   [rocket setPath:rocketShape];
   [rocket setFillColor:CGColorMakeWithRGBA( 1.0, 0.3, 0.1, 1.0)];
   [[window contentView] addLayer:rocket];

   // circular orbit path
   orbitPath = CGPathCreate( NULL);
   CGPathAddArcWithCenter( orbitPath, center, 50.0, 0.0, 1.0);

   // path animation on pose (position + rotation)
   property = MulleObjCInstanceSearchProperty( rocket, @selector( pose));
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 3.0),
      INFINITY, NO);
   pathAnim = [[[CAPathAnimation alloc]
      initWithProperty:property
                  path:orbitPath
         pathValueType:CAPathAnimationValuePose
               options:&opts] autorelease];
   [pathAnim setAnimationObject:rocket];

   [rocket addAnimation:pathAnim];
}


#pragma mark - Effect 3: Bouncing Emoji Button

//
// A colored button that bounces up and down with EaseOutBounce curve.
// Animates the frame rect Y position.
//
static void   setupBouncingButton( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           frame;
   CGRect                           startFrame;
   CGRect                           endFrame;
   CABasicAnimation                 *anim;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;

   frame      = centeredBox( cell, CGSizeMake( 60, 30));
   startFrame = CGRectOffset( frame, 0, -20);
   endFrame   = CGRectOffset( frame, 0, 20);

   layer = [CGGraphicsLayer layerWithFrame:startFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.8, 0.0, 1.0)];
   [layer setCornerRadius:6.0];
   [[window contentView] addLayer:layer];

   property = MulleObjCInstanceSearchProperty( layer, @selector( frame));
   opts = CABasicAnimationOptionsMakeTween(
      mulle_relativetimerange_make( 0, 1.0),
      CATweenEaseOutBounce,
      INFINITY, YES);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:startFrame
          endRectValue:endFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];

   [layer addAnimation:anim];
}


#pragma mark - Effect 4: Squash/Stretch + Flash

//
// Button squashes vertically (height compress), then stretches back up
// with overshoot, plus a white flash on the peak. Uses a sequence:
//   1. squash (frame height shrinks)
//   2. stretch with easeOutBack (frame height overshoots)
//   3. white flash (backgroundColor pulse)
//
static void   setupSquashStretch( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           restFrame;
   CGRect                           squashFrame;
   CGRect                           stretchFrame;
   CABasicAnimation                 *squashAnim;
   CABasicAnimation                 *stretchAnim;
   CABasicAnimation                 *flashAnim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *frameProperty;
   struct _mulle_objc_property      *colorProperty;
   struct CABasicAnimationOptions   opts;

   restFrame    = centeredBox( cell, CGSizeMake( 80, 40));
   squashFrame  = CGRectMake( restFrame.origin.x - 5,
                              restFrame.origin.y + 12,
                              restFrame.size.width + 10,
                              restFrame.size.height - 12);
   stretchFrame = CGRectMake( restFrame.origin.x + 3,
                              restFrame.origin.y - 5,
                              restFrame.size.width - 6,
                              restFrame.size.height + 8);

   layer = [CGGraphicsLayer layerWithFrame:restFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.9, 0.2, 0.3, 1.0)];
   [layer setCornerRadius:8.0];
   [[window contentView] addLayer:layer];

   frameProperty = MulleObjCInstanceSearchProperty( layer, @selector( frame));
   colorProperty = MulleObjCInstanceSearchProperty( layer, @selector( backgroundColor));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // 1. squash down (0.15s easeIn)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.15),
      CAAnimationCurveEaseInQuadratic,
      1.0, NO);
   squashAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:restFrame
          endRectValue:squashFrame
               options:&opts] autorelease];
   [squashAnim setAnimationObject:layer];
   [seq addAnimation:squashAnim];

   // 2. stretch back with overshoot (0.4s easeOutBack)
   opts = CABasicAnimationOptionsMakeTween(
      mulle_relativetimerange_make( 0, 0.4),
      CATweenEaseOutBack,
      1.0, NO);
   stretchAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:squashFrame
          endRectValue:restFrame
               options:&opts] autorelease];
   [stretchAnim setAnimationObject:layer];
   [seq addAnimation:stretchAnim];

   // 3. flash white → original color (0.2s)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.2),
      CAAnimationCurveEaseOutExponential,
      1.0, NO);
   flashAnim = [[[CABasicAnimation alloc]
      initWithProperty:colorProperty
       startColorValue:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)
         endColorValue:CGColorMakeWithRGBA( 0.9, 0.2, 0.3, 1.0)
               options:&opts] autorelease];
   [flashAnim setAnimationObject:layer];
   [seq addAnimation:flashAnim];

   // 4. hold at rest for 1.25s before repeat
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 1.25),
      1.0, NO);
   squashAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:restFrame
          endRectValue:restFrame
               options:&opts] autorelease];
   [squashAnim setAnimationObject:layer];
   [seq addAnimation:squashAnim];

   [layer addAnimation:seq];
}


#pragma mark - Effect 5: Pulse Glow

//
// Heartbeat pulse: layer scales up slightly and fades, then snaps back.
// Two quick pulses then a rest. Simulates a notification badge throb.
//
static void   setupPulseGlow( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           restFrame;
   CGRect                           pulseFrame;
   CABasicAnimation                 *frameAnim;
   CABasicAnimation                 *opacityAnim;
   CAAnimationSequence              *seq;
   CAAnimationGroup                 *pulse;
   struct _mulle_objc_property      *frameProperty;
   struct _mulle_objc_property      *opacityProperty;
   struct CABasicAnimationOptions   opts;

   restFrame  = centeredBox( cell, CGSizeMake( 36, 36));
   pulseFrame = CGRectInset( restFrame, -10, -10);

   layer = [CGGraphicsLayer layerWithFrame:restFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.2, 0.4, 1.0)];
   [layer setCornerRadius:18.0];
   [[window contentView] addLayer:layer];

   frameProperty   = MulleObjCInstanceSearchProperty( layer, @selector( frame));
   opacityProperty = MulleObjCInstanceSearchProperty( layer, @selector( opacity));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Pulse 1: expand + slight fade (0.25s each, repeat 2x with autoreverse = 0.5s total)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.25),
      CAAnimationCurveEaseOutQuadratic,
      2.0, YES);
   frameAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:restFrame
          endRectValue:pulseFrame
               options:&opts] autorelease];
   [frameAnim setAnimationObject:layer];

   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.25),
      CAAnimationCurveEaseOutQuadratic,
      2.0, YES);
   opacityAnim = [[[CABasicAnimation alloc]
      initWithProperty:opacityProperty
       startFloatValue:1.0
         endFloatValue:0.6
               options:&opts] autorelease];
   [opacityAnim setAnimationObject:layer];

   pulse = [[[CAAnimationGroup alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, 0.5 }, 0, 1.0, 0 }] autorelease];
   [pulse addAnimation:frameAnim];
   [pulse addAnimation:opacityAnim];
   [seq addAnimation:pulse];

   // Pulse 2: smaller secondary beat (0.2s each, repeat 2x = 0.4s total)
   pulseFrame = CGRectInset( restFrame, -3, -3);
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.2),
      CAAnimationCurveEaseOutQuadratic,
      2.0, YES);
   frameAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:restFrame
          endRectValue:pulseFrame
               options:&opts] autorelease];
   [frameAnim setAnimationObject:layer];

   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.2),
      CAAnimationCurveEaseOutQuadratic,
      2.0, YES);
   opacityAnim = [[[CABasicAnimation alloc]
      initWithProperty:opacityProperty
       startFloatValue:1.0
         endFloatValue:0.75
               options:&opts] autorelease];
   [opacityAnim setAnimationObject:layer];

   pulse = [[[CAAnimationGroup alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, 0.4 }, 0, 1.0, 0 }] autorelease];
   [pulse addAnimation:frameAnim];
   [pulse addAnimation:opacityAnim];
   [seq addAnimation:pulse];

   // Rest 1.1s
   [seq addPause:1.1];

   [layer addAnimation:seq];
}


#pragma mark - Effect 6: Coin Spin

//
// Fake 3D coin flip: width squishes to 0 (flat edge-on), color changes
// mid-flip to simulate backside, then expands back. Classic loot UI.
//
static void   setupCoinSpin( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           restFrame;
   CGRect                           flatFrame;
   CABasicAnimation                 *anim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *frameProperty;
   struct _mulle_objc_property      *colorProperty;
   struct CABasicAnimationOptions   opts;
   CGPoint                          center;

   restFrame = centeredBox( cell, CGSizeMake( 44, 44));
   center    = CGRectGetCenter( restFrame);
   flatFrame = CGRectMake( center.x - 2, restFrame.origin.y,
                           4, restFrame.size.height);

   layer = [CGGraphicsLayer layerWithFrame:restFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.84, 0.0, 1.0)];
   [layer setCornerRadius:22.0];
   [layer setBorderWidth:2.0];
   [layer setBorderColor:CGColorMakeWithRGBA( 0.8, 0.6, 0.0, 1.0)];
   [[window contentView] addLayer:layer];

   frameProperty = MulleObjCInstanceSearchProperty( layer, @selector( frame));
   colorProperty = MulleObjCInstanceSearchProperty( layer, @selector( backgroundColor));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Squish to flat (0.3s easeInSine — accelerating into flip)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.3),
      CAAnimationCurveEaseInSine,
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:restFrame
          endRectValue:flatFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Color flip at edge (instant — 0.01s)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:colorProperty
       startColorValue:CGColorMakeWithRGBA( 1.0, 0.84, 0.0, 1.0)
         endColorValue:CGColorMakeWithRGBA( 0.85, 0.65, 0.0, 1.0)
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Expand back (0.3s easeOutSine — decelerating out of flip)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.3),
      CAAnimationCurveEaseOutSine,
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:flatFrame
          endRectValue:restFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Color back to gold (instant)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:colorProperty
       startColorValue:CGColorMakeWithRGBA( 0.85, 0.65, 0.0, 1.0)
         endColorValue:CGColorMakeWithRGBA( 1.0, 0.84, 0.0, 1.0)
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Hold 1.4s
   [seq addPause:1.4];

   [layer addAnimation:seq];
}


#pragma mark - Effect 7: Slide-In Banner

//
// Banner slides in from the right with easeOutBack (overshoot and settle).
// Then fades out slowly. Classic notification/achievement toast.
//
static void   setupSlideInBanner( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           offFrame;
   CGRect                           onFrame;
   CABasicAnimation                 *slideAnim;
   CABasicAnimation                 *fadeAnim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *frameProperty;
   struct _mulle_objc_property      *opacityProperty;
   struct CABasicAnimationOptions   opts;

   onFrame  = centeredBox( cell, CGSizeMake( 110, 28));
   offFrame = CGRectOffset( onFrame, cell.size.width, 0);

   layer = [CGGraphicsLayer layerWithFrame:offFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.15, 0.7, 0.3, 1.0)];
   [layer setCornerRadius:6.0];
   [[window contentView] addLayer:layer];

   frameProperty   = MulleObjCInstanceSearchProperty( layer, @selector( frame));
   opacityProperty = MulleObjCInstanceSearchProperty( layer, @selector( opacity));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Slide in (0.6s easeOutBack — overshoot!)
   opts = CABasicAnimationOptionsMakeTween(
      mulle_relativetimerange_make( 0, 0.6),
      CATweenEaseOutBack,
      1.0, NO);
   slideAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:offFrame
          endRectValue:onFrame
               options:&opts] autorelease];
   [slideAnim setAnimationObject:layer];
   [seq addAnimation:slideAnim];

   // Hold visible (1.2s)
   [seq addPause:1.2];

   // Fade out (0.5s easeInQuadratic)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.5),
      CAAnimationCurveEaseInQuadratic,
      1.0, NO);
   fadeAnim = [[[CABasicAnimation alloc]
      initWithProperty:opacityProperty
       startFloatValue:1.0
         endFloatValue:0.0
               options:&opts] autorelease];
   [fadeAnim setAnimationObject:layer];
   [seq addAnimation:fadeAnim];

   // Reset position + opacity (instant), then hold before next loop
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   slideAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:onFrame
          endRectValue:offFrame
               options:&opts] autorelease];
   [slideAnim setAnimationObject:layer];
   [seq addAnimation:slideAnim];

   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   fadeAnim = [[[CABasicAnimation alloc]
      initWithProperty:opacityProperty
       startFloatValue:0.0
         endFloatValue:1.0
               options:&opts] autorelease];
   [fadeAnim setAnimationObject:layer];
   [seq addAnimation:fadeAnim];

   // Pre-loop pause (0.7s)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.7),
      1.0, NO);
   slideAnim = [[[CABasicAnimation alloc]
      initWithProperty:opacityProperty
       startFloatValue:1.0
         endFloatValue:1.0
               options:&opts] autorelease];
   [slideAnim setAnimationObject:layer];
   [seq addAnimation:slideAnim];

   [layer addAnimation:seq];
}


#pragma mark - Effect 8: Color Cycle Badge

//
// A badge that smoothly cycles through saturated game colors:
// red → orange → yellow → green → cyan → blue → magenta → red
// Uses a sequence of color transitions, looping forever.
//
static void   setupColorCycle( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           frame;
   CABasicAnimation                 *anim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;
   CGColor                          colors[8];
   NSUInteger                       i;

   frame = centeredBox( cell, CGSizeMake( 50, 50));
   layer = [CGGraphicsLayer layerWithFrame:frame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.2, 0.2, 1.0)];
   [layer setCornerRadius:10.0];
   [[window contentView] addLayer:layer];

   property = MulleObjCInstanceSearchProperty( layer, @selector( backgroundColor));

   // Saturated game palette
   colors[0] = CGColorMakeWithRGBA( 1.0, 0.2, 0.2, 1.0);   // red
   colors[1] = CGColorMakeWithRGBA( 1.0, 0.6, 0.1, 1.0);   // orange
   colors[2] = CGColorMakeWithRGBA( 1.0, 0.9, 0.1, 1.0);   // yellow
   colors[3] = CGColorMakeWithRGBA( 0.2, 0.9, 0.3, 1.0);   // green
   colors[4] = CGColorMakeWithRGBA( 0.1, 0.9, 0.9, 1.0);   // cyan
   colors[5] = CGColorMakeWithRGBA( 0.3, 0.4, 1.0, 1.0);   // blue
   colors[6] = CGColorMakeWithRGBA( 0.8, 0.2, 1.0, 1.0);   // magenta
   colors[7] = CGColorMakeWithRGBA( 1.0, 0.2, 0.2, 1.0);   // back to red

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   for( i = 0; i < 7; i++)
   {
      opts = CABasicAnimationOptionsMakeLinear(
         mulle_relativetimerange_make( 0, 0.5),
         1.0, NO);
      anim = [[[CABasicAnimation alloc]
         initWithProperty:property
          startColorValue:colors[ i]
            endColorValue:colors[ i + 1]
                  options:&opts] autorelease];
      [anim setAnimationObject:layer];
      [seq addAnimation:anim];
   }

   [layer addAnimation:seq];
}


#pragma mark - Effect 9: Shake / Reject

//
// Rapid horizontal shake — the "wrong password" or "nope" feedback.
// Quick oscillation with decreasing amplitude via a sequence of
// short frame animations.
//
static void   setupShakeReject( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           restFrame;
   CGRect                           leftFrame;
   CGRect                           rightFrame;
   CABasicAnimation                 *anim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;
   CGFloat                          offsets[] = { 12, -12, 8, -8, 5, -5, 2, -2, 0 };
   NSUInteger                       i;

   restFrame = centeredBox( cell, CGSizeMake( 80, 32));

   layer = [CGGraphicsLayer layerWithFrame:restFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.85, 0.15, 0.15, 1.0)];
   [layer setCornerRadius:6.0];
   [[window contentView] addLayer:layer];

   property = MulleObjCInstanceSearchProperty( layer, @selector( frame));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Shake oscillations with decreasing amplitude
   leftFrame = restFrame;
   for( i = 0; i < 9; i++)
   {
      rightFrame = CGRectOffset( restFrame, offsets[i], 0);
      opts = CABasicAnimationOptionsMakeLinear(
         mulle_relativetimerange_make( 0, 0.04),
         1.0, NO);
      anim = [[[CABasicAnimation alloc]
         initWithProperty:property
           startRectValue:leftFrame
             endRectValue:rightFrame
                  options:&opts] autorelease];
      [anim setAnimationObject:layer];
      [seq addAnimation:anim];
      leftFrame = rightFrame;
   }

   // Hold at rest 2.0s before next shake
   [seq addPause:2.0];

   [layer addAnimation:seq];
}


#pragma mark - Effect 10: Loot Drop

//
// Item drops from above with gravity (easeInQuadratic fall),
// then bounces on landing (easeOutBounce). Classic loot/item pickup.
//
static void   setupLootDrop( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           topFrame;
   CGRect                           landFrame;
   CABasicAnimation                 *fallAnim;
   CABasicAnimation                 *holdAnim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *frameProperty;
   struct CABasicAnimationOptions   opts;

   landFrame = centeredBox( cell, CGSizeMake( 30, 30));
   landFrame.origin.y = cell.origin.y + cell.size.height - 45;
   topFrame  = landFrame;
   topFrame.origin.y  = cell.origin.y + 5;

   layer = [CGGraphicsLayer layerWithFrame:topFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.6, 0.3, 1.0, 1.0)];
   [layer setCornerRadius:4.0];
   [[window contentView] addLayer:layer];

   frameProperty = MulleObjCInstanceSearchProperty( layer, @selector( frame));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Fall + bounce (1.0s easeOutBounce — single animation does gravity + bounce)
   opts = CABasicAnimationOptionsMakeTween(
      mulle_relativetimerange_make( 0, 1.0),
      CATweenEaseOutBounce,
      1.0, NO);
   fallAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:topFrame
          endRectValue:landFrame
               options:&opts] autorelease];
   [fallAnim setAnimationObject:layer];
   [seq addAnimation:fallAnim];

   // Hold at landing (1.0s)
   [seq addPause:1.0];

   // Reset to top (instant)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   holdAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:landFrame
          endRectValue:topFrame
               options:&opts] autorelease];
   [holdAnim setAnimationObject:layer];
   [seq addAnimation:holdAnim];

   // Pause at top (0.5s)
   [seq addPause:0.5];

   [layer addAnimation:seq];
}


#pragma mark - Effect 11: XP Bar Fill

//
// Progress bar fills from 0% to 100% width with satisfying easeOutQuartic
// deceleration. Classic RPG experience bar.
//
static void   setupXPBarFill( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *track;
   CGGraphicsLayer                  *fill;
   CGRect                           trackFrame;
   CGRect                           emptyFrame;
   CGRect                           fullFrame;
   CABasicAnimation                 *anim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;

   trackFrame = centeredBox( cell, CGSizeMake( 110, 16));

   // Track background (dark)
   track = [CGGraphicsLayer layerWithFrame:trackFrame];
   [track setBackgroundColor:CGColorMakeWithRGBA( 0.15, 0.15, 0.2, 1.0)];
   [track setCornerRadius:8.0];
   [[window contentView] addLayer:track];

   // Fill bar (starts empty)
   emptyFrame = CGRectMake( trackFrame.origin.x + 2, trackFrame.origin.y + 2,
                            4, trackFrame.size.height - 4);
   fullFrame  = CGRectMake( trackFrame.origin.x + 2, trackFrame.origin.y + 2,
                            trackFrame.size.width - 4, trackFrame.size.height - 4);

   fill = [CGGraphicsLayer layerWithFrame:emptyFrame];
   [fill setBackgroundColor:CGColorMakeWithRGBA( 0.2, 0.9, 0.4, 1.0)];
   [fill setCornerRadius:6.0];
   [[window contentView] addLayer:fill];

   property = MulleObjCInstanceSearchProperty( fill, @selector( frame));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Fill up (1.5s easeOutQuartic — fast start, slow satisfying finish)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 1.5),
      CAAnimationCurveEaseOutQuartic,
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:emptyFrame
          endRectValue:fullFrame
               options:&opts] autorelease];
   [anim setAnimationObject:fill];
   [seq addAnimation:anim];

   // Hold full (1.0s)
   [seq addPause:1.0];

   // Reset to empty (instant)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:fullFrame
          endRectValue:emptyFrame
               options:&opts] autorelease];
   [anim setAnimationObject:fill];
   [seq addAnimation:anim];

   // Pause before refill (0.5s)
   [seq addPause:0.5];

   [fill addAnimation:seq];
}


#pragma mark - Effect 12: Star Burst

//
// 5 small squares explode outward from center on different circular paths,
// then fade out and reset. Simulates reward particle burst.
//
static void   setupStarBurst( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *particle;
   CGPoint                          center;
   CGRect                           startFrame;
   CGRect                           endFrame;
   CGFloat                          angle;
   CGFloat                          radius;
   CABasicAnimation                 *moveAnim;
   struct _mulle_objc_property      *frameProperty;
   struct CABasicAnimationOptions   opts;
   NSUInteger                       i;
   CGColor                          particleColors[5];

   center = CGRectGetCenter( cell);
   radius = 45.0;

   particleColors[0] = CGColorMakeWithRGBA( 1.0, 0.9, 0.2, 1.0);  // gold
   particleColors[1] = CGColorMakeWithRGBA( 1.0, 0.4, 0.1, 1.0);  // orange
   particleColors[2] = CGColorMakeWithRGBA( 0.3, 1.0, 0.5, 1.0);  // green
   particleColors[3] = CGColorMakeWithRGBA( 0.4, 0.6, 1.0, 1.0);  // blue
   particleColors[4] = CGColorMakeWithRGBA( 1.0, 0.3, 0.7, 1.0);  // pink

   for( i = 0; i < 5; i++)
   {
      CAAnimationSequence              *seq;

      angle = (CGFloat) i * (2.0 * M_PI / 5.0) - M_PI / 2.0;

      startFrame = CGRectMake( center.x - 5, center.y - 5, 10, 10);
      endFrame   = CGRectMake( center.x + radius * cos( angle) - 5,
                               center.y + radius * sin( angle) - 5,
                               10, 10);

      particle = [CGGraphicsLayer layerWithFrame:startFrame];
      [particle setBackgroundColor:particleColors[i]];
      [particle setCornerRadius:5.0];
      [[window contentView] addLayer:particle];

      frameProperty = MulleObjCInstanceSearchProperty( particle, @selector( frame));

      // Each particle: explode out (0.5s) then snap back (0.01s) then wait (1.5s)
      seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
         &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

      // Move outward (0.5s easeOutQuintic)
      opts = CABasicAnimationOptionsMakeCurve(
         mulle_relativetimerange_make( 0, 0.5),
         CAAnimationCurveEaseOutQuintic,
         1.0, NO);
      moveAnim = [[[CABasicAnimation alloc]
         initWithProperty:frameProperty
           startRectValue:startFrame
             endRectValue:endFrame
                  options:&opts] autorelease];
      [moveAnim setAnimationObject:particle];
      [seq addAnimation:moveAnim];

      // Snap back instantly (0.01s)
      opts = CABasicAnimationOptionsMakeLinear(
         mulle_relativetimerange_make( 0, 0.01),
         1.0, NO);
      moveAnim = [[[CABasicAnimation alloc]
         initWithProperty:frameProperty
           startRectValue:endFrame
             endRectValue:startFrame
                  options:&opts] autorelease];
      [moveAnim setAnimationObject:particle];
      [seq addAnimation:moveAnim];

      // Hold at center (1.49s padding)
      [seq addPause:1.49];

      [particle addAnimation:seq];
   }
}


#pragma mark - Effect 13: Typewriter Reveal

//
// Text range expands character by character using NSRange animation.
// Simulates typewriter text reveal common in RPG dialog.
// We animate an integer property as a proxy (visible character count).
//
static void   setupTypewriter( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGGraphicsLayer                  *cursor;
   CGRect                           frame;
   CGRect                           cursorFrame;
   CABasicAnimation                 *anim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;
   CGFloat                          startWidth;
   CGFloat                          endWidth;

   // Dark "terminal" background
   frame = centeredBox( cell, CGSizeMake( 100, 24));
   layer = [CGGraphicsLayer layerWithFrame:frame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.12, 0.12, 0.18, 1.0)];
   [layer setBorderWidth:1.0];
   [layer setBorderColor:CGColorMakeWithRGBA( 0.3, 0.9, 0.3, 1.0)];
   [[window contentView] addLayer:layer];

   // Green "text" bar that grows in width to simulate typing
   startWidth = 4.0;
   endWidth   = 88.0;
   cursorFrame = CGRectMake( frame.origin.x + 6,
                             frame.origin.y + 6,
                             startWidth,
                             12);
   cursor = [CGGraphicsLayer layerWithFrame:cursorFrame];
   [cursor setBackgroundColor:CGColorMakeWithRGBA( 0.3, 0.9, 0.3, 0.9)];
   [[window contentView] addLayer:cursor];

   property = MulleObjCInstanceSearchProperty( cursor, @selector( frame));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // Type out: width grows in steps (1.2s linear — discrete look from quantization)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 1.2),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:cursorFrame
          endRectValue:CGRectMake( cursorFrame.origin.x,
                                   cursorFrame.origin.y,
                                   endWidth,
                                   12)
               options:&opts] autorelease];
   [anim setAnimationObject:cursor];
   [seq addAnimation:anim];

   // Hold full (0.8s)
   [seq addPause:0.8];

   // Clear: shrink back (0.1s)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.1),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:CGRectMake( cursorFrame.origin.x,
                                   cursorFrame.origin.y,
                                   endWidth,
                                   12)
          endRectValue:cursorFrame
               options:&opts] autorelease];
   [anim setAnimationObject:cursor];
   [seq addAnimation:anim];

   // Pause before next line (0.9s)
   [seq addPause:0.9];

   [cursor addAnimation:seq];
}


#pragma mark - Effect 14: Breathing Idle

//
// Subtle size oscillation — the idle character "breathing" effect.
// Very gentle frame expansion/contraction with slow easeInOutSine.
//
static void   setupBreathingIdle( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           restFrame;
   CGRect                           breathFrame;
   CABasicAnimation                 *anim;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;

   restFrame   = centeredBox( cell, CGSizeMake( 44, 56));
   breathFrame = CGRectInset( restFrame, -8, -10);

   layer = [CGGraphicsLayer layerWithFrame:restFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.3, 0.6, 0.9, 1.0)];
   [layer setCornerRadius:8.0];
   [[window contentView] addLayer:layer];

   property = MulleObjCInstanceSearchProperty( layer, @selector( frame));

   // Gentle oscillation (2.5s easeInOutSine, forever, autoreverses)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 2.5),
      CAAnimationCurveEaseInOutSine,
      INFINITY, YES);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:restFrame
          endRectValue:breathFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];

   [layer addAnimation:anim];
}


#pragma mark - Effect 15: Slam Down

//
// Object slams from top with fast easeIn (gravity), brief squash on impact,
// then a tiny settle bounce. Visceral impact feel.
//
static void   setupSlamDown( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           topFrame;
   CGRect                           landFrame;
   CGRect                           squashFrame;
   CABasicAnimation                 *anim;
   CAAnimationSequence              *seq;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   opts;

   landFrame   = centeredBox( cell, CGSizeMake( 50, 50));
   landFrame.origin.y = cell.origin.y + cell.size.height - 60;
   topFrame    = landFrame;
   topFrame.origin.y = cell.origin.y + 5;
   squashFrame = CGRectMake( landFrame.origin.x - 8,
                             landFrame.origin.y + 15,
                             landFrame.size.width + 16,
                             landFrame.size.height - 15);

   layer = [CGGraphicsLayer layerWithFrame:topFrame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.9, 0.5, 0.1, 1.0)];
   [layer setCornerRadius:6.0];
   [[window contentView] addLayer:layer];

   property = MulleObjCInstanceSearchProperty( layer, @selector( frame));

   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];

   // SLAM down (0.25s easeInQuintic — starts slow, hits HARD)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.25),
      CAAnimationCurveEaseInQuintic,
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:topFrame
          endRectValue:landFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Impact squash (0.06s — instant flatten)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.06),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:landFrame
          endRectValue:squashFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Settle back with elastic overshoot (0.4s)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.4),
      CAAnimationCurveEaseOutElastic,
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:squashFrame
          endRectValue:landFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Hold (1.2s)
   [seq addPause:1.2];

   // Reset to top (instant)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.01),
      1.0, NO);
   anim = [[[CABasicAnimation alloc]
      initWithProperty:property
        startRectValue:landFrame
          endRectValue:topFrame
               options:&opts] autorelease];
   [anim setAnimationObject:layer];
   [seq addAnimation:anim];

   // Pre-slam pause (0.6s)
   [seq addPause:0.6];

   [layer addAnimation:seq];
}


#pragma mark - Effect 16: Victory Spin

//
// Trophy layer follows a figure-8 path with color flashing between
// gold and white. Celebratory victory screen effect.
//
static void   setupVictorySpin( UIWindow *window, CGRect cell)
{
   CGGraphicsLayer                  *layer;
   CGRect                           frame;
   CGPoint                          center;
   CGPath                           *path;
   CGPoint                          upperCenter;
   CGPoint                          lowerCenter;
   CGFloat                          radius;
   CAPathAnimation                  *pathAnim;
   CABasicAnimation                 *colorAnim;
   CABasicAnimation                 *scaleAnim;
   CAAnimationGroup                 *group;
   struct _mulle_objc_property      *poseProperty;
   struct _mulle_objc_property      *colorProperty;
   struct _mulle_objc_property      *frameProperty;
   struct CABasicAnimationOptions   opts;

   center = CGRectGetCenter( cell);
   radius = 35.0;
   frame  = CGRectMake( center.x - 12, center.y - 12, 24, 24);

   layer = [CGGraphicsLayer layerWithFrame:frame];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.84, 0.0, 1.0)];
   [layer setCornerRadius:4.0];
   [[window contentView] addLayer:layer];

   // Figure-8 path
   path = CGPathCreate( NULL);
   upperCenter = CGPointMake( center.x, center.y - radius / 2);
   lowerCenter = CGPointMake( center.x, center.y + radius / 2);
   CGPathMoveToPoint( path, center);
   CGPathAddArcWithCenter( path, upperCenter, radius / 2,
                           CARadiansToAngle( M_PI_f / 2), 1.0);
   CGPathAddArcWithCenter( path, lowerCenter, radius / 2,
                           CARadiansToAngle( -M_PI_f / 2), -1.0);

   poseProperty  = MulleObjCInstanceSearchProperty( layer, @selector( pose));
   colorProperty = MulleObjCInstanceSearchProperty( layer, @selector( backgroundColor));
   frameProperty = MulleObjCInstanceSearchProperty( layer, @selector( frame));

   // Path animation (3s loop)
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 3.0),
      INFINITY, NO);
   pathAnim = [[[CAPathAnimation alloc]
      initWithProperty:poseProperty
                  path:path
         pathValueType:CAPathAnimationValuePose
               options:&opts] autorelease];
   [pathAnim setAnimationObject:layer];

   // Color flash: gold ↔ white (0.4s, forever, autoreverses)
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 0.4),
      CAAnimationCurveEaseInOutSine,
      INFINITY, YES);
   colorAnim = [[[CABasicAnimation alloc]
      initWithProperty:colorProperty
       startColorValue:CGColorMakeWithRGBA( 1.0, 0.84, 0.0, 1.0)
         endColorValue:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)
               options:&opts] autorelease];
   [colorAnim setAnimationObject:layer];

   // Additive scale pulse: adds size delta on top of current frame
   // from (0,0,0,0) to (-8,-8,+16,+16) — grows 8px each side
   opts = CABasicAnimationOptionsMakeCurve(
      mulle_relativetimerange_make( 0, 1.5),
      CAAnimationCurveEaseInOutSine,
      INFINITY, YES);
   opts.base.bits |= CAAnimationAdditive;
   scaleAnim = [[[CABasicAnimation alloc]
      initWithProperty:frameProperty
        startRectValue:CGRectMake( 0, 0, 0, 0)
          endRectValue:CGRectMake( -8, -8, 16, 16)
               options:&opts] autorelease];
   [scaleAnim setAnimationObject:layer];

   // Group all three in parallel
   group = [[[CAAnimationGroup alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];
   [group addAnimation:pathAnim];
   [group addAnimation:colorAnim];
   [group addAnimation:scaleAnim];

   [layer addAnimation:group];
}


#pragma mark - Scene Setup

static void   setupScene( UIWindow *window, unsigned int mask)
{
   CGRect   canvas;
   CGRect   cell;

   canvas = [[window contentView] contentRect];

   if( mask & (1 << 0))
   {
      cell = cellFrameAtIndex( 0, canvas);
      setupShineSweep( window, cell);
   }
   if( mask & (1 << 1))
   {
      cell = cellFrameAtIndex( 1, canvas);
      setupRocketOrbit( window, cell);
   }
   if( mask & (1 << 2))
   {
      cell = cellFrameAtIndex( 2, canvas);
      setupBouncingButton( window, cell);
   }
   if( mask & (1 << 3))
   {
      cell = cellFrameAtIndex( 3, canvas);
      setupSquashStretch( window, cell);
   }
   if( mask & (1 << 4))
   {
      cell = cellFrameAtIndex( 4, canvas);
      setupPulseGlow( window, cell);
   }
   if( mask & (1 << 5))
   {
      cell = cellFrameAtIndex( 5, canvas);
      setupCoinSpin( window, cell);
   }
   if( mask & (1 << 6))
   {
      cell = cellFrameAtIndex( 6, canvas);
      setupSlideInBanner( window, cell);
   }
   if( mask & (1 << 7))
   {
      cell = cellFrameAtIndex( 7, canvas);
      setupColorCycle( window, cell);
   }
   if( mask & (1 << 8))
   {
      cell = cellFrameAtIndex( 8, canvas);
      setupShakeReject( window, cell);
   }
   if( mask & (1 << 9))
   {
      cell = cellFrameAtIndex( 9, canvas);
      setupLootDrop( window, cell);
   }
   if( mask & (1 << 10))
   {
      cell = cellFrameAtIndex( 10, canvas);
      setupXPBarFill( window, cell);
   }
   if( mask & (1 << 11))
   {
      cell = cellFrameAtIndex( 11, canvas);
      setupStarBurst( window, cell);
   }
   if( mask & (1 << 12))
   {
      cell = cellFrameAtIndex( 12, canvas);
      setupTypewriter( window, cell);
   }
   if( mask & (1 << 13))
   {
      cell = cellFrameAtIndex( 13, canvas);
      setupBreathingIdle( window, cell);
   }
   if( mask & (1 << 14))
   {
      cell = cellFrameAtIndex( 14, canvas);
      setupSlamDown( window, cell);
   }
   if( mask & (1 << 15))
   {
      cell = cellFrameAtIndex( 15, canvas);
      setupVictorySpin( window, cell);
   }
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   unsigned int    mask;

   // mask: each bit enables one effect (0-15). default: all on.
   // pass as first argument, e.g. "0x5" for effects 0 and 2
   mask = 0xFFFF;
   if( argc > 1)
      mask = (unsigned int) strtoul( argv[1], NULL, 0);

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      [window setBackgroundColor:CGColorMakeWithRGBA( 0.05, 0.05, 0.1, 1.0)];

      setupScene( window, mask);

      [app addWindow:window];
   }
   return( [app runApp]);
}
