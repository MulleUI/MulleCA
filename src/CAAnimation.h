#import "import.h"

#import "CGBase.h"
#import "CGGeometry.h"
#import "CGColor.h"
#import "CATime.h"
#import "MulleEdgeInsets.h"


enum CAAnimationCurve
{
   CAAnimationCurveEaseInOut,
   CAAnimationCurveEaseIn,
   CAAnimationCurveEaseOut,
   CAAnimationCurveLinear
};


MulleQuadratic   MulleQuadraticForAnimationCurve( enum CAAnimationCurve curvetype);


enum CAAnimationBits
{
   CAAnimationStarted     = 0x1,
   CAAnimationHasReversed = 0x2,
   CAAnimationEnded       = 0x4,
   // options
   CAAnimationReverses    = 0x10000
};



// stuff to animate:
//  CGPoint
//  CGColor
//  CGFloat
//  CGRect
//  BOOL
// none of these values are retain/release
//
// Should generalize this to array of float/int/bool ?
//
union CAAnimationValue
{
   BOOL              boolValue;        // 0 1
   NSInteger         integerValue;     // a 32 or 64 bit integer
   NSRange           range;            // two 32 or 64 bit integers
   CGFloat           floatValue;       // a 32 bit float usually
   CGColorRef        color;            // four floats
   CGPoint           point;            // two floats
   CGSize            size;             // two floats
   CGRect            rect;             // four floats
   MulleEdgeInsets   insets;           // four floats
};


static inline union CAAnimationValue
   CGAnimationValueMakeWithRect( CGRect rect)
{
   union CAAnimationValue  value;

   value.rect = rect;
   return( value);
}

static inline union CAAnimationValue
   CGAnimationValueMakeWithColor( CGColorRef color)
{
   union CAAnimationValue  value;

   value.color = color;
   return( value);
}


struct CAAnimationValueRange
{
   union CAAnimationValue   start;
   union CAAnimationValue   end;
};


static inline struct CAAnimationValueRange
   CGAnimationValueRangeMakeWithRects( CGRect start, CGRect end)
{
   struct CAAnimationValueRange  range;

   range.start.rect = start;
   range.end.rect   = end;
   return( range);
}

static inline struct CAAnimationValueRange
   CGAnimationValueRangeMakeWithColors( CGColorRef start, CGColorRef end)
{
   struct CAAnimationValueRange  range;

   range.start.color = start;
   range.end.color   = end;
   return( range);
}


enum CAAnimationValueType
{
   CAAnimationValueUndefined,
   CAAnimationValueBOOL,
   CAAnimationValueNSInteger,
   CAAnimationValueNSRange,
   CAAnimationValueCGFloat,
   CAAnimationValueCGColorRef,
   CAAnimationValueCGPoint,
   CAAnimationValueCGSize,
   CAAnimationValueCGRect,
   CAAnimationValueEdgeInsets
};


struct CAAnimationOptions
{
   struct CARelativeTimeRange    timeRange;
   CGFloat                       repeatCount;
   MulleQuadratic                curve;
   NSUInteger                    bits;  // reverse flag mainly
};



@class CALayer;

// All animations in one UIView beginAnimations:context: have the
// same duration and start and repeatCount

@interface MulleAnimationDelegate : NSObject

@property( assign) id     delegate;
@property( assign) SEL    animationWillStartSelector;
@property( assign) SEL    animationDidStopSelector;
@property( assign) void   *context;
@property( assign) char   *identifier;

@property( assign) NSUInteger  started;
@property( assign) NSUInteger  ended;

- (void) willStart;
- (void) didPreempt;
- (void) didEnd;

@end


@protocol CAAnimatableObject

- (void) animateWithAbsoluteTime:(CAAbsoluteTime) time;

@end


//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly alternative
//
@interface CAAnimation : NSObject <NSCopying>
{
   struct CARelativeTimeRange   _relative;  // delay, copied from initialRenderdelay
   enum CAAnimationValueType    _valueType;
   union CAAnimationValue       _start;
   union CAAnimationValue       _end;
   union CAAnimationValue       _repeatStart;
   CGFloat                      _originalRepeatCount;

   MulleQuadratic               _quadratic;
   SEL                          _propertySetter;

   // mutating state
   struct CAAbsoluteTimeRange   _absolute;
   CGFloat                      _repeatCount; // original state will be lost
   NSUInteger                   _bits;        // options and more
   NSUInteger                   _frames;
}

//@property( retain) CAAnimationGroup        *animationGroup;
@property( retain) MulleAnimationDelegate  *animationDelegate;

//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
- (id) initWithPropertySetter:(SEL) propertySetter
                    valueType:(enum CAAnimationValueType) type
                   valueRange:(struct CAAnimationValueRange *) range
                  repeatStart:(union CAAnimationValue) repeatStart
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                   startColor:(CGColorRef) start
                     endColor:(CGColorRef) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                    startRect:(CGRect) start
                      endRect:(CGRect) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
              startEdgeInsets:(MulleEdgeInsets) start
                endEdgeInsets:(MulleEdgeInsets) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                    startSize:(CGSize) start
                      endSize:(CGSize) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                   startPoint:(CGPoint) start
                     endPoint:(CGPoint) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
              startFloatValue:(CGFloat) start
                endFloatValue:(CGFloat) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                   startRange:(NSRange) start
                     endRange:(NSRange) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
            startIntegerValue:(NSInteger) start
              endIntegerValue:(NSInteger) end
                      options:(struct CAAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
               startBOOLValue:(BOOL) start
                 endBOOLValue:(BOOL) end
                      options:(struct CAAnimationOptions *) options;


- (void) animateObject:(id) object
          absoluteTime:(CAAbsoluteTime) now;

// subclass must override this method, to do their special effect
- (void) animateObject:(id) object
normalizedRelativeTime:(double) x;

+ (void) animateObjects:(struct mulle_pointerarray *) objects
           absoluteTime:(CAAbsoluteTime) renderTime;

// used if options are set to CAAnimationReverses (and CAAnimationRepeats)
- (void) reverse;

// animation will start again with values as given
- (void) reset;

@end

