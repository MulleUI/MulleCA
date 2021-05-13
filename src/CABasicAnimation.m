#import "CABasicAnimation.h"

#import "import-private.h"

#include <assert.h>


MulleQuadratic   MulleQuadraticForAnimationCurve( enum CAAnimationCurve curvetype)
{
   MulleQuadratic   quadratic;

   switch( curvetype)
   {
   case CAAnimationCurveEaseInOut:
      MulleQuadraticInit( &quadratic, 0.0, 0.025, 1.0 - 0.025, 1.0);
      break;

   case CAAnimationCurveEaseOut:
      MulleQuadraticInit( &quadratic, 0.0, 0.9, 0.9, 1.0);
      break;

   case CAAnimationCurveEaseIn:
      MulleQuadraticInit( &quadratic, 0.0, 0.0, 0.1, 1.0);
      break;

   default :
      MulleQuadraticInit( &quadratic, 0.0, 0.333, 0.666, 1.0);
      break;
   }

   return( quadratic);
}



@implementation CABasicAnimation


static const struct CABasicAnimationOptions   CABasicAnimationDefaultOptions =
{
   {
      { 0, 1 },      // 1 second starting immediately
      1.0,
      0
   },
   { 0.0, 0.333, 0.666, 1.0 },  // linear as default
};


- (id) initWithPropertySetter:(SEL) propertySetter
                    valueType:(enum CAAnimationValueType) type
                   valueRange:(struct CAAnimationValueRange *) range
                  repeatStart:(union CAAnimationValue) repeatStart
                      options:(struct CABasicAnimationOptions *) options
{
   if( ! options)
      options = (void *) &CABasicAnimationDefaultOptions;

   self = [self initWithOptions:&options->base];
   if( ! self)
      return( self);

   self->_propertySetter      = propertySetter;
   self->_quadratic           = options->curve;

   self->_valueType           = type;
   self->_start               = range->start;
   self->_end                 = range->end;
   self->_repeatStart         = repeatStart;

   return( self);
}



- (id) initWithPropertySetter:(SEL) propertySetter
                    startRect:(CGRect) start
                      endRect:(CGRect) end
                      options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithRect( start);
   range.end   = CGAnimationValueMakeWithRect( end);
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueCGFloat4
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}


- (id) initWithPropertySetter:(SEL) propertySetter
              startEdgeInsets:(MulleEdgeInsets) start
                endEdgeInsets:(MulleEdgeInsets) end
                      options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithEdgeInsets( start);
   range.end   = CGAnimationValueMakeWithEdgeInsets( end);
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueCGFloat4
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}


- (id) initWithPropertySetter:(SEL) propertySetter
                    startSize:(CGSize) start
                      endSize:(CGSize) end
                      options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithSize( start);
   range.end   = CGAnimationValueMakeWithSize( end);
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueCGFloat2
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}


- (id) initWithPropertySetter:(SEL) propertySetter
                   startPoint:(CGPoint) start
                     endPoint:(CGPoint) end
                      options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithPoint( start);
   range.end   = CGAnimationValueMakeWithPoint( end);
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueCGFloat2
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}

- (id) initWithPropertySetter:(SEL) propertySetter
              startFloatValue:(CGFloat) start
                endFloatValue:(CGFloat) end
                      options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start.floatValue = start;
   range.end.floatValue   = end;
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueCGFloat
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}



- (id) initWithPropertySetter:(SEL) propertySetter
                   startRange:(NSRange) start
                     endRange:(NSRange) end
                      options:(struct CABasicAnimationOptions *) options;
{
   struct CAAnimationValueRange  range;

   range.start.rangeValue = start;
   range.end.rangeValue   = end;
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueNSRange
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}


- (id) initWithPropertySetter:(SEL) propertySetter
            startIntegerValue:(NSInteger) start
              endIntegerValue:(NSInteger) end
                      options:(struct CABasicAnimationOptions *) options;
{
   struct CAAnimationValueRange  range;

   range.start.integerValue = start;
   range.end.integerValue   = end;
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueNSInteger
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}

- (id) initWithPropertySetter:(SEL) propertySetter
               startBOOLValue:(BOOL) start
                 endBOOLValue:(BOOL) end
                      options:(struct CABasicAnimationOptions *) options;
{
   struct CAAnimationValueRange  range;

   range.start.boolValue = start;
   range.end.boolValue   = end;
   return( [self initWithPropertySetter:propertySetter
                              valueType:CAAnimationValueBOOL
                             valueRange:&range
                            repeatStart:range.start
                                options:options]);
}


- (void) reverse
{
   union CAAnimationValue     tmp;

   tmp          = self->_start;
   self->_start = self->_end;
   self->_end   = tmp;
   if( self->_bits & CAAnimationHasReversed)
      self->_end = tmp;
   else
      self->_end = self->_repeatStart;

   [super reverse];
}


//
// this is called by the layer (ahem) animatableObject
// which does the animation now
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) x
           elapsedTime:(CARelativeTime) elapsedTime
{
   union CAAnimationValue   value;

   assert( x >= 0.0);
   assert( x <= 1.0);
   assert( object);

   x = MulleQuadraticGetValueForNormalizedDistance( &self->_quadratic, x);

   switch( self->_valueType)
   {
   case CAAnimationValueUndefined :
      abort();

   case CAAnimationValueBOOL :
      value.boolValue = round( (self->_end.boolValue - self->_start.boolValue) * x + self->_start.boolValue);
      mulle_objc_object_call( object, self->_propertySetter, (void *) (intptr_t) value.boolValue);
      break;

   case CAAnimationValueNSInteger :
      value.integerValue = round( (self->_end.integerValue - self->_start.integerValue) * x + self->_start.integerValue);
      mulle_objc_object_call( object, self->_propertySetter, (void *) value.integerValue);
      break;

   case CAAnimationValueNSRange :
      // tricky coz its unsigned
      // is the location moving down ?
      //
      // also tricky as we may not accidentally round up too much
      //
      if( self->_start.rangeValue.location > self->_end.rangeValue.location)
         value.rangeValue.location = self->_start.rangeValue.location - floor( (self->_start.rangeValue.location - self->_end.rangeValue.location) * x);
      else
         value.rangeValue.location = self->_start.rangeValue.location + floor( (self->_end.rangeValue.location - self->_start.rangeValue.location) * x);
      if( self->_start.rangeValue.length > self->_end.rangeValue.length)
         value.rangeValue.length = self->_start.rangeValue.length - floor( (self->_start.rangeValue.length - self->_end.rangeValue.length) * x);
      else
         value.rangeValue.length = self->_start.rangeValue.length + floor( (self->_end.rangeValue.length - self->_start.rangeValue.length) * x);
      {
         mulle_metaabi_struct_void_return( NSRange)   param;

         param.p = value.rangeValue;
         mulle_objc_object_call( object, self->_propertySetter, &param);
      }
      break;

   case CAAnimationValueCGFloat :
      value.floatValue = (self->_end.floatValue - self->_start.floatValue) * x + self->_start.floatValue;
      {
         mulle_metaabi_struct_void_return( float)   param;

         param.p = value.floatValue;
         mulle_objc_object_call( object, self->_propertySetter, &param);
      }
      break;


   // this is all identical, we use point
   case CAAnimationValueCGFloat2  :
      value.float2Value.v[ 0] = (self->_end.float2Value.v[ 0] - self->_start.float2Value.v[ 0]) * x + self->_start.float2Value.v[ 0];
      value.float2Value.v[ 1] = (self->_end.float2Value.v[ 1] - self->_start.float2Value.v[ 1]) * x + self->_start.float2Value.v[ 1];
      {
         mulle_metaabi_struct_void_return( struct CAAnimationFloat2)   param;

         param.p = value.float2Value;
         mulle_objc_object_call( object, self->_propertySetter, &param);
      }
      break;


   // this is all identical, we use CGRect
   case CAAnimationValueCGFloat4     :
      value.float4Value.v[ 0] = (self->_end.float4Value.v[ 0] - self->_start.float4Value.v[ 0]) * x + self->_start.float4Value.v[ 0];
      value.float4Value.v[ 1] = (self->_end.float4Value.v[ 1] - self->_start.float4Value.v[ 1]) * x + self->_start.float4Value.v[ 1];
      value.float4Value.v[ 2] = (self->_end.float4Value.v[ 2] - self->_start.float4Value.v[ 2]) * x + self->_start.float4Value.v[ 2];
      value.float4Value.v[ 3] = (self->_end.float4Value.v[ 3] - self->_start.float4Value.v[ 3]) * x + self->_start.float4Value.v[ 3];
      {
         mulle_metaabi_struct_void_return( struct CAAnimationFloat4)   param;

         param.p = value.float4Value;
         mulle_objc_object_call( object, self->_propertySetter, &param);
      }
      break;

   default :
      abort();
   }
}


@end

