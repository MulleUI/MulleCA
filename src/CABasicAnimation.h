//
//  CABasicAnimation.h
//  MulleCA
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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
MULLE_CA_GLOBAL
NSInteger   CAArrayIndexForInterpolation( NSUInteger startLength,
                                          NSUInteger length,
                                          NSUInteger mode);

MULLE_CA_GLOBAL
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
   CAAnimationCurveLinear,

   // append-only: keep legacy values above stable
   CAAnimationCurveEaseInQuadratic,
   CAAnimationCurveEaseOutQuadratic,
   CAAnimationCurveEaseInOutQuadratic,

   CAAnimationCurveEaseInCubic,
   CAAnimationCurveEaseOutCubic,
   CAAnimationCurveEaseInOutCubic,

   CAAnimationCurveEaseInQuartic,
   CAAnimationCurveEaseOutQuartic,
   CAAnimationCurveEaseInOutQuartic,

   CAAnimationCurveEaseInQuintic,
   CAAnimationCurveEaseOutQuintic,
   CAAnimationCurveEaseInOutQuintic,

   CAAnimationCurveEaseInSine,
   CAAnimationCurveEaseOutSine,
   CAAnimationCurveEaseInOutSine,

   CAAnimationCurveEaseInExponential,
   CAAnimationCurveEaseOutExponential,
   CAAnimationCurveEaseInOutExponential,

   CAAnimationCurveEaseInCircular,
   CAAnimationCurveEaseOutCircular,
   CAAnimationCurveEaseInOutCircular,

   CAAnimationCurveEaseInBack,
   CAAnimationCurveEaseOutBack,
   CAAnimationCurveEaseInOutBack,

   CAAnimationCurveEaseInBounce,
   CAAnimationCurveEaseOutBounce,
   CAAnimationCurveEaseInOutBounce,

   CAAnimationCurveEaseInElastic,
   CAAnimationCurveEaseOutElastic,
   CAAnimationCurveEaseInOutElastic
};


static inline char  *CAAnimationCurveUTF8String(CAAnimationCurve curve)
{
   switch( curve)
   {
   case CAAnimationCurveEaseInOut            : return( "CAAnimationCurveEaseInOut");
   case CAAnimationCurveEaseIn               : return( "CAAnimationCurveEaseIn");
   case CAAnimationCurveEaseOut              : return( "CAAnimationCurveEaseOut");
   case CAAnimationCurveLinear               : return( "CAAnimationCurveLinear");
   case CAAnimationCurveEaseInQuadratic      : return( "CAAnimationCurveEaseInQuadratic");
   case CAAnimationCurveEaseOutQuadratic     : return( "CAAnimationCurveEaseOutQuadratic");
   case CAAnimationCurveEaseInOutQuadratic   : return( "CAAnimationCurveEaseInOutQuadratic");
   case CAAnimationCurveEaseInCubic          : return( "CAAnimationCurveEaseInCubic");
   case CAAnimationCurveEaseOutCubic         : return( "CAAnimationCurveEaseOutCubic");
   case CAAnimationCurveEaseInOutCubic       : return( "CAAnimationCurveEaseInOutCubic");
   case CAAnimationCurveEaseInQuartic        : return( "CAAnimationCurveEaseInQuartic");
   case CAAnimationCurveEaseOutQuartic       : return( "CAAnimationCurveEaseOutQuartic");
   case CAAnimationCurveEaseInOutQuartic     : return( "CAAnimationCurveEaseInOutQuartic");
   case CAAnimationCurveEaseInQuintic        : return( "CAAnimationCurveEaseInQuintic");
   case CAAnimationCurveEaseOutQuintic       : return( "CAAnimationCurveEaseOutQuintic");
   case CAAnimationCurveEaseInOutQuintic     : return( "CAAnimationCurveEaseInOutQuintic");
   case CAAnimationCurveEaseInSine           : return( "CAAnimationCurveEaseInSine");
   case CAAnimationCurveEaseOutSine          : return( "CAAnimationCurveEaseOutSine");
   case CAAnimationCurveEaseInOutSine        : return( "CAAnimationCurveEaseInOutSine");
   case CAAnimationCurveEaseInExponential    : return( "CAAnimationCurveEaseInExponential");
   case CAAnimationCurveEaseOutExponential   : return( "CAAnimationCurveEaseOutExponential");
   case CAAnimationCurveEaseInOutExponential : return( "CAAnimationCurveEaseInOutExponential");
   case CAAnimationCurveEaseInCircular       : return( "CAAnimationCurveEaseInCircular");
   case CAAnimationCurveEaseOutCircular      : return( "CAAnimationCurveEaseOutCircular");
   case CAAnimationCurveEaseInOutCircular    : return( "CAAnimationCurveEaseInOutCircular");
   case CAAnimationCurveEaseInBack           : return( "CAAnimationCurveEaseInBack");
   case CAAnimationCurveEaseOutBack          : return( "CAAnimationCurveEaseOutBack");
   case CAAnimationCurveEaseInOutBack        : return( "CAAnimationCurveEaseInOutBack");
   case CAAnimationCurveEaseInBounce         : return( "CAAnimationCurveEaseInBounce");
   case CAAnimationCurveEaseOutBounce        : return( "CAAnimationCurveEaseOutBounce");
   case CAAnimationCurveEaseInOutBounce      : return( "CAAnimationCurveEaseInOutBounce");
   case CAAnimationCurveEaseInElastic        : return( "CAAnimationCurveEaseInElastic");
   case CAAnimationCurveEaseOutElastic       : return( "CAAnimationCurveEaseOutElastic");
   case CAAnimationCurveEaseInOutElastic     : return( "CAAnimationCurveEaseInOutElastic");
   default                                   : return( "???");
   }
}


static inline CACubic
   CACubicForAnimationCurve( CAAnimationCurve curvetype)
{
   switch( curvetype)
   {
   case CAAnimationCurveEaseInOut : return( CACubicEaseInOut);
   case CAAnimationCurveEaseOut   : return( CACubicEaseOut);
   case CAAnimationCurveEaseIn    : return( CACubicEaseIn);
   default                        : return( CACubicLinear);
   }
}


static inline CATweenFunction   *
   CATweenForAnimationCurve( CAAnimationCurve curvetype)
{
   switch( curvetype)
   {
   case CAAnimationCurveEaseInQuadratic      : return( CATweenEaseInQuadratic);
   case CAAnimationCurveEaseOutQuadratic     : return( CATweenEaseOutQuadratic);
   case CAAnimationCurveEaseInOutQuadratic   : return( CATweenEaseInOutQuadratic);
   case CAAnimationCurveEaseInCubic          : return( CATweenEaseInCubic);
   case CAAnimationCurveEaseOutCubic         : return( CATweenEaseOutCubic);
   case CAAnimationCurveEaseInOutCubic       : return( CATweenEaseInOutCubic);
   case CAAnimationCurveEaseInQuartic        : return( CATweenEaseInQuartic);
   case CAAnimationCurveEaseOutQuartic       : return( CATweenEaseOutQuartic);
   case CAAnimationCurveEaseInOutQuartic     : return( CATweenEaseInOutQuartic);
   case CAAnimationCurveEaseInQuintic        : return( CATweenEaseInQuintic);
   case CAAnimationCurveEaseOutQuintic       : return( CATweenEaseOutQuintic);
   case CAAnimationCurveEaseInOutQuintic     : return( CATweenEaseInOutQuintic);
   case CAAnimationCurveEaseInSine           : return( CATweenEaseInSine);
   case CAAnimationCurveEaseOutSine          : return( CATweenEaseOutSine);
   case CAAnimationCurveEaseInOutSine        : return( CATweenEaseInOutSine);
   case CAAnimationCurveEaseInExponential    : return( CATweenEaseInExponential);
   case CAAnimationCurveEaseOutExponential   : return( CATweenEaseOutExponential);
   case CAAnimationCurveEaseInOutExponential : return( CATweenEaseInOutExponential);
   case CAAnimationCurveEaseInCircular       : return( CATweenEaseInCircular);
   case CAAnimationCurveEaseOutCircular      : return( CATweenEaseOutCircular);
   case CAAnimationCurveEaseInOutCircular    : return( CATweenEaseInOutCircular);
   case CAAnimationCurveEaseInBack           : return( CATweenEaseInBack);
   case CAAnimationCurveEaseOutBack          : return( CATweenEaseOutBack);
   case CAAnimationCurveEaseInOutBack        : return( CATweenEaseInOutBack);
   case CAAnimationCurveEaseInBounce         : return( CATweenEaseInBounce);
   case CAAnimationCurveEaseOutBounce        : return( CATweenEaseOutBounce);
   case CAAnimationCurveEaseInOutBounce      : return( CATweenEaseInOutBounce);
   case CAAnimationCurveEaseInElastic        : return( CATweenEaseInElastic);
   case CAAnimationCurveEaseOutElastic       : return( CATweenEaseOutElastic);
   case CAAnimationCurveEaseInOutElastic     : return( CATweenEaseInOutElastic);
   default                                   : return( NULL);
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




MULLE_CA_GLOBAL
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


MULLE_CA_GLOBAL
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


MULLE_CA_GLOBAL
char  *CAAnimationValueRangeUTF8String( struct CAAnimationValueRange *range,
                                        CAAnimationValueType type);


struct CABasicAnimationOptions
{
   struct CAAnimationOptions   base;
   CAAnimationCurve            curve;
   CATweenFunction             *tween;
};


//
// Note on autoreverses: with autoreverses=YES the animation reverses direction
// on each repeat. To get a full out-and-back cycle (ending at the start value),
// use repeatCount=2. With repeatCount=1 and autoreverses, the animation only
// goes forward (no reversal occurs).
//
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



#define CA_BASIC_ANIMATION_OPTIONS_DATA_CURVE( vdelay, vduration, voffset, vrepeat, vbits, vcurve)  \
   ((struct CABasicAnimationOptions)                                                                \
   {                                                                                                \
      /* base */                                                                                    \
      .base = CA_ANIMATION_OPTIONS_DATA( (vdelay), (vduration), (voffset), (vrepeat), (vbits)),     \
      /* curve */                                                                                   \
      .curve = (vcurve),                                                                            \
      .tween = 0                                                                                    \
   })                                                                                  


#define CA_BASIC_ANIMATION_OPTIONS_DATA_TWEEN( vdelay, vduration, voffset, vrepeat, vbits, vtween) \
   ((struct CABasicAnimationOptions)                                                               \
   {                                                                                               \
      /* base */                                                                                   \
      .base = CA_ANIMATION_OPTIONS_DATA( (vdelay), (vduration), (voffset), (vrepeat), (vbits)),    \
      /* curve */                                                                                  \
      .curve = 0,                                                                                  \
      .tween = (vtween)                                                                            \
   })                                                                                  

MULLE_CA_GLOBAL
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
MULLE_CA_GLOBAL
void  CABasicAnimationTypeDefinitionRegister( struct CABasicAnimationTypeDefinition *definition);

MULLE_CA_GLOBAL
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
@property( readonly) CACubic                       quadratic;
@property( readonly) CAAnimationValueType          valueType;


// Convenience factory methods
+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                             valueType:(CAAnimationValueType) type
                            valueRange:(struct CAAnimationValueRange *) range
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                        startRectValue:(CGRect) start
                          endRectValue:(CGRect) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                  startEdgeInsetsValue:(MulleEdgeInsets) start
                    endEdgeInsetsValue:(MulleEdgeInsets) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                        startSizeValue:(CGSize) start
                          endSizeValue:(CGSize) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startPointValue:(CGPoint) start
                         endPointValue:(CGPoint) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startFloatValue:(CGFloat) start
                         endFloatValue:(CGFloat) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                      startFloat2Value:(CGFloat2) start
                        endFloat2Value:(CGFloat2) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                      startFloat4Value:(CGFloat4) start
                        endFloat4Value:(CGFloat4) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                  startFloatArrayValue:(struct mulle__floatarray) start
                    endFloatArrayValue:(struct mulle__floatarray) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                      startObjectValue:(id <CAInterpolatableValue>) start
                        endObjectValue:(id <CAInterpolatableValue>) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startRangeValue:(NSRange) start
                         endRangeValue:(NSRange) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                     startIntegerValue:(NSInteger) start
                       endIntegerValue:(NSInteger) end
                               options:(struct CABasicAnimationOptions *) options;

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                        startBOOLValue:(BOOL) start
                          endBOOLValue:(BOOL) end
                               options:(struct CABasicAnimationOptions *) options;

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


MULLE_CA_GLOBAL
void   CABasicAnimationSetInterpolatedFloatAdditive( CABasicAnimation *self,
                                                     id object,
                                                     double x);

MULLE_CA_GLOBAL
void   CABasicAnimationSetInterpolatedFloat2Additive( CABasicAnimation *self,
                                                      id object,
                                                      double x);

MULLE_CA_GLOBAL
void   CABasicAnimationSetInterpolatedFloat4Additive( CABasicAnimation *self,
                                                      id object,
                                                      double x);


// useful for tests, to have this exposed
// x can be < 0  and > 1 here
static inline void
   CABasicAnimationAnimateObject( CABasicAnimation *self, id object, double x)
{
   //
   // TODO: make this thread local and ask inside accessors, which are
   //      providing animations themselves.
   //
   // isAnimating++;
   if( self)
      (*((struct{ @defs( CABasicAnimation); } *) self)->_interpolate)( self, object, x);
}


static inline void
   CABasicAnimationAnimateObjectAdditive( CABasicAnimation *self, id object, double x)
{
   if( self)
      (*((struct{ @defs( CABasicAnimation); } *) self)->_interpolateAdditive)( self, object, x);
}
