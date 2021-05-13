#import "CAAnimation.h"


enum CAAnimationCurve
{
   CAAnimationCurveEaseInOut,
   CAAnimationCurveEaseIn,
   CAAnimationCurveEaseOut,
   CAAnimationCurveLinear
};


MulleQuadratic   MulleQuadraticForAnimationCurve( enum CAAnimationCurve curvetype);


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
   MulleQuadratic              curve;
};


//
// TODO: interpolating RGB is easy, but not necessarily very nice looking.
//       Possibly implement http://labs.adamluptak.com/javascript-color-blending/
//       though it is costly
//       HSV seems like a cheaper and probably more gainly alternative
//
@interface CABasicAnimation : CAAnimation
{
   enum CAAnimationValueType   _valueType;
   union CAAnimationValue      _start;
   union CAAnimationValue      _end;
   union CAAnimationValue      _repeatStart;

   MulleQuadratic              _quadratic;
   SEL                         _propertySetter;
}

//
// You can reuse an existing CAAnimation by calling init again
// Could/maybe should generalize this with NSValue ?
//
- (id) initWithPropertySetter:(SEL) propertySetter
                    valueType:(enum CAAnimationValueType) type
                   valueRange:(struct CAAnimationValueRange *) range
                  repeatStart:(union CAAnimationValue) repeatStart
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                    startRect:(CGRect) start
                      endRect:(CGRect) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
              startEdgeInsets:(MulleEdgeInsets) start
                endEdgeInsets:(MulleEdgeInsets) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                    startSize:(CGSize) start
                      endSize:(CGSize) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                   startPoint:(CGPoint) start
                     endPoint:(CGPoint) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
              startFloatValue:(CGFloat) start
                endFloatValue:(CGFloat) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
                   startRange:(NSRange) start
                     endRange:(NSRange) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
            startIntegerValue:(NSInteger) start
              endIntegerValue:(NSInteger) end
                      options:(struct CABasicAnimationOptions *) options;

- (id) initWithPropertySetter:(SEL) propertySetter
               startBOOLValue:(BOOL) start
                 endBOOLValue:(BOOL) end
                      options:(struct CABasicAnimationOptions *) options;

@end

