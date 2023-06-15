#import "CAAnimation.h"

#import "CATransaction.h"  // for tweenfunction




#define CAInterpolateAdditive( start, end, x) \
   ( (x) * ((end) - (start)) )


#define CAInterpolate( start, end, x)  \
   ( (start) + CAInterpolateAdditive( start, end, x) )

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
   CAAnimationValueNSInteger,
   CAAnimationValueNSRange,
   CAAnimationValueCGFloat,
   CAAnimationValueCGFloat2,
   CAAnimationValueCGFloat4,
   CAAnimationValueFloatArray,
// just some aliases
   CAAnimationValueCGPoint    = CAAnimationValueCGFloat2,
   CAAnimationValueCGSize     = CAAnimationValueCGFloat2,
   CAAnimationValueCGRect     = CAAnimationValueCGFloat4,
   CAAnimationValueEdgeInsets = CAAnimationValueCGFloat4
};


struct CAAnimationFloat2
{
   CGFloat   v[ 2];
};


static inline char  *CAAnimationFloat2UTF8String( struct CAAnimationFloat2 value)
{
   return( MulleObjC_asprintf( "[%g %g]", value.v[ 0],
                                          value.v[ 1]));
}


struct CAAnimationFloat4
{
   CGFloat   v[ 4];
};


static inline char  *CAAnimationFloat4UTF8String( struct CAAnimationFloat4 value)
{
   return( MulleObjC_asprintf( "[%g %g %g %g]", value.v[ 0],
                                                value.v[ 1],
                                                value.v[ 2],
                                                value.v[ 3]));
}

MULLE_CA_EXTERN_GLOBAL
char  *CAAnimationFloatArrayUTF8String( struct mulle__floatarray value);


union CAAnimationValue
{
   BOOL                       boolValue;        // 0 1
   NSInteger                  integerValue;     // a 32 or 64 bit integer
   NSRange                    rangeValue;       // two 32 or 64 bit integers (special semantics)
   CGFloat                    floatValue;       // a 32 bit float usually

   struct CAAnimationFloat2   float2Value;  // a 32 bit float usually
   struct CAAnimationFloat4   float4Value;  // a 32 bit float usually
   struct mulle__floatarray   floatArray;
//   CGColor        color;          // four floats
};


static inline union CAAnimationValue
   CGAnimationValueMakeWithVector( CGVector vector)
{
   union CAAnimationValue  value;

   *(CGVector *) &value.float2Value = vector;
   return( value);
}


static inline union CAAnimationValue
   CGAnimationValueMakeWithPoint( CGPoint point)
{
   union CAAnimationValue   value;

   *(CGPoint *) &value.float2Value = point;
   return( value);
}


static inline union CAAnimationValue
   CGAnimationValueMakeWithSize( CGSize size)
{
   union CAAnimationValue   value;

   *(CGSize *) &value.float2Value = size;
   return( value);
}


static inline union CAAnimationValue
   CGAnimationValueMakeWithRect( CGRect rect)
{
   union CAAnimationValue   value;

   *(CGRect *) &value.float4Value = rect;
   return( value);
}


static inline union CAAnimationValue
   CGAnimationValueMakeWithEdgeInsets( MulleEdgeInsets insets)
{
   union CAAnimationValue   value;

   *(MulleEdgeInsets *) &value.float4Value = insets;
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


// the "default" constructor
static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeCurve( struct mulle_relativetimerange timeRange,
                                     CGFloat repeatCount,
                                     NSUInteger bits,
                                     CAAnimationCurve curve)
{
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange, repeatCount, bits),
              .curve = curve,
              .tween = 0
            });
}


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeTween( struct mulle_relativetimerange timeRange,
                                     CGFloat repeatCount,
                                     NSUInteger bits,
                                     CATweenFunction tween)
{
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange, repeatCount, bits),
              .curve = 0,
              .tween = tween
            });
}



// conveniences
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
                                               repeatCount,
                                               reverses ? CAAnimationReverses : 0),
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
                                               0),
              .curve = CAAnimationCurveEaseOut,
              .tween = 0
            });
}



#define CA_BASIC_ANIMATION_OPTIONS_INIT_CURVE( vdelay, vduration, vrepeat, vbits, vcurve) \
   ((struct CABasicAnimationOptions)                                                      \
   {                                                                                      \
      /* base */                                                                          \
      .base = CA_ANIMATION_OPTIONS_INIT( (vdelay), (vduration), (vrepeat), (vbits)),      \
      /* curve */                                                                         \
      .curve = (vcurve),                                                                  \
      .tween = 0                                                                          \
   })                                                                                  


#define CA_BASIC_ANIMATION_OPTIONS_INIT_TWEEN( vdelay, vduration, vrepeat, vbits, vtween) \
   ((struct CABasicAnimationOptions)                                                      \
   {                                                                                      \
      /* base */                                                                          \
      .base = CA_ANIMATION_OPTIONS_INIT( (vdelay), (vduration), (vrepeat), (vbits)),      \
      /* curve */                                                                         \
      .curve = 0,                                                                         \
      .tween = (vtween)                                                                   \
   })                                                                                  

char  *CABasicAnimationOptionsUTF8String( struct CABasicAnimationOptions *options);


@class CABasicAnimation;


typedef void  CABasicAnimationInterpolator( CABasicAnimation *, id, double);
typedef char  *CAAnimationValueUTF8Printer( union CAAnimationValue);

//
// this is a simple extension interface to add more definitions.
// you have to invent a type integer that doesn't conflict with the others
// CAAnimationValueType and other extensions
//
struct CABasicAnimationTypeDefinition
{
   NSUInteger                     type;
   char                           *name;
   CABasicAnimationInterpolator   *interpolate;
   CABasicAnimationInterpolator   *interpolateAdditive;
   CAAnimationValueUTF8Printer    *valueUTF8String;
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
   CABasicAnimationInterpolator  *_interpolate;
   CABasicAnimationInterpolator  *_interpolateAdditive;
   CAAnimationValueType          _valueType;
   union CAAnimationValue        _start;
   union CAAnimationValue        _end;
   // for additive that's the previous difference we added
   union CAAnimationValue        _previous;

   CAQuadratic                   _quadratic;
   CATweenFunction               *_tween;
   struct _mulle_objc_property   *_property;
}

//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
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
   startFloatArrayValue:(struct mulle__floatarray) start
     endFloatArrayValue:(struct mulle__floatarray) end
                options:(struct CABasicAnimationOptions *) options;

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startFloatValue:(CGFloat) start
          endFloatValue:(CGFloat) end
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


