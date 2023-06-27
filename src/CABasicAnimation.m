#import "CABasicAnimation.h"

#import "import-private.h"

#include <assert.h>


//#define ANIMATION_DEBUG


char  *CAAnimationFloatArrayUTF8String( struct mulle__floatarray value)
{
   float  v;
   char   *s;
   char   *sep;

   sep = "";
   mulle_buffer_do_string( buffer, NULL, s)
   {
      mulle_buffer_add_string( buffer, "[");
      mulle__floatarray_for( &value, v)
      {
         mulle_buffer_add_string( buffer, sep);
         mulle_buffer_sprintf( buffer, "%s%g", sep, v);
         sep = " ";
      }
      mulle_buffer_add_string( buffer, "]");
   }
   return( MulleObjCAutoreleaseAllocation( s, NULL));
}




static void   CABasicAnimationAbort( CABasicAnimation *self, id object, double x);


char  *CABasicAnimationOptionsUTF8String( struct CABasicAnimationOptions *options)
{
   if( ! options)
      return( "NULL");

   return( MulleObjC_asprintf( "{ base: %s; curve: %s;  }",
               CAAnimationOptionsUTF8String( &options->base),
               options->tween ? "custom" : CAAnimationCurveUTF8String( options->curve)));
}


#pragma mark - Additive Interpolation code


@implementation CABasicAnimation

static void
   CABasicAnimationSetInterpolatedIntegerAdditive( CABasicAnimation *self,
                                                   id object,
                                                   double x)
{
   NSInteger  diff;
   NSInteger  value;
   NSInteger  newValue;

   diff     = (NSInteger) round( CAInterpolateAdditive( self->_start.integerValue,
                                                        self->_end.integerValue,
                                                        x));
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


static void
   CABasicAnimationSetInterpolatedFloatAdditive( CABasicAnimation *self,
                                                 id object,
                                                 double x)
{
   CGFloat   diff;
   CGFloat   value;
   CGFloat   newValue;

   diff = CAInterpolateAdditive( self->_start.floatValue, self->_end.floatValue, x);
   {
      mulle_metaabi_union_void_parameter( CGFloat)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }

   newValue = value - self->_previous.floatValue + diff;

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
      mulle_metaabi_union_void_return( CGFloat)   param;

      param.p = newValue;

      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void
   CABasicAnimationSetInterpolatedFloat2Additive( CABasicAnimation *self,
                                                  id object,
                                                  double x)
{
   struct CAAnimationFloat2   diff;
   struct CAAnimationFloat2   value;
   struct CAAnimationFloat2   newValue;

   diff.v[ 0] = CAInterpolateAdditive( self->_start.float2Value.v[ 0], self->_end.float2Value.v[ 0], x);
   diff.v[ 1] = CAInterpolateAdditive( self->_start.float2Value.v[ 1], self->_end.float2Value.v[ 1], x);

   {
      mulle_metaabi_union_void_parameter( struct CAAnimationFloat2)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      value = param.r;
   }

   newValue.v[ 0] = value.v[ 0] - self->_previous.float2Value.v[ 0] + diff.v[ 0];
   newValue.v[ 1] = value.v[ 1] - self->_previous.float2Value.v[ 1] + diff.v[ 1];

   self->_previous.float2Value.v[ 0] = diff.v[ 0];
   self->_previous.float2Value.v[ 1] = diff.v[ 1];

   {
      mulle_metaabi_union_void_return( struct CAAnimationFloat2)   param;

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
   diff.v[ 0] = CAInterpolateAdditive( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   diff.v[ 1] = CAInterpolateAdditive( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   diff.v[ 2] = CAInterpolateAdditive( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   diff.v[ 3] = CAInterpolateAdditive( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);

   {
      mulle_metaabi_union_void_parameter( struct CAAnimationFloat4)   param;

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
      mulle_metaabi_union_void_return( struct CAAnimationFloat4)   param;

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %s", object,
                               mulle_objc_property_get_name( self->_property),
                               CAAnimationFloat4UTF8String( newValue));
#endif

      param.p = newValue;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedObjectAdditive( CABasicAnimation *self,
                                                            id object,
                                                            double x)
{
   id   diff;
   id   value;
   id   newValue;

   if( ! self->_start.objectValue)
      diff     = [self->_end.objectValue interpolateTo:nil
                                                factor:(1.0 - x)
                                              additive:YES];
   else
      diff     = [self->_start.objectValue interpolateTo:self->_end.objectValue
                                                  factor:x
                                                additive:YES];

   value    = mulle_objc_object_call_variablemethodid( object, 
                                                       self->_property->getter, 
                                                       object);
   newValue = [value interpolatedValueWithDiff:diff
                                  previousDiff:self->_previous.objectValue];

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s :: %@ - %@ + %@ -> %@",
                              object,
                              mulle_objc_property_get_name( self->_property),
                              value,
                              self->_previous.objectValue,
                              diff,
                              newValue);
#endif
   [self->_previous.objectValue autorelease];
   self->_previous.objectValue = [diff copy];

   mulle_objc_object_call_variablemethodid( object, self->_property->setter, newValue);
}



// x can be < 0  and > 1 here
static inline void   CABasicAnimationAnimateObject( CABasicAnimation *self, id object, double x)
{
   //
   // TODO: make this thread local and ask inside accessors, which are
   //      providing animations themselves.
   //
   // isAnimating++;

   return( (*self->_interpolate)( self, object, x));
}


static inline void   CABasicAnimationAnimateObjectAdditive( CABasicAnimation *self, id object, double x)
{
    return( (*self->_interpolateAdditive)( self, object, x));
}



static void   CABasicAnimationSetInterpolatedBOOL( CABasicAnimation *self,
                                                   id object,
                                                   double x)
{
   BOOL   value;

   value = round( CAInterpolate( self->_start.boolValue, self->_end.boolValue, x)) >= 1.0 ? YES : NO;
   mulle_objc_object_call_variablemethodid( object,
                                            self->_property->setter,
                                            (void *) (intptr_t) value);
}


static void   CABasicAnimationSetInterpolatedInteger( CABasicAnimation *self,
                                                      id object,
                                                      double x)
{
   NSInteger   value;

   value = (NSInteger) round( CAInterpolate( self->_start.integerValue,
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
      mulle_metaabi_union_void_return( NSRange)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   CGFloat   value;

   value = CAInterpolate( self->_start.floatValue, self->_end.floatValue, x);
   {
      mulle_metaabi_union_void_return( CGFloat)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat2( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CAAnimationFloat2   value;

   value.v[ 0] = CAInterpolate( self->_start.float2Value.v[ 0], self->_end.float2Value.v[ 0], x);
   value.v[ 1] = CAInterpolate( self->_start.float2Value.v[ 1], self->_end.float2Value.v[ 1], x);
   {
      mulle_metaabi_union_void_return( struct CAAnimationFloat2)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


static void   CABasicAnimationSetInterpolatedFloat4( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CAAnimationFloat4   value;

   value.v[ 0] = CAInterpolate( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   value.v[ 1] = CAInterpolate( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   value.v[ 2] = CAInterpolate( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   value.v[ 3] = CAInterpolate( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);
   {
      mulle_metaabi_union_void_return( struct CAAnimationFloat4)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


NSInteger   CAArrayIndexForInterpolation( NSUInteger startLength,
                                          NSUInteger length,
                                          NSUInteger mode)
{
   switch( mode)
   {
   default :
      // 1)
      // start    = |124689|
      // inter_50 = |412|
      // end      = |9|       -> |900000|
      //
      // 2)
      // start    = |1|       -> |100000|
      // inter_50 = |443|
      // end      = |986421|
      //
      return( 0);

   case CAAnimationStickyArrayEnd :
      // 1)
      // start    = |124689|
      // inter_50 =    |349|
      // end      =      |9|  -> |000009|
      //
      // 2)
      // start    =      |1|  -> |000001|
      // inter_50 =    |211|
      // end      = |986421|
      //
      return( (NSInteger) startLength - (NSInteger) length);

   case CAAnimationStickyArrayCenter :
      // 1)
      // start    = |124689|
      // inter_50 =  |163|
      // end      =   |9|    -> |009000|
      //
      // 2)
      // start    =   |1|    -> |001000|
      // inter_50 =  |432|
      // end      = |986421|
      //
      return( ((NSInteger) startLength - (NSInteger) length + 1) / 2.0);
   }
}


NSInteger   CAInterpolatedArrayIndex( NSUInteger startLength,
                                      NSUInteger endLength,
                                      double x,
                                      NSUInteger mode)
{
   NSUInteger   length;

   length = (NSUInteger) round( CAInterpolate( startLength, endLength, x));
   return( CAArrayIndexForInterpolation( startLength, length, mode));
}


static void   CABasicAnimationSetInterpolatedFloatArray( CABasicAnimation *self,
                                                         id object,
                                                         double x)
{
   float                      *p;
   float                      v1, v2;
   NSUInteger                 bits;
   NSUInteger                 endLength;
   NSInteger                  i;
   NSInteger                  j;
   NSUInteger                 k;
   NSUInteger                 length;
   NSUInteger                 startLength;
   struct mulle__floatarray   value;
   struct mulle_allocator     *allocator;

   startLength = mulle__floatarray_get_count( &self->_start.floatArray);
   endLength   = mulle__floatarray_get_count( &self->_end.floatArray);
   length      = (NSUInteger) round( CAInterpolate( startLength, endLength, x));
   bits        = self->_state.bits & (CAAnimationStickyArrayCenter|CAAnimationStickyArrayEnd);

   i = CAArrayIndexForInterpolation( startLength, length, bits);
   j = CAArrayIndexForInterpolation( endLength, length, bits);

   allocator = MulleObjCInstanceGetAllocator( self);
   _mulle__floatarray_init( &value, 0, allocator);
   p = _mulle__floatarray_advance( &value, length, allocator);
   
   for( k = 0; k < length; k++)
   {
      v1   = (i < 0 || i >= startLength) ? 0.0 : _mulle__floatarray_get( &self->_start.floatArray, i);
      v2   = (j < 0 || j >= endLength)   ? 0.0 : _mulle__floatarray_get( &self->_end.floatArray, j);
      *p++ = CAInterpolate( v1, v2, x);
      i++;
      j++;
   }
   {
      mulle_metaabi_union_void_return( struct mulle__floatarray)   param;

      param.p = value;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
   //TODO: release on close of CABasicAnimation
   _mulle__floatarray_done( &value, allocator);
}


static void   CABasicAnimationSetInterpolatedObject( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   id   newValue;

   // now
   if( ! self->_start.objectValue)
      newValue = [self->_end.objectValue interpolateTo:nil
                                                factor:(1.0 - x)
                                              additive:NO];
   else       
      newValue = [self->_start.objectValue interpolateTo:self->_end.objectValue
                                                  factor:x
                                                additive:NO];

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %@", object,
                               mulle_objc_property_get_name( self->_property),
                               newValue);
#endif

   mulle_objc_object_call_variablemethodid( object, self->_property->setter, newValue);
}




static struct CABasicAnimationTypeDefinition  builtins[] =
{
   {
      CAAnimationValueUndefined,
      "CAAnimationValueUndefined",
      CABasicAnimationAbort,
      CABasicAnimationAbort
   },
   {
      CAAnimationValueBOOL,
      "CAAnimationValueBOOL",
      CABasicAnimationSetInterpolatedBOOL,
      CABasicAnimationAbort
   },
   {
      CAAnimationValueNSInteger,
      "CAAnimationValueNSInteger",
      CABasicAnimationSetInterpolatedInteger,
      CABasicAnimationSetInterpolatedIntegerAdditive
   },
   {
      CAAnimationValueNSRange,
      "CAAnimationValueNSRange",
      CABasicAnimationSetInterpolatedRange,
      CABasicAnimationAbort
   },

   {
      CAAnimationValueCGFloat,
      "CAAnimationValueCGFloat",
      CABasicAnimationSetInterpolatedFloat,
      CABasicAnimationSetInterpolatedFloatAdditive
   },
   {
      CAAnimationValueCGFloat2,
      "CAAnimationValueCGFloat2",
      CABasicAnimationSetInterpolatedFloat2,
      CABasicAnimationSetInterpolatedFloat2Additive
   },
   {
      CAAnimationValueCGFloat4,
      "CAAnimationValueCGFloat4",
      CABasicAnimationSetInterpolatedFloat4,
      CABasicAnimationSetInterpolatedFloat4Additive
   },
   {
      CAAnimationValueFloatArray,
      "CAAnimationValueFloatArray",
      CABasicAnimationSetInterpolatedFloatArray,
      (CABasicAnimationInterpolator_t *) abort  // not yet coded
   },

   {
      CAAnimationValueObject,
      "CAAnimationValueObject",
      CABasicAnimationSetInterpolatedObject,
      CABasicAnimationSetInterpolatedObjectAdditive
   }
};

#define N_BUILTINS  (sizeof( builtins) / sizeof( struct CABasicAnimationTypeDefinition))

// room for 8
#define S_EXTENSIONS  8
static struct CABasicAnimationTypeDefinition  extensions[ S_EXTENSIONS];
static unsigned int                           n_extensions;


MULLE_C_CONST_NONNULL_RETURN
struct CABasicAnimationTypeDefinition *
   CABasicAnimationTypeDefinitionGetExtension( NSUInteger type)
{
   struct CABasicAnimationTypeDefinition  *p;
   struct CABasicAnimationTypeDefinition  *sentinel;

   p        = extensions;
   sentinel = &p[ n_extensions];
   while( p < sentinel)
      if( p->type == type)
         return( p);

   abort();
}


struct CABasicAnimationTypeDefinition *
   CABasicAnimationTypeDefinitionGet( CAAnimationValueType type)
{
   if( type <= CAAnimationValueTypeLastBuiltIn)
      return( &builtins[ type]);
   return( CABasicAnimationTypeDefinitionGetExtension( type));
}


void   CABasicAnimationTypeDefinitionRegister( struct CABasicAnimationTypeDefinition *p)
{
   if( n_extensions >= S_EXTENSIONS)
      abort();

   assert( p);
   assert( p->type > CAAnimationValueTypeLastBuiltIn);
   assert( p->name && p->name[ 0]);
   assert( p->interpolate);
   assert( p->interpolateAdditive);

   extensions[ n_extensions++] = *p;
}


char   *CAAnimationValueUTF8String( union CAAnimationValue value,
                                    CAAnimationValueType type)
{
   struct CABasicAnimationTypeDefinition  *p;

   switch( type)
   {
   case CAAnimationValueUndefined  : return( "???");
   case CAAnimationValueBOOL       : return( MulleObjC_asprintf( "%btd", value.boolValue));
   case CAAnimationValueNSInteger  : return( MulleObjC_asprintf( "%td", value.integerValue));
   case CAAnimationValueNSRange    : return( MulleObjC_asprintf( "%td-%td", value.rangeValue.location, value.rangeValue.length));
   case CAAnimationValueCGFloat    : return( MulleObjC_asprintf( "%g", value.floatValue));
   case CAAnimationValueCGFloat2   : return( CAAnimationFloat2UTF8String( value.float2Value));
   case CAAnimationValueCGFloat4   : return( CAAnimationFloat4UTF8String( value.float4Value));
   case CAAnimationValueFloatArray : return( CAAnimationFloatArrayUTF8String( value.floatArray));
   case CAAnimationValueObject     : return( [value.objectValue UTF8String]);
   }

   p = CABasicAnimationTypeDefinitionGetExtension( type);
   return( (*p->valueUTF8String)( value));
}


char   *CAAnimationValueRangeUTF8String( struct CAAnimationValueRange *range,
                                         CAAnimationValueType type)
{
   char   *s[ 2];

   if( ! range)
      return( "NULL");

   s[ 0] = CAAnimationValueUTF8String( range->start, type);
   s[ 1] = CAAnimationValueUTF8String( range->end, type);

   return( MulleObjC_asprintf( "%s -> %s", s[ 0], s[ 1]));
}


static const struct CABasicAnimationOptions   
   CABasicAnimationDefaultOptions =
      CA_BASIC_ANIMATION_OPTIONS_INIT_CURVE( 0, 1, 1.0, 0, CAAnimationCurveLinear);



static void   CABasicAnimationAbort( CABasicAnimation *self, id object, double x)
{
   mulle_fprintf( stderr, "This kind of interpolation is not supported on %ld\n", self->_valueType);
   abort();
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
              valueType:(CAAnimationValueType) type
             valueRange:(struct CAAnimationValueRange *) range
                options:(struct CABasicAnimationOptions *) options
{
   struct CABasicAnimationTypeDefinition   *p;

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
   self->_property  = property;
   self->_quadratic = CAQuadraticForAnimationCurve( options->curve);
   self->_tween     = options->tween ? options->tween : CAQuadraticGetValue;

   p                          = CABasicAnimationTypeDefinitionGet( type);
   self->_interpolate         = p->interpolate;
   self->_interpolateAdditive = p->interpolateAdditive;

   self->_valueType = type;
   self->_start     = range->start;
   self->_end       = range->end;

   return( self);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
         startRectValue:(CGRect) start
           endRectValue:(CGRect) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CAAnimationValueMakeWithRect( start);
   range.end   = CAAnimationValueMakeWithRect( end);
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

   range.start = CAAnimationValueMakeWithEdgeInsets( start);
   range.end   = CAAnimationValueMakeWithEdgeInsets( end);
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

   range.start = CAAnimationValueMakeWithSize( start);
   range.end   = CAAnimationValueMakeWithSize( end);
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

   range.start = CAAnimationValueMakeWithPoint( start);
   range.end   = CAAnimationValueMakeWithPoint( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat2
                       valueRange:&range
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
   startFloatArrayValue:(struct mulle__floatarray) start
     endFloatArrayValue:(struct mulle__floatarray) end
                options:(struct CABasicAnimationOptions *) options
 {
   struct CAAnimationValueRange  range;
   unsigned int                  n;
   struct mulle_allocator        *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);

   n = mulle__floatarray_get_count( &start);
   _mulle__floatarray_init( &range.start.floatArray, n, allocator);
   _mulle__floatarray_add_array( &range.start.floatArray,
                                 &start,
                                 mulle_range_make_all(),
                                 allocator);

   n = mulle__floatarray_get_count( &end);
   _mulle__floatarray_init( &range.end.floatArray, n, allocator);
   _mulle__floatarray_add_array( &range.end.floatArray,
                                 &end,
                                 mulle_range_make_all(),
                                 allocator);

   return( [self initWithProperty:property
                        valueType:CAAnimationValueFloatArray
                       valueRange:&range
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
       startObjectValue:(id <CAInterpolatableValue>) start
         endObjectValue:(id <CAInterpolatableValue>) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   assert( ! start || [start conformsToProtocol:@protocol( CAInterpolatableValue)]);
   assert( ! end   || [end conformsToProtocol:@protocol( CAInterpolatableValue)]);

   range.start.objectValue = [start copy];
   range.end.objectValue   = [end copy];
   return( [self initWithProperty:property
                        valueType:CAAnimationValueObject
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


static void   releasePrevious( CABasicAnimation *self)
{
   struct mulle_allocator   *allocator;

   switch( self->_valueType)
   {
   case CAAnimationValueFloatArray :
      allocator = MulleObjCInstanceGetAllocator( self);
      _mulle__floatarray_done( &self->_previous.floatArray, allocator);
      break;

   case CAAnimationValueObject :
      [self->_previous.objectValue autorelease];
      break;
   }
}


static void   releaseStartEnd( CABasicAnimation *self)
{
   struct mulle_allocator   *allocator;

   switch( self->_valueType)
   {
   case CAAnimationValueFloatArray :
      allocator = MulleObjCInstanceGetAllocator( self);
      _mulle__floatarray_done( &self->_previous.floatArray, allocator);
      _mulle__floatarray_done( &self->_end.floatArray, allocator);
      _mulle__floatarray_done( &self->_start.floatArray, allocator);
      break;

   case CAAnimationValueObject :
      [self->_previous.objectValue autorelease];
      [self->_end.objectValue autorelease];
      [self->_start.objectValue autorelease];
      break;
   }
}



- (void) dealloc
{
   releaseStartEnd( self);
   releasePrevious( self);
   [super dealloc];
}


#pragma mark - Petty accessors


- (BOOL) isAdditive
{
   return( _state.bits & CAAnimationAdditive);
}


- (BOOL) isCumulative
{
   return( _state.bits & CAAnimationCumulative);
}


//
// this is called by the layer (ahem) animatableObject
// which does the animation now
//
- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(mulle_relativetime_t) elapsedTime
{
   double   x;

   assert( t >= 0.0);
   assert( t <= 1.0);
   assert( object);

   x = (self->_tween)( &self->_quadratic, t);
   // x can be <0.0 > 1.0 though!
   if( _state.bits & CAAnimationAdditive)
      CABasicAnimationAnimateObjectAdditive( self, object, x);
   else
      CABasicAnimationAnimateObject( self, object, x);
}


- (void) reset
{
   [super reset];

   releasePrevious( self);
   memset( &_previous, 0, sizeof( union CAAnimationValue));
}


- (void) animationIndexDidChange
{
   if( _state.bits & CAAnimationCumulative)
   {
      assert( _state.bits & CAAnimationAdditive);

      releasePrevious( self);
      memset( &_previous, 0, sizeof( union CAAnimationValue));
   }
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



@implementation NSObject( CABasicAnimation)

+ (CAAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                       startObjectValue:(id) start
                         endObjectValue:(id) end
                                options:(struct CABasicAnimationOptions *) options
{
   return( [[[CABasicAnimation alloc] initWithProperty:property
                                      startObjectValue:start
                                        endObjectValue:end
                                               options:options] autorelease]);
}

@end
