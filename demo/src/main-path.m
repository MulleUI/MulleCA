#import "import-private.h"

#include <math.h>

#define DO_FRAME_ANIMATION   0  // Set to 1 to enable 2 animations as frame only
#define DO_PATH_ANIMATION    1  // Set to 1 to enable animations
#define DO_COLOR_ANIMATION   1  // Set to 1 to enable animations

#define ENABLE_CIRCLE   1
#define ENABLE_EIGHT    1
#define ENABLE_SINE     1
#define ENABLE_STAR     1

#define TRACE           0


@interface Layer : CAShapeLayer
@end


@implementation Layer

- (void) setPose:(CAPose) pose
{
#if TRACE
   mulle_fprintf( stderr, "%#@: %s %s\n", self, __FUNCTION__, CAPoseUTF8String( pose));
#endif
   [super setPose:pose];
}

- (void) setFrame:(CGRect) frame
{
#if TRACE
   mulle_fprintf( stderr, "%#@: %s %s\n", self, __FUNCTION__, CGRectUTF8String( frame));
#endif
   [super setFrame:frame];
}


- (void) renderInContext:(CGContext *) context
{
   [super renderInContext:context];
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGAffineTransform   xform;

   xform = CGContextCurrentTransform( context);

#if TRACE
   mulle_fprintf( stderr, "%#@: %s f: %s  b: %s  c: %s  r: %.2g  xform: %s\n",
                           self,
                           __FUNCTION__,
                           CGRectUTF8String( [self frame]),
                           CGRectUTF8String( [self bounds]),
                           CGRectUTF8String( [self canvas]),
                           [self rotation],
                           CGAffineTransformUTF8String( &xform));
#endif

#ifdef DEBUG_BOUNDS
   CGContextStrokeRectWithColor( context, [self bounds], 1.0f, CGColorMakeChartreuse());
   CGContextStrokeRectWithColor( context, [self canvas], 1.0f, CGColorMakeDodgerBlue());
#endif

   return( [super drawInContext:context]);
}

@end


// Helper function to create a simple circle path
static CGPath *createCirclePath( CGPoint center, CGFloat radius)
{
   CGPath *path;

   path = CGPathCreate( NULL);
   CGPathAddArcWithCenter( path, center, radius, 0.0, 1.0);
   return( path);
}

// Helper function to create a figure-8 path using two connected arcs
static CGPath *createFigure8Path( CGPoint center, CGFloat radius)
{
   CGPoint   lowerCenter;
   CGPath    *path;
   CGPoint   upperCenter;

   path = CGPathCreate( NULL);

   // Calculate centers for the two loops of the figure-8
   upperCenter = CGPointMake( center.x, center.y - radius/2);
   lowerCenter = CGPointMake( center.x, center.y + radius/2);

   // Start at the center intersection point
   CGPathMoveToPoint( path, center);

   // First arc - upper loop, starting from bottom going clockwise
   CGPathAddArcWithCenter( path, upperCenter, radius/2, CARadiansToAngle( M_PI_f/2), 1.0);

   // Second arc - lower loop, starting from top going counter-clockwise
   CGPathAddArcWithCenter( path, lowerCenter, radius/2, CARadiansToAngle( -M_PI_f/2), -1.0);

   return( path);
}

// Helper function to create a sine wave path
// why not use bezier ? anyway...
static CGPath *createSineWavePath( CGRect bounds)
{
   CGFloat          amplitude;
   CGFloat          frequency;
   CGFloat          height;
   int              i;
   CGPath           *path;
   CGPoint          point;
   CGPoint          startPoint;
   CGFloat          width;
   CGFloat          x;
   CGFloat          y;

   path      = CGPathCreate( NULL);
   width     = CGRectGetWidth( bounds);
   height    = CGRectGetHeight( bounds);
   amplitude = height * 0.3;
   frequency = 2.0;

   startPoint = CGPointMake( bounds.origin.x, bounds.origin.y + height/2);
   CGPathMoveToPoint( path, startPoint);

   for( i = 1; i <= 100; i++)
   {
      x     = bounds.origin.x + (width * i / 100.0);
      y     = bounds.origin.y + height/2 + amplitude * sin( frequency * M_PI_f * i / 100.0);
      point = CGPointMake( x, y);
      CGPathAddLineToPoint( path, point);
   }
   // CGPathCloseSubpath( path);

   return( path);
}

// Helper function to create a star path
static CGPath   *createStarPath( CGPoint center, CGFloat radius)
{
   CGFloat   angle;
   int       i;
   CGPath    *path;
   CGPoint   points[10]; // 5 outer points + 5 inner points
   CGFloat   r;

   path = CGPathCreate( NULL);

   // Create a 5-pointed star by connecting every second point
   for( i = 0; i < 10; i++)
   {
      angle     = (i * M_PI_f) / 5.0;
      r         = (i % 2 == 0) ? radius : radius * 0.5;
      points[i] = CGPointMake(
         center.x + r * cos( angle - M_PI_f/2),
         center.y + r * sin( angle - M_PI_f/2)
      );
   }

   // Start at first outer point and connect alternating outer/inner points
   CGPathMoveToPoint( path, points[0]);
   for( i = 1; i < 10; i++)
   {
      CGPathAddLineToPoint( path, points[i]);
   }
   CGPathCloseSubpath( path);
   //CGPathAddLineToPoint( path, points[0]); // Close the star

   return( path);
}


static CGPath   *createTrianglePath( CGRect bounds)
{
   CGPath   *path;
   CGPoint  p1;
   CGPoint  p2;
   CGPoint  p3;

   path = CGPathCreate( NULL);
   p1   = CGPointMake( CGRectGetMidX( bounds), CGRectGetMinY( bounds));
   p2   = CGPointMake( CGRectGetMaxX( bounds), CGRectGetMaxY( bounds));
   p3   = CGPointMake( CGRectGetMinX( bounds), CGRectGetMaxY( bounds));

   CGPathMoveToPoint(path, p1);
   CGPathAddLineToPoint(path, p2);
   CGPathAddLineToPoint(path, p3);
   CGPathCloseSubpath(path);

   return( path);
}


#define numLayers 4


static CGRect   cellFrameAtIndex( NSUInteger i, CGRect canvas)
{
   CGRect   frame;
   CGRect   cellFrame;
   CGFloat  cellWidth;
   CGFloat  cellHeight;

   assert( i < 4);

   frame = UIEdgeInsetsInsetRect( canvas, UIEdgeInsetsMake( 50, 50, 50, 50));

   // Calculate grid layout (same as setupScene)
   cellWidth  = CGRectGetWidth( frame) / 2;
   cellHeight = CGRectGetHeight( frame) / 2;

   cellFrame.size     = CGSizeMake( cellWidth, cellHeight);
   cellFrame.origin.x = frame.origin.x + (i % 2) * cellWidth;
   cellFrame.origin.y = frame.origin.y + (i / 2) * cellHeight;

   return( cellFrame);
}


static CGPath   *pathAtIndex( NSUInteger i, CGRect cellFrame)
{
   CGPath    *path;
   CGPoint   center;
   CGFloat   cellWidth;
   CGFloat   cellHeight;

   center     = CGRectGetCenter( cellFrame);
   cellWidth  = cellFrame.size.width;
   cellHeight = cellFrame.size.height;

   path = NULL;
      // Create different paths for each quadrant
   switch( i)
   {
   case 0:
#if ENABLE_CIRCLE
      path = createCirclePath( center, CGFloatMinimum( cellWidth, cellHeight) * 0.3);
#endif
      break;
   case 1:
#if ENABLE_EIGHT
      path = createFigure8Path( center, CGFloatMinimum( cellWidth, cellHeight) * 0.3);
#endif
      break;
   case 2:
#if ENABLE_SINE
      path = createSineWavePath( CGRectInset( cellFrame, cellWidth*0.1, cellHeight*0.3));
#endif
      break;
   case 3:
#if ENABLE_STAR
      path = createStarPath( center, CGFloatMinimum( cellWidth, cellHeight) * 0.3);
#endif
      break;
   }
   return( path);
}


static char   *labelAtIndex( NSUInteger  i)
{
   switch( i)
   {
   case 0: return( "circle");
   case 1: return( "eight");
   case 2: return( "sine");
   case 3: return( "star");
   }
   return( "???");
}


// Drawing callback to show the animation paths
static BOOL   drawPaths( CGGraphicsLayer *layer, CGContext *context)
{
   CGPath       *path;
   CGRect       cellFrame;
   NSUInteger   i;

   for( i = 0; i < numLayers; i++)
   {
      cellFrame = cellFrameAtIndex( i, [layer canvas]);
      path      = pathAtIndex( i, cellFrame);
      if( ! path)
         continue;

      CGContextStrokeRectWithColor( context, cellFrame, 1.0, CGColorMakeWithRGBA( 0.8, 0.8, 0.8, 1.0)); // Light gray

      CGContextBeginPath( context);
      CGContextAddCGPath( context, path);
      CGContextFillColor( context, CGColorMakeWithRGBA( 0.7, 0.7, 0.7, 1.0));
      CGContextFill( context);

      CGContextStrokeColor( context, CGColorMakeWithRGBA( 0.3, 0.3, 0.3, 1.0)); // Dark gray
      CGContextStrokeWidth( context, 1.0);
      CGContextStroke( context);

      CGPathDestroy( path);
   }

   return( YES);
}


static void   setupScene( UIWindow *window)
{
   CABasicAnimation                 *colorAnimation;
   CAPathAnimation                  *pathAnimation;
   CAPathAnimationValueType         pathValueType;
   CGGraphicsLayer                  *layer;
   CGPath                           *path;
   CGPoint                          center;
   CGRect                           cellFrame;
   CGRect                           frame;
   NSUInteger                       i;
   char                             *label;
   struct _mulle_objc_property      *colorProperty;
   struct _mulle_objc_property      *pathProperty;
   struct CABasicAnimationOptions   colorOptions;
   struct CABasicAnimationOptions   pathOptions;
   UIView                           *view;

   view = [window contentView];
   assert( view);

   for( i = 0; i < numLayers; i++)
   {
      cellFrame = cellFrameAtIndex( i, [view contentRect]);
      path      = pathAtIndex( i, cellFrame);
      if( ! path)
         continue;

      label  = labelAtIndex( i);
      center = CGRectGetCenter( cellFrame);
      frame  = CGRectMake( center.x - 10, center.y - 10, 20, 20);

      layer = [Layer layerWithFrame:frame];
      [layer setNameUTF8String:label];
      [layer setPath:createTrianglePath( [layer canvas])];
#ifdef DEBUG_BOUNDS
      // [layer setMasksToBounds:NO];
      [layer setBackgroundColor:CGColorMakeWithRGBA( 0.3, 0.3, 0.3, 0.5)];
#endif
      [view addLayer:layer];

#if DO_COLOR_ANIMATION
      // Color animation (keep this - it's working)
      colorProperty = MulleObjCInstanceSearchProperty( layer, @selector( fillColor));
      if( colorProperty)
      {
         colorOptions = CABasicAnimationOptionsMakeEaseInOut(
            mulle_relativetimerange_make( 0.0, 2.0),
            INFINITY,
            YES
         );
         colorAnimation = [[[CABasicAnimation alloc]
            initWithProperty:colorProperty
              startColorValue:CGColorMakeWithRGBA( 1.0, 0.0, 0.0, 1.0)  // red
                endColorValue:CGColorMakeWithRGBA( 0.0, 0.0, 1.0, 1.0)  // blue
                      options:&colorOptions] autorelease];
         [colorAnimation setAnimationObject:layer];
         [[window postLayoutAnimator] addAnimation:colorAnimation];
      }
#endif

#if DO_PATH_ANIMATION
      pathProperty  = MulleObjCInstanceSearchProperty( layer, @selector( pose));
      pathValueType = CAPathAnimationValuePose;
#if DO_FRAME_ANIMATION
      if( i < 2)
      {
         // First two layers (circle, figure-8): animate pose (center follows path + rotation)
         // Last two layers (sine wave, star): animate frame origin
         pathProperty  = MulleObjCInstanceSearchProperty( layer, @selector( frame));
         pathValueType = CAPathAnimationValuePositionAsOrigin;
      }
#endif
      if( pathProperty && path)
      {
         pathOptions = CABasicAnimationOptionsMakeEaseInOut(
            mulle_relativetimerange_make( 0.0, 4.0),
            INFINITY,
            YES
         );
         pathAnimation = [[[CAPathAnimation alloc]
            initWithProperty:pathProperty
                        path:path
               pathValueType:pathValueType
                     options:&pathOptions] autorelease];
         [pathAnimation setAnimationObject:layer];
         [[window postLayoutAnimator] addAnimation:pathAnimation];
      }
#endif
   }
}


int main(int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   NSUInteger      styleMask;

   app       = [UIApplication sharedInstance];
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStylePlanes, NO);

   window    = [UIWindow windowWithFrame:CGRectMake(0.0, 0.0, 800.0, 600.0)
                         titleUTF8String:"Demo"
                               styleMask:styleMask];
   assert( window);

   [window setBackgroundColor:CGColorMakeWithRGBA(1.0, 1.0, 1.0, 1.0)];
   [window setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawPaths];

   setupScene(window);

   [app addWindow:window];

   return [app runApp];
}
