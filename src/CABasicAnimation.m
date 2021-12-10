#import "CABasicAnimation.h"

#import "import-private.h"

#include <assert.h>



@implementation CABasicAnimation


static const struct CABasicAnimationOptions   CABasicAnimationDefaultOptions =
{
   /* base */
   {
      { 0, 1 },      // 1 second starting immediately
      1.0,
      0
   },
   /* curve */
   CAAnimationCurveLinear,  // linear as default
   /* tween */
};


- (id) initWithProperty:(struct _mulle_objc_property *) property
              valueType:(enum CAAnimationValueType) type
             valueRange:(struct CAAnimationValueRange *) range
            repeatStart:(union CAAnimationValue) repeatStart
                options:(struct CABasicAnimationOptions *) options
{
   if( ! property ||  ! range)
   {
      [self release];
      return( nil);
   }

   if( ! options)
      options = (void *) &CABasicAnimationDefaultOptions;

   self = [self initWithAnimationOptions:&options->base];
   if( ! self)
      return( self);

   self->_property    = property;
   self->_quadratic   = CAQuadraticForAnimationCurve( options->curve);
   self->_tween       = options->tween ? options->tween : CAQuadraticGetValue;
   self->_valueType   = type;
   self->_start       = range->start;
   self->_end         = range->end;
   self->_repeatStart = repeatStart;

   return( self);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
         startRectValue:(CGRect) start
           endRectValue:(CGRect) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithRect( start);
   range.end   = CGAnimationValueMakeWithRect( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat4
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
   startEdgeInsetsValue:(MulleEdgeInsets) start
     endEdgeInsetsValue:(MulleEdgeInsets) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithEdgeInsets( start);
   range.end   = CGAnimationValueMakeWithEdgeInsets( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat4
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
         startSizeValue:(CGSize) start
           endSizeValue:(CGSize) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithSize( start);
   range.end   = CGAnimationValueMakeWithSize( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat2
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
        startPointValue:(CGPoint) start
          endPointValue:(CGPoint) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithPoint( start);
   range.end   = CGAnimationValueMakeWithPoint( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat2
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startFloatValue:(CGFloat) start
          endFloatValue:(CGFloat) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start.floatValue = start;
   range.end.floatValue   = end;
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}



- (id) initWithProperty:(struct _mulle_objc_property *) property
        startRangeValue:(NSRange) start
          endRangeValue:(NSRange) end
                options:(struct CABasicAnimationOptions *) options;
{
   struct CAAnimationValueRange  range;

   range.start.rangeValue = start;
   range.end.rangeValue   = end;
   return( [self initWithProperty:property
                        valueType:CAAnimationValueNSRange
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
      startIntegerValue:(NSInteger) start
        endIntegerValue:(NSInteger) end
                options:(struct CABasicAnimationOptions *) options;
{
   struct CAAnimationValueRange  range;

   range.start.integerValue = start;
   range.end.integerValue   = end;
   return( [self initWithProperty:property
                        valueType:CAAnimationValueNSInteger
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}

- (id) initWithProperty:(struct _mulle_objc_property *) property
         startBOOLValue:(BOOL) start
           endBOOLValue:(BOOL) end
                options:(struct CABasicAnimationOptions *) options;
{
   struct CAAnimationValueRange  range;

   range.start.boolValue = start;
   range.end.boolValue   = end;
   return( [self initWithProperty:property
                        valueType:CAAnimationValueBOOL
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
        startColorValue:(CGColor) start
          endColorValue:(CGColor) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CGAnimationValueMakeWithCGColor( start);
   range.end   = CGAnimationValueMakeWithCGColor( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGColor
                       valueRange:&range
                      repeatStart:range.start
                          options:options]);
}


- (BOOL) isAdditive
{
   return( _bits & CAAnimationAdditive);
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


#define interpolate( start, end, x)  \
   ( (start) + (x) * ((end) - (start)) )

#define additive_interpolate( previous, start, end, x) \
   ( (previous) + (x) * ((end) - (start)) )


static void   CABasicAnimationSetInterpolatedBOOLAdditive( CABasicAnimation *self,
                                                           id object,
                                                           double x,
                                                           double y)
{
   float   before;
   float   now;
   BOOL    value;

   before   = interpolate( self->_start.boolValue, self->_end.boolValue, y);
   now      = interpolate( self->_start.boolValue, self->_end.boolValue, x);
   value    = (BOOL) (intptr_t) mulle_objc_object_call_variablemethodid( object,
                                                                         self->_property->getter,
                                                                         object);
   value    = (value + (now - before) >= 0.5) ? YES : NO;
   mulle_objc_object_call_variablemethodid( object,
                                            self->_property->setter,
                                            (void *) (intptr_t) value);
}


static void   CABasicAnimationSetInterpolatedIntegerAdditive( CABasicAnimation *self,
                                                              id object,
                                                              double x,
                                                              double y)
{
   double     before;
   double     now;
   NSInteger  value;

   before   = interpolate( self->_start.integerValue, self->_end.integerValue, y);
   now      = interpolate( self->_start.integerValue, self->_end.integerValue, x);
   value    = (NSInteger) mulle_objc_object_call_variablemethodid( object,
                                                                   self->_property->getter,
                                                                   object);
   value   += (NSInteger) round( now - before);
   mulle_objc_object_call_variablemethodid( object, self->_property->setter, (void *) value);
}


static void   CABasicAnimationSetInterpolatedFloatAdditive( CABasicAnimation *self,
                                                            id object,
                                                            double x,
                                                            double y)
{
   CGFloat   before;
   CGFloat   now;
   CGFloat   value;

   before = interpolate( self->_start.floatValue, self->_end.floatValue, y);
   now    = interpolate( self->_start.floatValue, self->_end.floatValue, x);
   {
      mulle_metaabi_struct_void_parameter( CGFloat)   param;
      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }
   value += (now - before);
   {
      mulle_metaabi_struct_void_return( CGFloat)   param;
      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat2Additive( CABasicAnimation *self,
                                                             id object,
                                                             double x,
                                                             double y)
{
   struct CAAnimationFloat2   before;
   struct CAAnimationFloat2   now;
   struct CAAnimationFloat2   value;

   before.v[ 0] = interpolate( self->_start.float2Value.v[ 0], self->_end.float2Value.v[ 0], y);
   before.v[ 1] = interpolate( self->_start.float2Value.v[ 1], self->_end.float2Value.v[ 1], y);

   now.v[ 0]    = interpolate( self->_start.float2Value.v[ 0], self->_end.float2Value.v[ 0], x);
   now.v[ 1]    = interpolate( self->_start.float2Value.v[ 1], self->_end.float2Value.v[ 1], x);

   {
      mulle_metaabi_struct_void_parameter( struct CAAnimationFloat2)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }
   value.v[ 0] += (now.v[ 0] - before.v[ 0]);
   value.v[ 1] += (now.v[ 1] - before.v[ 1]);
   {
      mulle_metaabi_struct_void_return( struct CAAnimationFloat2)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static struct CAAnimationFloat4
   _CABasicAnimationSetInterpolatedFloat4Additive( CABasicAnimation *self,
                                                   id object,
                                                   double x,
                                                   double y)
{
   struct CAAnimationFloat4   before;
   struct CAAnimationFloat4   now;
   struct CAAnimationFloat4   value;

   // before
   before.v[ 0] = interpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], y);
   before.v[ 1] = interpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], y);
   before.v[ 2] = interpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], y);
   before.v[ 3] = interpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], y);

   // now
   now.v[ 0]    = interpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   now.v[ 1]    = interpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   now.v[ 2]    = interpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   now.v[ 3]    = interpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);

   {
      mulle_metaabi_struct_void_parameter( struct CAAnimationFloat4)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }

   value.v[ 0] += (now.v[ 0] - before.v[ 0]);
   value.v[ 1] += (now.v[ 1] - before.v[ 1]);
   value.v[ 2] += (now.v[ 2] - before.v[ 2]);
   value.v[ 3] += (now.v[ 3] - before.v[ 3]);

   return( value);
}


static void
   CABasicAnimationSetInterpolatedFloat4Additive( CABasicAnimation *self,
                                                  id object,
                                                  double x,
                                                  double y)
{
   struct CAAnimationFloat4   value;

   value = _CABasicAnimationSetInterpolatedFloat4Additive( self, object, x, y);

   {
      mulle_metaabi_struct_void_return( struct CAAnimationFloat4)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedColorAdditive( CABasicAnimation *self,
                                                             id object,
                                                             double x,
                                                             double y)
{
   struct CAAnimationFloat4   value;
   CGColor                    color;

   value = _CABasicAnimationSetInterpolatedFloat4Additive( self, object, x, y);
   color = CGColorMakeHSBA( value.v[ 0], value.v[ 1], value.v[ 2], value.v[3]);
   {
      mulle_metaabi_struct_void_return( CGColor)   param;

      param.p = color;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}



- (void) animateAdditiveObject:(id) object
        normalizedRelativeTime:(double) t
                   elapsedTime:(CARelativeTime) elapsedTime
{
   union CAAnimationValue   value1;
   union CAAnimationValue   value2;
   union CAAnimationValue   previous;
   union CAAnimationValue   value;
   double                   x;
   double                   y;
   double                   e;
   double                   t2;
   CARelativeTime           diff;

   // x is now
   x = (_tween)( &self->_quadratic, t);

   e    = elapsedTime / self->_relative.duration;
   t2   = t - e;
   if( t2 < 0.0)
      t2 = 0.0;

   // y is last frame
   y = (_tween)( &self->_quadratic, t2);

   // the amount of change from last time
   switch( self->_valueType)
   {
   case CAAnimationValueUndefined :
      abort();

   case CAAnimationValueBOOL :
      // this doesn't work additively it will stick to NO or YES
      if( t == 0.0)
         fprintf( stderr, "BOOL animation can not be done additively\n");
      break;

   case CAAnimationValueNSInteger :
      CABasicAnimationSetInterpolatedIntegerAdditive( self, object, x, y);
      break;

   case CAAnimationValueNSRange :
      // we just can't do this additively (or I can't)
      if( t == 0.0)
         fprintf( stderr, "NSRange animation can not be done additively\n");
      break;

   case CAAnimationValueCGFloat :
      CABasicAnimationSetInterpolatedFloatAdditive( self, object, x, y);
      break;


   // this is all identical, we use point
   case CAAnimationValueCGFloat2 :
      CABasicAnimationSetInterpolatedFloat2Additive( self, object, x, y);
      break;


   // this is all identical, we use CGRect
   case CAAnimationValueCGFloat4 :
      CABasicAnimationSetInterpolatedFloat4Additive( self, object, x, y);
      break;

   case CAAnimationValueCGColor :
      CABasicAnimationSetInterpolatedColorAdditive( self, object, x, y);
      break;

   default :
      abort();
   }
}


static void   CABasicAnimationSetInterpolatedBOOL( CABasicAnimation *self,
                                                   id object,
                                                   double x)
{
   BOOL   value;

   value = round( interpolate( self->_start.boolValue, self->_end.boolValue, x)) >= 1.0 ? YES : NO;
   mulle_objc_object_call_variablemethodid( object,
                                            self->_property->setter,
                                            (void *) (intptr_t) value);
}


static void   CABasicAnimationSetInterpolatedInteger( CABasicAnimation *self,
                                                      id object,
                                                      double x)
{
   NSInteger   value;

   value = (NSInteger) round( interpolate( self->_start.integerValue,
                                           self->_end.integerValue,
                                           x));
   mulle_objc_object_call_variablemethodid( object,
                                            self->_property->setter,
                                            (void *) value);
}


static void   CABasicAnimationSetInterpolatedRange( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   NSRange   value;

   // tricky coz its unsigned
   // is the location moving down ?
   //
   // also tricky as we may not accidentally round up too much
   //
   if( self->_start.rangeValue.location > self->_end.rangeValue.location)
      value.location = self->_start.rangeValue.location -
                       (NSUInteger) floor( (self->_start.rangeValue.location -
                                            self->_end.rangeValue.location) * x);
   else
      value.location = self->_start.rangeValue.location +
                       (NSUInteger)  floor( (self->_end.rangeValue.location -
                                             self->_start.rangeValue.location) * x);
   if( self->_start.rangeValue.length > self->_end.rangeValue.length)
      value.length   = self->_start.rangeValue.length -
                       (NSUInteger) floor( (self->_start.rangeValue.length -
                                            self->_end.rangeValue.length) * x);
   else
      value.length   = self->_start.rangeValue.length +
                       (NSUInteger) floor( (self->_end.rangeValue.length -
                                            self->_start.rangeValue.length) * x);
   {
      mulle_metaabi_struct_void_return( NSRange)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   CGFloat   value;

   value = interpolate( self->_start.floatValue, self->_end.floatValue, x);
   {
      mulle_metaabi_struct_void_return( CGFloat)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat2( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CAAnimationFloat2   value;

   value.v[ 0] = interpolate( self->_start.float2Value.v[ 0], self->_end.float2Value.v[ 0], x);
   value.v[ 1] = interpolate( self->_start.float2Value.v[ 1], self->_end.float2Value.v[ 1], x);
   {
      mulle_metaabi_struct_void_return( struct CAAnimationFloat2)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat4( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CAAnimationFloat4   value;

   value.v[ 0] = interpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   value.v[ 1] = interpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   value.v[ 2] = interpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   value.v[ 3] = interpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);
   {
      mulle_metaabi_struct_void_return( struct CAAnimationFloat4)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedColor( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   struct CAAnimationFloat4   value;
   CGColor                    color;

   value.v[ 0] = interpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   value.v[ 1] = interpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   value.v[ 2] = interpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   value.v[ 3] = interpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);

   color = CGColorMakeHSBA( value.v[ 0], value.v[ 1], value.v[ 2], value.v[ 3]);
   {
      mulle_metaabi_struct_void_return( CGColor)   param;

      param.p = color;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


//
// this is called by the layer (ahem) animatableObject
// which does the animation now
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(CARelativeTime) elapsedTime
{
   union CAAnimationValue   value;
   double                   x;

   assert( t >= 0.0);
   assert( t <= 1.0);
   assert( object);
   
   if( _bits & CAAnimationAdditive)
   {
      [self animateAdditiveObject:object
           normalizedRelativeTime:t
                      elapsedTime:elapsedTime];
      return;
   }

   //
   // TODO: make this thread local and ask inside accessors, which are 
   //      providing animations themselves.
   //
   // isAnimating++;

   x = (_tween)( &self->_quadratic, t);
   switch( self->_valueType)
   {
   case CAAnimationValueUndefined :
      abort();

   case CAAnimationValueBOOL :
      CABasicAnimationSetInterpolatedBOOL( self, object, x);
      break;

   case CAAnimationValueNSInteger :
      CABasicAnimationSetInterpolatedInteger( self, object, x);
      break;

   case CAAnimationValueNSRange :
      CABasicAnimationSetInterpolatedRange( self, object, x);
      break;

   case CAAnimationValueCGFloat :
      CABasicAnimationSetInterpolatedFloat( self, object, x);
      break;

   case CAAnimationValueCGFloat2 :
      CABasicAnimationSetInterpolatedFloat2( self, object, x);
      break;

   case CAAnimationValueCGFloat4 :
      CABasicAnimationSetInterpolatedFloat4( self, object, x);
      break;

   case CAAnimationValueCGColor :
      CABasicAnimationSetInterpolatedColor( self, object, x);
      break;

   default :
      abort();
   }
   // isAnimating--;
}

@end

