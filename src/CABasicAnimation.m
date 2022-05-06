#import "CABasicAnimation.h"

#import "import-private.h"

#include <assert.h>


#define ANIMATION_DEBUG


char  *CAAnimationValueUTF8String( union CAAnimationValue value,
                                   enum CAAnimationValueType type)
{
   switch( type)
   {
   case CAAnimationValueUndefined : return( "???");
   case CAAnimationValueBOOL      : return( MulleObjC_asprintf( "%btd", value.boolValue));
   case CAAnimationValueNSInteger : return( MulleObjC_asprintf( "%td", value.integerValue));
   case CAAnimationValueNSRange   : return( MulleObjC_asprintf( "%td-%td", value.rangeValue.location, value.rangeValue.length));
   case CAAnimationValueCGFloat   : return( MulleObjC_asprintf( "%g", value.floatValue));
   case CAAnimationValueCGFloat2  : return( CAAnimationFloat2UTF8String( value.float2Value));
   case CAAnimationValueCGColor   :
   case CAAnimationValueCGFloat4  : return( CAAnimationFloat4UTF8String( value.float4Value));
   }
}


char  *CAAnimationValueRangeUTF8String( struct CAAnimationValueRange *range,
                                        enum CAAnimationValueType type)
{
   char   *s[ 2];

   if( ! range)
      return( "NULL");
   s[ 0] = CAAnimationValueUTF8String( range->start, type);
   s[ 1] = CAAnimationValueUTF8String( range->end, type);

   return( MulleObjC_asprintf( "%s -> %s", s[ 0], s[ 1]));
}


char  *CABasicAnimationOptionsUTF8String( struct CABasicAnimationOptions *options)
{
   if( ! options)
      return( "NULL");

   return( MulleObjC_asprintf( "{ base: %s; curve: %s;  }",
               CAAnimationOptionsUTF8String( &options->base),
               options->tween ? "custom" : CAAnimationCurveUTF8String( options->curve)));
}


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

#ifdef ANIMATION_DEBUG
   MulleUILog( "%s %s %s",
                        mulle_objc_property_get_name( property),
                        CAAnimationValueTypeUTF8String( type),
                        CAAnimationValueRangeUTF8String( range, type));
#endif
   self->_property    = property;
   self->_quadratic   = CAQuadraticForAnimationCurve( options->curve);
   self->_tween       = options->tween ? options->tween : CAQuadraticGetValue;
   self->_valueType   = type;
   self->_start       = range->start;
   self->_end         = range->end;

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
                          options:options]);
}


- (BOOL) isAdditive
{
   return( _state.bits & CAAnimationAdditive);
}

- (BOOL) isCumulative
{
   return( _state.bits & CAAnimationCumulative);
}


- (void) reset
{
   [super reset];
   memset( &_previous, 0, sizeof( union CAAnimationValue));
}


- (void) animationIndexDidChange
{
   if( _state.bits & CAAnimationCumulative)
   {
      assert( _state.bits & CAAnimationAdditive);

      // do what now ?
      memset( &_previous, 0, sizeof( union CAAnimationValue));
   }
}



#define additive_interpolate( start, end, x) \
   ( (x) * ((end) - (start)) )


#define interpolate( start, end, x)  \
   ( (start) + additive_interpolate( start, end, x) )



static void   CABasicAnimationSetInterpolatedIntegerAdditive( CABasicAnimation *self,
                                                              id object,
                                                              double x)
{
   NSInteger  diff;
   NSInteger  value;
   NSInteger  newValue;

   diff     = (NSInteger) round( additive_interpolate( self->_start.integerValue, self->_end.integerValue, x));
   value    = (NSInteger) mulle_objc_object_call_variablemethodid( object,
                                                                   self->_property->getter,
                                                                   object);

   newValue                     = value -  self->_previous.integerValue + diff;
   self->_previous.integerValue = diff;

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %td", object,
                                 mulle_objc_property_get_name( self->_property),
                                 newValue);
#endif

   mulle_objc_object_call_variablemethodid( object, self->_property->setter, (void *) newValue);
}


static void   CABasicAnimationSetInterpolatedFloatAdditive( CABasicAnimation *self,
                                                            id object,
                                                            double x)
{
   CGFloat   diff;
   CGFloat   value;
   CGFloat   newValue;

   assert( x >= 0.0 && x <= 1.0);

   diff = additive_interpolate( self->_start.floatValue, self->_end.floatValue, x);
   {
      mulle_metaabi_struct_void_parameter( CGFloat)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }

   newValue                   = value - self->_previous.floatValue + diff;
#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s :: %g - %g + %g -> %g",
                              object,
                              mulle_objc_property_get_name( self->_property),
                              value,
                              self->_previous.floatValue,
                              diff,
                              newValue);
#endif
   self->_previous.floatValue = diff;

   {
      mulle_metaabi_struct_void_return( CGFloat)   param;

      param.p = newValue;

      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat2Additive( CABasicAnimation *self,
                                                             id object,
                                                             double x)
{
   struct CAAnimationFloat2   diff;
   struct CAAnimationFloat2   value;
   struct CAAnimationFloat2   newValue;

   diff.v[ 0] = additive_interpolate( self->_start.float2Value.v[ 0], self->_end.float2Value.v[ 0], x);
   diff.v[ 1] = additive_interpolate( self->_start.float2Value.v[ 1], self->_end.float2Value.v[ 1], x);

   {
      mulle_metaabi_struct_void_parameter( struct CAAnimationFloat2)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }

   newValue.v[ 0] = value.v[ 0] - self->_previous.float2Value.v[ 0] + diff.v[ 0];
   newValue.v[ 1] = value.v[ 1] - self->_previous.float2Value.v[ 1] + diff.v[ 1];

   self->_previous.float2Value.v[ 0] = diff.v[ 0];
   self->_previous.float2Value.v[ 1] = diff.v[ 1];

   {
      mulle_metaabi_struct_void_return( struct CAAnimationFloat2)   param;

#ifdef ANIMATION_DEBUG
      MulleUILog( "%#@ %s -> %s", object,
                               mulle_objc_property_get_name( self->_property),
                               CAAnimationFloat2UTF8String( newValue));
#endif
      param.p = newValue;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void
   CABasicAnimationSetInterpolatedFloat4Additive( CABasicAnimation *self,
                                                  id object,
                                                  double x)
{
   struct CAAnimationFloat4   diff;
   struct CAAnimationFloat4   value;
   struct CAAnimationFloat4   newValue;

   // now
   diff.v[ 0] = additive_interpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   diff.v[ 1] = additive_interpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   diff.v[ 2] = additive_interpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   diff.v[ 3] = additive_interpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);

   {
      mulle_metaabi_struct_void_parameter( struct CAAnimationFloat4)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }

   newValue.v[ 0] = value.v[ 0] - self->_previous.float4Value.v[ 0] + diff.v[ 0];
   newValue.v[ 1] = value.v[ 1] - self->_previous.float4Value.v[ 1] + diff.v[ 1];
   newValue.v[ 2] = value.v[ 2] - self->_previous.float4Value.v[ 2] + diff.v[ 2];
   newValue.v[ 3] = value.v[ 3] - self->_previous.float4Value.v[ 3] + diff.v[ 3];

   self->_previous.float4Value.v[ 0] = diff.v[ 0];
   self->_previous.float4Value.v[ 1] = diff.v[ 1];
   self->_previous.float4Value.v[ 2] = diff.v[ 2];
   self->_previous.float4Value.v[ 3] = diff.v[ 3];

   {
      mulle_metaabi_struct_void_return( struct CAAnimationFloat4)   param;

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %s", object,
                               mulle_objc_property_get_name( self->_property),
                               CAAnimationFloat4UTF8String( newValue));
#endif

      param.p = newValue;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


// Interpolating non-additive is nicer, as we can keep values as internally
// as HSBA
//

static void   CABasicAnimationSetInterpolatedColorAdditive( CABasicAnimation *self,
                                                            id object,
                                                            double x)
{
   CGColor                    newColor;
   float                      hsva[ 4];
   CGColor                    color;
   struct CAAnimationFloat4   diff;

   diff.v[ 0] = additive_interpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   diff.v[ 1] = additive_interpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   diff.v[ 2] = additive_interpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   diff.v[ 3] = additive_interpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);

   {
      mulle_metaabi_struct_void_parameter( CGColor)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      color = param.r;
   }

   CGColorGetHSVAComponents( color, hsva);

   hsva[ 0] = fmod( hsva[ 0] - self->_previous.float4Value.v[ 0] + diff.v[ 0], 1.0);    // hue can wrap for sure
   hsva[ 1] = fmod( hsva[ 1] - self->_previous.float4Value.v[ 1] + diff.v[ 1], 1.0);    // saturation clamp ?
   hsva[ 2] = fmod( hsva[ 2] - self->_previous.float4Value.v[ 2] + diff.v[ 2], 1.0);    // value clamp ?
   hsva[ 3] = fmod( hsva[ 3] - self->_previous.float4Value.v[ 3] + diff.v[ 3], 1.0);

   newColor = CGColorMakeHSVAComponents( hsva);

   self->_previous.float4Value.v[ 0] = diff.v[ 0];
   self->_previous.float4Value.v[ 1] = diff.v[ 1];
   self->_previous.float4Value.v[ 2] = diff.v[ 2];
   self->_previous.float4Value.v[ 3] = diff.v[ 3];

   {
      mulle_metaabi_struct_void_return( CGColor)   param;

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %s", object,
                               mulle_objc_property_get_name( self->_property),
                               CGColorUTF8String( newColor));
#endif

      param.p = newColor;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationAnimateObject( CABasicAnimation *self, id object, double t);


- (void) animateAdditiveObject:(id) object
        normalizedRelativeTime:(double) t
                   elapsedTime:(mulle_relativetime_t) elapsedTime
{
   double   x;

   // x is now
   x = (_tween)( &self->_quadratic, t);

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
      CABasicAnimationSetInterpolatedIntegerAdditive( self, object, x);
      break;

   case CAAnimationValueNSRange :
      // we just can't do this additively (or I can't)
      if( t == 0.0)
         fprintf( stderr, "NSRange animation can not be done additively\n");
      break;

   case CAAnimationValueCGFloat :
      CABasicAnimationSetInterpolatedFloatAdditive( self, object, x);
      break;

   // this is all identical, we use point
   case CAAnimationValueCGFloat2 :
      CABasicAnimationSetInterpolatedFloat2Additive( self, object, x);
      break;

   // this is all identical, we use CGRect
   case CAAnimationValueCGFloat4 :
      CABasicAnimationSetInterpolatedFloat4Additive( self, object, x);
      break;

   case CAAnimationValueCGColor :
      CABasicAnimationSetInterpolatedColorAdditive( self, object, x);
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


static void   CABasicAnimationAnimateObject( CABasicAnimation *self, id object, double t)
{
   double   x;

   //
   // TODO: make this thread local and ask inside accessors, which are
   //      providing animations themselves.
   //
   // isAnimating++;

   x = (self->_tween)( &self->_quadratic, t);
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

//
// this is called by the layer (ahem) animatableObject
// which does the animation now
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(mulle_relativetime_t) elapsedTime
{
   union CAAnimationValue   value;
   double                   x;

   assert( t >= 0.0);
   assert( t <= 1.0);
   assert( object);

   if( _state.bits & CAAnimationAdditive)
   {
      [self animateAdditiveObject:object
           normalizedRelativeTime:t
                      elapsedTime:elapsedTime];
      return;
   }

   CABasicAnimationAnimateObject( self, object, t);
}


#ifdef ANIMATION_DEBUG
- (NSUInteger) animateObject:(id) object
                absoluteTime:(mulle_absolutetime_t) now
               animationRate:(mulle_relativetime_t) animationRate
{
   return( [super animateObject:object
                   absoluteTime:now
                  animationRate:animationRate]);
}
#endif

@end

