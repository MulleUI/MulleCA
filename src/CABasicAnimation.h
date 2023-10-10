#import "CAAnimation.h"

#import "CATransaction.h"  // for tweenfunction



// The implicit conversion to "signedness" by using double, is important
// here. This is probably not a static inline function, to avoid casting
// so much, but not sure anymore.
#define CAInterpolateAdditive( start, end, x) \
   ( (double) (x) * ((double) (end) - (double) (start)) )


#define CAInterpolate( start, end, x)  \
   ( (start) + CAInterpolateAdditive( start, end, x) )



//
// length is interpolated length:
// (NSUInteger) round( CAInterpolate( startLength, endLength, x));
// mode is any of 0, CAAnimationStickyArrayCenter CAAnimationStickyArrayEnd
//
MULLE_CA_EXTERN_GLOBAL
NSInteger   CAArrayIndexForInterpolation( NSUInteger startLength,
                                          NSUInteger length,
                                          NSUInteger mode);

MULLE_CA_EXTERN_GLOBAL
NSInteger   CAInterpolatedArrayIndex( NSUInteger startLength,
                                      NSUInteger endLength,
                                      double x,
                                      NSUInteger mode);

//
//       Moving to NSValue could be cleaner, but is problematic for CGColor.
//       There are really no operations on NSValue which help.
//
// Actual CGColor code is in MulleGraphics for dependency reasons

// The basic animation has a definitive starting value and and end value
// and it interpolates from start to the end. The end value is set at the
// end "as is", so there is no accumulated interpolation error.
//
// An basic animation does not "mix" well with another basic animation of
// the same property.
//
//
// This is how animations look like  "in flight", they stick to a layer and
// they share an animation group. The CAAnimationGroup is fairly boring
// and important though and may even be missing for animations, that are not
// created during a CATransaction.
//
//  .---------.    .------------------.    .------------------.
//  | CALayer |--->| CABasicAnimation |--->| CAAnimationGroup |
//  '---------'    '------------------'    '------------------'
//       |         .------------------.              ^
//       '-------->| CABasicAnimation |--------------'
//                 '------------------'
//

typedef NS_ENUM( NSUInteger, CAAnimationCurve)
{
   CAAnimationCurveEaseInOut,
   CAAnimationCurveEaseIn,
   CAAnimationCurveEaseOut,
   CAAnimationCurveLinear
};


static inline char  *CAAnimationCurveUTF8String(CAAnimationCurve curve)
{
   switch( curve)
   {
   case CAAnimationCurveEaseInOut : return( "CAAnimationCurveEaseInOut");
   case CAAnimationCurveEaseIn    : return( "CAAnimationCurveEaseIn");
   case CAAnimationCurveEaseOut   : return( "CAAnimationCurveEaseOut");
   case CAAnimationCurveLinear    : return( "CAAnimationCurveLinear");
   default                        : return( "???");
   }
}


static inline CAQuadratic
   CAQuadraticForAnimationCurve( CAAnimationCurve curvetype)
{
   switch( curvetype)
   {
   case CAAnimationCurveEaseInOut : return( CAQuadraticEaseInOut);
   case CAAnimationCurveEaseOut   : return( CAQuadraticEaseOut);
   case CAAnimationCurveEaseIn    : return( CAQuadraticEaseIn);
   default                        : return( CAQuadraticLinear);
   }
}


typedef NS_ENUM( NSInteger, CAAnimationValueType)
{
   CAAnimationValueUndefined,

   CAAnimationValueBOOL,
   CAAnimationValueNSInteger,  // TODO: CAAnimationValueNSUInteger
   CAAnimationValueNSRange,
   CAAnimationValueCGFloat,
   CAAnimationValueCGFloat2,
   CAAnimationValueCGFloat4,
   CAAnimationValueFloatArray,
   CAAnimationValueObject,
// just some aliases
   CAAnimationValueCACircle     = CAAnimationValueCGFloat2,
   CAAnimationValueCGPoint      = CAAnimationValueCGFloat2,
   CAAnimationValueCGSize       = CAAnimationValueCGFloat2,
   CAAnimationValueCGRect       = CAAnimationValueCGFloat4,
   CAAnimationValueEdgeInsets   = CAAnimationValueCGFloat4,
   CAAnimationValueCornerInsets = CAAnimationValueCGFloat4
};

#define CAAnimationValueTypeLastBuiltIn   CAAnimationValueObject




MULLE_CA_EXTERN_GLOBAL
char  *CAAnimationFloatArrayUTF8String( struct mulle__floatarray value);

struct CABasicAnimationOptions;

@protocol CAInterpolatableValue < NSCopying, NSObject>

// standard interpolation: self + (end - self) * x;
// additive interpolation (1): (end - self) * x (is diff)
- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive;

// additive interpolation (2): self - previous + diff
- (id) interpolatedValueWithDiff:(id) diff
                    previousDiff:(id) previous;  // previous will be nil the first call!

@end


union CAAnimationValue
{
   BOOL                        boolValue;        // 0 1
   NSInteger                   integerValue;     // a 32 or 64 bit integer
   NSRange                     rangeValue;       // two 32 or 64 bit integers (special semantics)
   CGFloat                     floatValue;       // a 32 bit float usually

   struct CGFloat2             float2Value;      // 2 32 bit float usually
   struct CGFloat4             float4Value;      // 4 32 bit float usually
   struct mulle__floatarray    floatArray;

   id <CAInterpolatableValue>  objectValue;
//   CGColor        color;          // four floats
};


static inline union CAAnimationValue
   CAAnimationValueMakeWithVector( CGVector vector)
{
   union CAAnimationValue  value;

   *(CGVector *) &value.float2Value = vector;
   return( value);
}


static inline union CAAnimationValue
   CAAnimationValueMakeWithPoint( CGPoint point)
{
   union CAAnimationValue   value;

   *(CGPoint *) &value.float2Value = point;
   return( value);
}


static inline union CAAnimationValue
   CAAnimationValueMakeWithSize( CGSize size)
{
   union CAAnimationValue   value;

   *(CGSize *) &value.float2Value = size;
   return( value);
}


static inline union CAAnimationValue
   CAAnimationValueMakeWithRect( CGRect rect)
{
   union CAAnimationValue   value;

   *(CGRect *) &value.float4Value = rect;
   return( value);
}


static inline union CAAnimationValue
   CAAnimationValueMakeWithEdgeInsets( MulleEdgeInsets insets)
{
   union CAAnimationValue   value;

   *(MulleEdgeInsets *) &value.float4Value = insets;
   return( value);
}



static inline union CAAnimationValue
   CAAnimationValueMakeWithObject( id<NSCopying> obj)
{
   union CAAnimationValue   value;

   value.objectValue = [obj copy];
   return( value);
}


char  *CAAnimationValueUTF8String( union CAAnimationValue value,
                                   CAAnimationValueType type);


struct CAAnimationValueRange
{
   union CAAnimationValue   start;
   union CAAnimationValue   end;
};


static inline struct CAAnimationValueRange
   CGAnimationValueRangeMake( union CAAnimationValue start,
                              union CAAnimationValue end)
{
   return( (struct CAAnimationValueRange) { .start = start, .end = end });
}


char  *CAAnimationValueRangeUTF8String( struct CAAnimationValueRange *range,
                                        CAAnimationValueType type);


struct CABasicAnimationOptions
{
   struct CAAnimationOptions   base;
   CAAnimationCurve            curve;
   CATweenFunction             *tween;
};


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMake( struct CAAnimationOptions base,
                                CAAnimationCurve curve,
                                CATweenFunction *tween)
{
   return( (struct CABasicAnimationOptions)
           {
              .base  = base,
              .curve = curve,
              .tween = tween
           });
}


// these options are not in the constructors, because they are reasonably
// rare and remembering the order as well as the meaning of the constants
// gets some
static inline void
   CABasicAnimationOptionsSetOffset( struct CABasicAnimationOptions *options,
                                     float offset)
{
   if( ! options)
      return;
   CAAnimationOptionsSetOffset( &options->base, offset);
}

static inline void
   CABasicAnimationOptionsSetRepeatCount( struct CABasicAnimationOptions *options,
                                          float repeatCount)
{
   if( ! options)
      return;
   CAAnimationOptionsSetRepeatCount( &options->base, repeatCount);
}


static inline void
   CABasicAnimationOptionsSetBit( struct CABasicAnimationOptions *options,
                                   NSUInteger  bit)
{
   if( ! options)
      return;
   CAAnimationOptionsSetBit( &options->base, bit);
}

static inline void
   CABasicAnimationOptionsClearBit( struct CABasicAnimationOptions *options,
                                    NSUInteger  bit)
{
   if( ! options)
      return;
   CAAnimationOptionsClearBit( &options->base, bit);
}


// conveniences
static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeCurve( struct mulle_relativetimerange timeRange,
                                     CAAnimationCurve curve,
                                     CGFloat repeatCount,
                                     BOOL reverses)
{
   if( reverses && repeatCount == 0.0)
      repeatCount = INFINITY;
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange,
                                               0.0,
                                               repeatCount,
                                               reverses
                                               ? CAAnimationReverses
                                               : 0),
              .curve = curve,
              .tween = 0
            });
}


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeTween( struct mulle_relativetimerange timeRange,
                                     CATweenFunction tween,
                                     CGFloat repeatCount,
                                     BOOL reverses)
{
   if( reverses && repeatCount == 0.0)
      repeatCount = INFINITY;
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange,
                                               0.0,
                                               repeatCount,
                                               reverses
                                               ? CAAnimationReverses
                                               : 0),
              .curve = 0,
              .tween = tween
            });
}



static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeLinear( struct mulle_relativetimerange timeRange,
                                      CGFloat repeatCount,
                                      BOOL reverses)
{
   if( reverses && repeatCount == 0.0)
      repeatCount = INFINITY;
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange,
                                               0.0,
                                               repeatCount,
                                               reverses
                                               ? CAAnimationReverses
                                               : 0),
              .curve = CAAnimationCurveLinear,
              .tween = 0
            });
}


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeEaseInOut( struct mulle_relativetimerange timeRange,
                                         CGFloat repeatCount,
                                         BOOL reverses)
{
   if( reverses && repeatCount == 0.0)
      repeatCount = INFINITY;
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange,
                                               0.0,
                                               repeatCount,
                                               reverses ? CAAnimationReverses : 0),
              .curve = CAAnimationCurveEaseInOut,
              .tween = 0
            });
}


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeEaseIn( struct mulle_relativetimerange timeRange)
{
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange,
                                               0.0,
                                               1.0,
                                               0),
              .curve = CAAnimationCurveEaseIn,
              .tween = 0
            });
}


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeEaseOut( struct mulle_relativetimerange timeRange)
{
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange,
                                               0.0,
                                               1.0,
                                               0),
              .curve = CAAnimationCurveEaseOut,
              .tween = 0
            });
}



#define CA_BASIC_ANIMATION_OPTIONS_INIT_CURVE( vdelay, vduration, voffset, vrepeat, vbits, vcurve)  \
   ((struct CABasicAnimationOptions)                                                                \
   {                                                                                                \
      /* base */                                                                                    \
      .base = CA_ANIMATION_OPTIONS_INIT( (vdelay), (vduration), (voffset), (vrepeat), (vbits)),     \
      /* curve */                                                                                   \
      .curve = (vcurve),                                                                            \
      .tween = 0                                                                                    \
   })                                                                                  


#define CA_BASIC_ANIMATION_OPTIONS_INIT_TWEEN( vdelay, vduration, voffset, vrepeat, vbits, vtween) \
   ((struct CABasicAnimationOptions)                                                               \
   {                                                                                               \
      /* base */                                                                                   \
      .base = CA_ANIMATION_OPTIONS_INIT( (vdelay), (vduration), (voffset), (vrepeat), (vbits)),    \
      /* curve */                                                                                  \
      .curve = 0,                                                                                  \
      .tween = (vtween)                                                                            \
   })                                                                                  

char  *CABasicAnimationOptionsUTF8String( struct CABasicAnimationOptions *options);


@class CABasicAnimation;


typedef void  CABasicAnimationInterpolator_t( CABasicAnimation *, id, double);
typedef char  *CAAnimationValueUTF8Printer( union CAAnimationValue);

//
// this is a simple extension interface to add more definitions.
// you have to invent a type integer that doesn't conflict with the others
// CAAnimationValueType and other extensions
//
struct CABasicAnimationTypeDefinition
{
   NSUInteger                       type;
   char                             *name;
   CABasicAnimationInterpolator_t   *interpolate;
   CABasicAnimationInterpolator_t   *interpolateAdditive;
   CAAnimationValueUTF8Printer      *valueUTF8String;
};

// run this during +initialize or +load
void  CABasicAnimationTypeDefinitionRegister( struct CABasicAnimationTypeDefinition *definition);

MULLE_C_CONST_NONNULL_RETURN
struct CABasicAnimationTypeDefinition
      *CABasicAnimationTypeDefinitionGet( CAAnimationValueType type);


static inline char  *CAAnimationValueTypeUTF8String( CAAnimationValueType type)
{
   return( CABasicAnimationTypeDefinitionGet( type)->name);
}



@interface CABasicAnimation : CAAnimation
{
   CABasicAnimationInterpolator_t   *_interpolate;
   CABasicAnimationInterpolator_t   *_interpolateAdditive;

   // for additive that's the previous difference we added,
   // but it might be better to store the lastValue and not the diff,
   // for objects we could then just mutate some properties and not
   // allocate new stuff
   union CAAnimationValue           _previous;
}

@property( readonly) union CAAnimationValue        start;
@property( readonly) union CAAnimationValue        end;

@property( readonly) struct _mulle_objc_property   *property;
@property( readonly) CATweenFunction               *tween;
@property( readonly) CAQuadratic                   quadratic;
@property( readonly) CAAnimationValueType          valueType;

//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
// If you use this API directly, you probably also need to
// call -setAnimationObject:
//
- (id) initWithProperty:(struct _mulle_objc_property *) property
              valueType:(CAAnimationValueType) type
             valueRange:(struct CAAnimationValueRange *) range
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
         startRectValue:(CGRect) start
           endRectValue:(CGRect) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
   startEdgeInsetsValue:(MulleEdgeInsets) start
     endEdgeInsetsValue:(MulleEdgeInsets) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
         startSizeValue:(CGSize) start
           endSizeValue:(CGSize) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startPointValue:(CGPoint) start
          endPointValue:(CGPoint) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startFloatValue:(CGFloat) start
          endFloatValue:(CGFloat) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
       startFloat2Value:(CGFloat2) start
         endFloat2Value:(CGFloat2) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
       startFloat4Value:(CGFloat4) start
         endFloat4Value:(CGFloat4) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
   startFloatArrayValue:(struct mulle__floatarray) start
     endFloatArrayValue:(struct mulle__floatarray) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
       startObjectValue:(id <CAInterpolatableValue>) start
         endObjectValue:(id <CAInterpolatableValue>) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startRangeValue:(NSRange) start
          endRangeValue:(NSRange) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
      startIntegerValue:(NSInteger) start
        endIntegerValue:(NSInteger) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
         startBOOLValue:(BOOL) start
           endBOOLValue:(BOOL) end
                options:(struct CABasicAnimationOptions *) options;


//
// interpolated values aren't SET on the object, but the objects value
// is read and the change is added to the value and the SET. This makes
// multiple animations mixable, but will add interpolation errors.
//
- (BOOL) isAdditive;
- (BOOL) isCumulative;

@end



@interface NSObject( CABasicAnimation)

// it's not necessary to return a CABasicAnimation, it can be a custom
// animation
+ (CAAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                       startObjectValue:(id <CAInterpolatableValue>) start
                         endObjectValue:(id <CAInterpolatableValue>) end
                                options:(struct CABasicAnimationOptions *) options;

@end


void   CABasicAnimationSetInterpolatedFloatAdditive( CABasicAnimation *self,
                                                     id object,
                                                     double x);

void   CABasicAnimationSetInterpolatedFloat2Additive( CABasicAnimation *self,
                                                      id object,
                                                      double x);

void   CABasicAnimationSetInterpolatedFloat4Additive( CABasicAnimation *self,
                                                      id object,
                                                      double x);