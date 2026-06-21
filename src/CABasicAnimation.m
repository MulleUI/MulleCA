#import "CABasicAnimation.h"

#import "import-private.h"
#import "CAAnimation+DebugPrivate.h"

#include <assert.h>
#include <mulle-objc-runtime/mulle-metaabi-call.h>

#ifndef mulle_metaabi_call
#define mulle_metaabi_call   mulle_metaabi_object_call
#endif


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
   mulle_metaabi_call( &value, object, self->_property->getter);

   newValue                     = value -  self->_previous.integerValue + diff;
   self->_previous.integerValue = diff;

   CAAnimationInterpolateLog( "%g: %#@ %s -> %td",
                                x,
                                object,
                                mulle_objc_property_get_name( self->_property),
                                newValue);

   mulle_metaabi_call( , object, self->_property->setter, newValue);
}


void   CABasicAnimationSetInterpolatedFloatAdditive( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   CGFloat   diff;
   CGFloat   value;
   CGFloat   newValue;

   diff = CAInterpolateAdditive( self->_start.floatValue, self->_end.floatValue, x);
   mulle_metaabi_call( &value, object, self->_property->getter);

   newValue = value - self->_previous.floatValue + diff;

   CAAnimationInterpolateLog( "%#@ %s :: %g - %g + %g -> %g",
                              object,
                              mulle_objc_property_get_name( self->_property),
                              value,
                              self->_previous.floatValue,
                              diff,
                              newValue);

   self->_previous.floatValue = diff;

   mulle_metaabi_call( , object, self->_property->setter, newValue);
}


void   CABasicAnimationSetInterpolatedFloat2Additive( CABasicAnimation *self,
                                                      id object,
                                                      double x)
{
   struct CGFloat2   diff;
   struct CGFloat2   value;
   struct CGFloat2   newValue;

   diff.v0 = CAInterpolateAdditive( self->_start.float2Value.v0, self->_end.float2Value.v0, x);
   diff.v1 = CAInterpolateAdditive( self->_start.float2Value.v1, self->_end.float2Value.v1, x);

   mulle_metaabi_call( &value, object, self->_property->getter);

   newValue.v0 = value.v0 - self->_previous.float2Value.v0 + diff.v0;
   newValue.v1 = value.v1 - self->_previous.float2Value.v1 + diff.v1;

   self->_previous.float2Value.v0 = diff.v0;
   self->_previous.float2Value.v1 = diff.v1;

   CAAnimationLogVerbose( "%#@ %s -> %s", object,
                          mulle_objc_property_get_name( self->_property),
                         CGFloat2UTF8String( newValue));
   mulle_metaabi_call( , object, self->_property->setter, newValue);
}


void   CABasicAnimationSetInterpolatedFloat4Additive( CABasicAnimation *self,
                                                      id object,
                                                      double x)
{
   struct CGFloat4   diff;
   struct CGFloat4   value;
   struct CGFloat4   newValue;

   // now
   diff.v0 = CAInterpolateAdditive( self->_start.float4Value.v0, self->_end.float4Value.v0, x);
   diff.v1 = CAInterpolateAdditive( self->_start.float4Value.v1, self->_end.float4Value.v1, x);
   diff.v2 = CAInterpolateAdditive( self->_start.float4Value.v2, self->_end.float4Value.v2, x);
   diff.v3 = CAInterpolateAdditive( self->_start.float4Value.v3, self->_end.float4Value.v3, x);

   mulle_metaabi_call( &value, object, self->_property->getter);

   newValue.v0 = value.v0 - self->_previous.float4Value.v0 + diff.v0;
   newValue.v1 = value.v1 - self->_previous.float4Value.v1 + diff.v1;
   newValue.v2 = value.v2 - self->_previous.float4Value.v2 + diff.v2;
   newValue.v3 = value.v3 - self->_previous.float4Value.v3 + diff.v3;

   self->_previous.float4Value.v0 = diff.v0;
   self->_previous.float4Value.v1 = diff.v1;
   self->_previous.float4Value.v2 = diff.v2;
   self->_previous.float4Value.v3 = diff.v3;

   CAAnimationInterpolateLog( "%#@ %s -> %s", object,
                            mulle_objc_property_get_name( self->_property),
                            CGFloat4UTF8String( newValue));
   mulle_metaabi_call( , object, self->_property->setter, newValue);
}


static void   CABasicAnimationSetInterpolatedObjectAdditive( CABasicAnimation *self,
                                                            id object,
                                                            double x)
{
   id   diff;
   id   value;
   id   newValue;

   if( ! self->_start.objectValue)
      diff = [self->_end.objectValue interpolateTo:nil
                                            factor:(1.0 - x)
                                          additive:YES];
   else
      diff = [self->_start.objectValue interpolateTo:self->_end.objectValue
                                              factor:x
                                            additive:YES];

   value = mulle_objc_object_call_variable( object,
                                            self->_property->getter,
                                            object);
   newValue = [value interpolatedValueWithDiff:diff
                                  previousDiff:self->_previous.objectValue];

   CAAnimationInterpolateLog( "%#@ %s :: %#@ - %#@ + %#@ -> %#@",
                              object,
                              mulle_objc_property_get_name( self->_property),
                              value,
                              self->_previous.objectValue,
                              diff,
                              newValue);
   [self->_previous.objectValue autorelease];
   self->_previous.objectValue = [diff copy];

   mulle_objc_object_call_variable( object, self->_property->setter, newValue);
}




static void   CABasicAnimationSetInterpolatedBOOL( CABasicAnimation *self,
                                                   id object,
                                                   double x)
{
   BOOL    previous;
   BOOL    value;
   double  interpolated;

   interpolated = round( CAInterpolate( self->_start.boolValue, self->_end.boolValue, x));
   value        = interpolated >= 1.0 ? YES : NO;

   mulle_metaabi_call( &previous, object, self->_property->getter);
   CAAnimationInterpolateLog( "%#@ %s :: %s -> %s",
                              object,
                              mulle_objc_property_get_name( self->_property),
                              previous ? "YES" : "NO",
                              value ? "YES" : "NO");
   mulle_metaabi_call( , object, self->_property->setter, value);
}


static void   CABasicAnimationSetInterpolatedInteger( CABasicAnimation *self,
                                                      id object,
                                                      double x)
{
   NSInteger   previous;
   NSInteger   value;

   value = (NSInteger) round( CAInterpolate( self->_start.integerValue,
                                             self->_end.integerValue,
                                             x));
   mulle_metaabi_call( &previous, object, self->_property->getter);
   CAAnimationInterpolateLog( "%g: %#@ %s: %td -> %td",
                              x,
                              object,
                              mulle_objc_property_get_name( self->_property),
                              previous,
                              value);

   mulle_metaabi_call( , object, self->_property->setter, value);
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
   mulle_metaabi_call( , object, self->_property->setter, value);
}


static void   CABasicAnimationSetInterpolatedFloat( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   CGFloat   value;

   value = CAInterpolate( self->_start.floatValue, self->_end.floatValue, x);
   mulle_metaabi_call( , object, self->_property->setter, value);
}


static void   CABasicAnimationSetInterpolatedFloat2( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CGFloat2   value;

   value.v0 = CAInterpolate( self->_start.float2Value.v0, self->_end.float2Value.v0, x);
   value.v1 = CAInterpolate( self->_start.float2Value.v1, self->_end.float2Value.v1, x);
   mulle_metaabi_call( , object, self->_property->setter, value);
}


static void   CABasicAnimationSetInterpolatedFloat4( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   struct CGFloat4   value;

   value.v0 = CAInterpolate( self->_start.float4Value.v0, self->_end.float4Value.v0, x);
   value.v1 = CAInterpolate( self->_start.float4Value.v1, self->_end.float4Value.v1, x);
   value.v2 = CAInterpolate( self->_start.float4Value.v2, self->_end.float4Value.v2, x);
   value.v3 = CAInterpolate( self->_start.float4Value.v3, self->_end.float4Value.v3, x);

   if( self->_debuggingFlags & CAAnimationDebugVerbose)
   {
      struct CGFloat4   previous;

      mulle_metaabi_call( &previous, object, self->_property->getter);
      CAAnimationInterpolateLog( "%#@ %s :: %g %g %g %g -> %g %g %g %g",
                                 object,
                                 mulle_objc_property_get_name( self->_property),
                                 previous.v0,
                                 previous.v1,
                                 previous.v2,
                                 previous.v3,
                                 value.v0,
                                 value.v1,
                                 value.v2,
                                 value.v3);
   }

   mulle_metaabi_call( , object, self->_property->setter, value);
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
   mulle_metaabi_call( , object, self->_property->setter, value);
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

   CAAnimationInterpolateLog( "%#@ %s -> %#@", object,
                               mulle_objc_property_get_name( self->_property),
                               newValue);

   mulle_objc_object_call_variable( object, self->_property->setter, newValue);
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
   case CAAnimationValueCGFloat2   : return( CGFloat2UTF8String( value.float2Value));
   case CAAnimationValueCGFloat4   : return( CGFloat4UTF8String( value.float4Value));
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
      CA_BASIC_ANIMATION_OPTIONS_DATA_CURVE( 0,    // delay
                                             1,    // duration
                                             0,    // initial elapsed
                                             1.0,  // repeat
                                             0,    // bits
                                             CAAnimationCurveLinear);


static void   CABasicAnimationAbort( CABasicAnimation *self, id object, double x)
{
   mulle_fprintf( stderr, "This kind of interpolation is not supported on %ld\n", self->_valueType);
   abort();
}


static void  assert_property_is_compatible( struct _mulle_objc_property *property,
                                            char *signature)
{
   char *property_signature;

   property_signature = _mulle_objc_property_get_signature( property);
   if( _mulle_objc_ivarsignature_is_binary_compatible( property_signature, signature))
      return;
   MulleUICLog( "Value encoding \"%s\" may not match encoding \"%s\" of property \"%s\"",
                           signature,
                           property_signature,
                           _mulle_objc_property_get_name( property));
}


// Convenience factory methods
+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                             valueType:(CAAnimationValueType) type
                            valueRange:(struct CAAnimationValueRange *) range
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                                valueType:type
                               valueRange:range
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                        startRectValue:(CGRect) start
                          endRectValue:(CGRect) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                           startRectValue:start
                             endRectValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                  startEdgeInsetsValue:(MulleEdgeInsets) start
                    endEdgeInsetsValue:(MulleEdgeInsets) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                     startEdgeInsetsValue:start
                       endEdgeInsetsValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                        startSizeValue:(CGSize) start
                          endSizeValue:(CGSize) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                           startSizeValue:start
                             endSizeValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startPointValue:(CGPoint) start
                         endPointValue:(CGPoint) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                          startPointValue:start
                            endPointValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startFloatValue:(CGFloat) start
                         endFloatValue:(CGFloat) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                          startFloatValue:start
                            endFloatValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                      startFloat2Value:(CGFloat2) start
                        endFloat2Value:(CGFloat2) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                         startFloat2Value:start
                           endFloat2Value:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                      startFloat4Value:(CGFloat4) start
                        endFloat4Value:(CGFloat4) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                         startFloat4Value:start
                           endFloat4Value:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                  startFloatArrayValue:(struct mulle__floatarray) start
                    endFloatArrayValue:(struct mulle__floatarray) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                     startFloatArrayValue:start
                       endFloatArrayValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                      startObjectValue:(id <CAInterpolatableValue>) start
                        endObjectValue:(id <CAInterpolatableValue>) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                         startObjectValue:start
                           endObjectValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startRangeValue:(NSRange) start
                         endRangeValue:(NSRange) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                          startRangeValue:start
                            endRangeValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                     startIntegerValue:(NSInteger) start
                       endIntegerValue:(NSInteger) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                        startIntegerValue:start
                          endIntegerValue:end
                                  options:options] autorelease];
}

+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                        startBOOLValue:(BOOL) start
                          endBOOLValue:(BOOL) end
                               options:(struct CABasicAnimationOptions *) options
{
   return [[[self alloc] initWithProperty:property
                           startBOOLValue:start
                             endBOOLValue:end
                                  options:options] autorelease];
}



- (id) initWithProperty:(struct _mulle_objc_property *) property
              valueType:(CAAnimationValueType) type
             valueRange:(struct CAAnimationValueRange *) range
                options:(struct CABasicAnimationOptions *) options
{
   struct CABasicAnimationTypeDefinition   *p;

   if( ! range || ! property)
   {
      [self release];
      return( nil);
   }

   if( ! options)
      options = (void *) &CABasicAnimationDefaultOptions;

   //
   // its important that range will be cleanly released in -dealloc, as
   // we possibly get retained values. so copy it over now.
   // might as well do the others as well
   //
   self->_start               = range->start;
   self->_end                 = range->end;
   self->_quadratic           = CACubicForAnimationCurve( options->curve);
   self->_tween               = options->tween ? options->tween : CATweenForAnimationCurve( options->curve);
   if( ! self->_tween)
      self->_tween            = CACubicGetValue;

   p                          = CABasicAnimationTypeDefinitionGet( type);
   self->_interpolate         = p->interpolate;
   self->_interpolateAdditive = p->interpolateAdditive;

   self->_valueType           = type;
   self->_property            = property;

#ifdef DEBUG
   {
      switch( type)
      {
      default :
         break;

      case CAAnimationValueBOOL       :
         assert_property_is_compatible( property, @encode( BOOL));
         break;

      case CAAnimationValueNSInteger  :
         assert_property_is_compatible( property, @encode( NSInteger));
         break;

      case CAAnimationValueNSRange    :
         assert_property_is_compatible( property, @encode( NSRange));
         break;

      case CAAnimationValueCGFloat    :
         assert_property_is_compatible( property, @encode( CGFloat));
         break;

      case CAAnimationValueCGFloat2   :
         assert_property_is_compatible( property, @encode( struct CGFloat2 ));
         break;

      case CAAnimationValueCGFloat4   :
         assert_property_is_compatible( property, @encode( struct CGFloat4));
         break;

      case CAAnimationValueFloatArray :
         assert_property_is_compatible( property, @encode( struct mulle__floatarray));
         break;

      case CAAnimationValueObject     :
         assert_property_is_compatible( property, @encode( id <CAInterpolatableValue>));
         break;
      }
   }
#endif

   self = [self initWithAnimationOptions:&options->base];
   if( self)
   {
      CAAnimationLog( "property: \"%s\"",  mulle_objc_property_get_name( property));
   }
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
   _mulle__floatarray_add_floatarray( &range.start.floatArray,
                                 &start,
                                 mulle_range_make_all(),
                                 allocator);

   n = mulle__floatarray_get_count( &end);
   _mulle__floatarray_init( &range.end.floatArray, n, allocator);
   _mulle__floatarray_add_floatarray( &range.end.floatArray,
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
       startFloat2Value:(CGFloat2) start
         endFloat2Value:(CGFloat2) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start.float2Value = start;
   range.end.float2Value   = end;
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat2
                       valueRange:&range
                          options:options]);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
       startFloat4Value:(CGFloat4) start
         endFloat4Value:(CGFloat4) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start.float4Value = start;
   range.end.float4Value   = end;
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGFloat4
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


- (void) mulleGainAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   [super mulleGainAccessWithUniquingSet:uniquing];

   if( self->_valueType == CAAnimationValueObject)
   {
      if( mulle_pointerset_insert( uniquing, self->_start.objectValue))
         [self->_start.objectValue mulleGainAccessWithUniquingSet:uniquing];
      if( mulle_pointerset_insert( uniquing, self->_end.objectValue))
         [self->_end.objectValue mulleGainAccessWithUniquingSet:uniquing];
      if( mulle_pointerset_insert( uniquing, self->_previous.objectValue))
         [self->_previous.objectValue mulleGainAccessWithUniquingSet:uniquing];  // ???
   }
}


- (void) mulleRelinquishAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   if( self->_valueType == CAAnimationValueObject)
   {
      if( mulle_pointerset_insert( uniquing, self->_previous.objectValue))
         [self->_previous.objectValue mulleRelinquishAccessWithUniquingSet:uniquing]; // ???
      if( mulle_pointerset_insert( uniquing, self->_end.objectValue))
         [self->_end.objectValue mulleRelinquishAccessWithUniquingSet:uniquing];
      if( mulle_pointerset_insert( uniquing, self->_start.objectValue))
         [self->_start.objectValue mulleRelinquishAccessWithUniquingSet:uniquing];
   }
   [super mulleRelinquishAccessWithUniquingSet:uniquing];
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
    animationFrameInfo:(struct CAAnimationFrameInfo *) info
{
   double   x;

   if( ! info)
      return;

   assert( info->t >= 0.0);
   assert( info->t <= 1.0);
   assert( object);

   x = (self->_tween)( &self->_quadratic, info->t);
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


- (char *) UTF8String
{
   char   *s;

   s = MulleObjC_asprintf( "<%s %p: [%s,%s] %s>",
                           MulleObjCInstanceGetClassNameUTF8String( self),
                           self,
                           CAAnimationValueUTF8String( self->_start, self->_valueType),
                           CAAnimationValueUTF8String( self->_end, self->_valueType),
                           CAAnimationBitsUTF8String( self->_state.bits));
   return( s);
}

@end



@implementation NSObject( CABasicAnimation)

+ (CAAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                       startObjectValue:(id <CAInterpolatableValue>) start
                         endObjectValue:(id <CAInterpolatableValue>) end
                                options:(struct CABasicAnimationOptions *) options
{
   return( [[[CABasicAnimation alloc] initWithProperty:property
                                      startObjectValue:start
                                        endObjectValue:end
                                               options:options] autorelease]);
}

@end
