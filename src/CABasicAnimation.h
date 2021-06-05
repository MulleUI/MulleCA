#import "CAAnimation.h"

#import "CATransaction.h"  // for tweenfunction
#import "CAQuadratic.h"  // for tweenfunction


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


enum CAAnimationCurve
{
   CAAnimationCurveEaseInOut,
   CAAnimationCurveEaseIn,
   CAAnimationCurveEaseOut,
   CAAnimationCurveLinear
};


static inline CAQuadratic
   CAQuadraticForAnimationCurve( enum CAAnimationCurve curvetype)
{
   CAQuadratic   quadratic;

   switch( curvetype)
   {
   case CAAnimationCurveEaseInOut:
      return( CAQuadraticEaseInOut);

   case CAAnimationCurveEaseOut:
      return( CAQuadraticEaseOut);

   case CAAnimationCurveEaseIn:
      return( CAQuadraticEaseIn);

   default :
      return( CAQuadraticLinear);
   }
}



struct CAAnimationFloat2
{
   CGFloat   v[ 2];
};


struct CAAnimationFloat4
{
   CGFloat   v[ 4];
};


union CAAnimationValue
{
   BOOL                       boolValue;        // 0 1
   NSInteger                  integerValue;     // a 32 or 64 bit integer
   NSRange                    rangeValue;       // two 32 or 64 bit integers (special semantics)
   CGFloat                    floatValue;       // a 32 bit float usually

   struct CAAnimationFloat2   float2Value;  // a 32 bit float usually
   struct CAAnimationFloat4   float4Value;  // a 32 bit float usually
//   CGColorRef        color;          // four floats
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


enum CAAnimationValueType
{
   CAAnimationValueUndefined,

   CAAnimationValueBOOL,
   CAAnimationValueNSInteger,
   CAAnimationValueNSRange,
   CAAnimationValueCGFloat,
   CAAnimationValueCGFloat2,
   CAAnimationValueCGFloat4
};


enum
{
   CAAnimationValueCGPoint = CAAnimationValueCGFloat2
};
enum
{
   CAAnimationValueCGSize = CAAnimationValueCGFloat2
};
enum
{
   CAAnimationValueCGRect = CAAnimationValueCGFloat4
};
enum
{
   CAAnimationValueEdgeInsets = CAAnimationValueCGFloat4
};



struct CABasicAnimationOptions
{
   struct CAAnimationOptions   base;
   enum CAAnimationCurve       curve;
   CATweenFunction             *tween;
};


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeTween( struct CARelativeTimeRange timeRange,
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


static inline struct CABasicAnimationOptions
   CABasicAnimationOptionsMakeCurve( struct CARelativeTimeRange timeRange,
                                     CGFloat repeatCount,
                                     NSUInteger bits,
                                     enum CAAnimationCurve curve)
{
   return( (struct CABasicAnimationOptions)
           {
              .base  = CAAnimationOptionsMake( timeRange, repeatCount, bits),
              .curve = curve,
              .tween = 0
            });
}



//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly looking alternative
//
@interface CABasicAnimation : CAAnimation
{
   enum CAAnimationValueType     _valueType;
   union CAAnimationValue        _start;
   union CAAnimationValue        _end;
   union CAAnimationValue        _repeatStart;

   CAQuadratic                   _quadratic;
   CATweenFunction               *_tween;
   struct _mulle_objc_property   *_property;
}

//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
- (id) initWithProperty:(struct _mulle_objc_property *) property
              valueType:(enum CAAnimationValueType) type
             valueRange:(struct CAAnimationValueRange *) range
            repeatStart:(union CAAnimationValue) repeatStart
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
- (BOOL) isAdditive;  // TODO: move this to options?

@end


