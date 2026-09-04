//
//  NSObject+CAAnimation.m
//  MulleCA
//
//  Copyright (c) 2022 Nat! - Mulle kybernetiK.
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
#import "NSObject+CAAnimation.h"

#import "import-private.h"

#import "CAAnimationStorage.h"
#import "CAAnimationGroup.h"
#import "CABasicAnimation.h"
#import "CGGeometry+MulleObjC.h"
#import "MulleEdgeInsets+MulleObjC.h"


enum
{
   add_to_self            = 0x1,  // experimental, unused
   add_to_animation_group = 0x2
};



static struct CAAnimationPropertyDefinition   extensions[ 8];
static unsigned int                           n_extensions;


struct CAAnimationPropertyDefinition
   *CAAnimationPropertyDefinitionSearchExtension( char *s, NSUInteger length)
{
   struct CAAnimationPropertyDefinition  *p;
   struct CAAnimationPropertyDefinition  *sentinel;

   p        = extensions;
   sentinel = &p[ n_extensions];
   for( ; p < sentinel; p++)
      if( (*p->matchRuntimeStructName)( s, length))
         return( p);
   return( NULL);
}


void  CAAnimationPropertyDefinitionRegister( struct CAAnimationPropertyDefinition *p)
{
   if( n_extensions >= 8)
      abort();

   assert( p);
   assert( p->matchRuntimeStructName);
   assert( p->animateProperty);

   extensions[ n_extensions++] = *p;
}


void  CAPropertyAnimationContextAddAnimation( struct CAPropertyAnimationContext *ctx,
                                              CAAnimation *animation)
{
   if( ctx->flags & add_to_self)
      [(id <CAAnimationStorageObject>) ctx->self addAnimation:animation];
   else
      [animation setAnimationObject:ctx->self];

   if( ctx->flags & add_to_animation_group)
      [ctx->animationGroup addAnimation:animation];
}


// returns 0 on match
static inline int   string_matcher( char *s, char *other, size_t other_len)
{
   if( strlen( s) != other_len)
      return( 1);
   return( strncmp( s, other, other_len));
}


static void   animate_bool_property( struct _mulle_objc_property *property,
                                     struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   NSInteger     startValue;
   NSInteger     endValue;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startValue = MulleObjectGetBOOL( ctx->snapshot, getter);
   endValue   = MulleObjectGetBOOL( ctx->self, getter);
   if( startValue == endValue)
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:startValue
                                           endIntegerValue:endValue
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);
      // reset to start position
      MulleObjectSetBOOL( ctx->self, setter, startValue);
   }
}


static void   animate_integer_property( struct _mulle_objc_property *property,
                                        struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   NSInteger     startValue;
   NSInteger     endValue;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startValue = MulleObjectGetNSInteger( ctx->snapshot, getter);
   endValue   = MulleObjectGetNSInteger( ctx->self, getter);;
   if( startValue == endValue)
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:startValue
                                           endIntegerValue:endValue
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      MulleObjectSetNSInteger( ctx->self, setter, startValue);
   }
}


static void   animate_range_property( struct _mulle_objc_property *property,
                                      struct CAPropertyAnimationContext *ctx)
{
   CAAnimation  *animation;
   NSRange      startRange;
   NSRange      endRange;
   SEL          getter;
   SEL          setter;

   getter     = mulle_objc_property_get_getter( property);
   startRange = MulleObjectGetNSRange( ctx->snapshot, getter);
   endRange   = MulleObjectGetNSRange( ctx->self, getter);
   if( NSEqualRanges( startRange, endRange))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startRangeValue:startRange
                                             endRangeValue:endRange
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      // can not be additive
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetNSRange( ctx->self, setter, startRange);
   }
}


static void   animate_float_property( struct _mulle_objc_property *property,
                                      struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGFloat       startValue;
   CGFloat       endValue;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startValue = MulleObjectGetCGFloat( ctx->snapshot, getter);
   endValue   = MulleObjectGetCGFloat( ctx->self, getter);;
   if( startValue == endValue)
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startFloatValue:startValue
                                             endFloatValue:endValue
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      MulleObjectSetCGFloat( ctx->self, setter, startValue);
   }
}


//
// intended to be used by CACircle, CAPolarPoint, CGPoint, CGSize
//
static void   animate_float2_property( struct _mulle_objc_property *property,
                                       struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGFloat2      start;
   CGFloat2      end;
   SEL           getter;
   SEL           setter;

   getter = mulle_objc_property_get_getter( property);
   start  = MulleObjectGetCGFloat2( ctx->snapshot, getter);
   end    = MulleObjectGetCGFloat2( ctx->self, getter);
   if( CGFloat2EqualToFloat2( start, end))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                          startFloat2Value:start
                                            endFloat2Value:end
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGFloat2( ctx->self, setter, start);
   }
}


//
// intended to be used by CGRect, MulleEdgeInsets, MulleCornerInsets
//
static void   animate_float4_property( struct _mulle_objc_property *property,
                                       struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGFloat4      start;
   CGFloat4      end;
   SEL           getter;
   SEL           setter;

   getter = mulle_objc_property_get_getter( property);
   start  = MulleObjectGetCGFloat4( ctx->snapshot, getter);
   end    = MulleObjectGetCGFloat4( ctx->self, getter);
   if( CGFloat4EqualToFloat4( start, end))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startFloat4Value:start
                                             endFloat4Value:end
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGFloat4( ctx->self, setter, start);
   }
}



static void   animate_point_property( struct _mulle_objc_property *property,
                                      struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGPoint       startPoint;
   CGPoint       endPoint;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startPoint = MulleObjectGetCGPoint( ctx->snapshot, getter);
   endPoint   = MulleObjectGetCGPoint( ctx->self, getter);
   if( CGPointEqualToPoint( startPoint, endPoint))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startPointValue:startPoint
                                             endPointValue:endPoint
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGPoint( ctx->self, setter, startPoint);
   }
}


static void   animate_size_property( struct _mulle_objc_property *property,
                                     struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGSize        startSize;
   CGSize        endSize;
   SEL           getter;
   SEL           setter;

   getter    = mulle_objc_property_get_getter( property);
   startSize = MulleObjectGetCGSize( ctx->snapshot, getter);
   endSize   = MulleObjectGetCGSize( ctx->self, getter);
   if( CGSizeEqualToSize( startSize, endSize))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                            startSizeValue:startSize
                                              endSizeValue:endSize
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGSize( ctx->self, setter, startSize);
   }
}


static void   animate_rect_property( struct _mulle_objc_property *property,
                                     struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGRect        startRect;
   CGRect        endRect;
   SEL           getter;
   SEL           setter;

   getter    = mulle_objc_property_get_getter( property);
   startRect = MulleObjectGetCGRect( ctx->snapshot, getter);
   endRect   = MulleObjectGetCGRect( ctx->self, getter);
   if( CGRectEqualToRect( startRect, endRect))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                            startRectValue:startRect
                                              endRectValue:endRect
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGRect( ctx->self, setter, startRect);
   }
}


static void   animate_edge_insets_property( struct _mulle_objc_property *property,
                                           struct CAPropertyAnimationContext *ctx)
{
   CAAnimation       *animation;
   MulleEdgeInsets   startInsets;
   MulleEdgeInsets   endInsets;
   SEL               getter;
   SEL               setter;

   getter      = mulle_objc_property_get_getter( property);
   startInsets = MulleObjectGetEdgeInsets( ctx->snapshot, getter);
   endInsets   = MulleObjectGetEdgeInsets( ctx->self, getter);
   if( MulleEdgeInsetsEqualToEdgeInsets( startInsets, endInsets))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                      startEdgeInsetsValue:startInsets
                                        endEdgeInsetsValue:endInsets
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetEdgeInsets( ctx->self, setter, startInsets);
   }
}


static inline void   animate_corner_insets_property( struct _mulle_objc_property *property,
                                                     struct CAPropertyAnimationContext *ctx)
{
   // abuse these being four floats, samas MulleObjectSetEdgeInsets
   return( animate_float4_property( property, ctx));
}


static inline void   animate_polar_point_property( struct _mulle_objc_property *property,
                                                   struct CAPropertyAnimationContext *ctx)
{
   return( animate_float2_property( property, ctx));
}


static inline void   animate_circle_property( struct _mulle_objc_property *property,
                                              struct CAPropertyAnimationContext *ctx)
{
   return( animate_float2_property( property, ctx));
}


static void   animate_object_property( struct _mulle_objc_property *property,
                                       struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   id            startObject;
   id            endObject;
   SEL           getter;
   SEL           setter;
   Class         cls;

   getter      = mulle_objc_property_get_getter( property);
   startObject = MulleObjectGetObject( ctx->snapshot, getter);
   endObject   = MulleObjectGetObject( ctx->self, getter);

   // could ask for isEqual: but...
   if( startObject == endObject)
      return;

   cls = [startObject class];
   if( ! cls)
      cls = [endObject class];

   setter    = mulle_objc_property_get_setter( property);
   animation = [cls animationFrom:startObject
                                     to:endObject
                               property:property
                                options:&ctx->animationOptions];

   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetObject( ctx->self, setter, startObject);
   }
}


@implementation NSObject( CAAnimation)

- (BOOL) __isCAAnimation
{
   return( NO);
}


static mulle_objc_walkcommand_t
   caanimation_walkproperties_callback( struct _mulle_objc_property *property,
                                        struct _mulle_objc_infraclass *infra,
                                        void *userinfo)
{
   struct CAPropertyAnimationContext      *ctx = userinfo;
   struct CAAnimationPropertyDefinition   *p;
   char                                   *signature;
   char                                   *name_b;
   char                                   *name_e;
   size_t                                 name_len;

   if( ! (_mulle_objc_property_get_bits( property) & _mulle_objc_property_observable))
      return( mulle_objc_walk_ok);

   signature = mulle_objc_property_get_signature( property);


//   printf( "%s @property %s = %s\n", _mulle_objc_infraclass_get_name( infra),
//                                      mulle_objc_property_get_name( property),
//                                      signature);

   switch( *signature)
   {
   case _C_RETAIN_ID :
   case _C_COPY_ID   : // future: only one allowable!
   case _C_ASSIGN_ID : animate_object_property( property, ctx);
                       return( mulle_objc_walk_ok);

   // MEMO: does not work, because our BOOL is really an int
   case _C_BOOL      : animate_bool_property( property, ctx);
                       return( mulle_objc_walk_ok);

   case _C_INT       : if( sizeof( int) != sizeof( NSInteger))
                          goto type_fail;
                       animate_integer_property( property, ctx);
                       return( mulle_objc_walk_ok);

   case _C_LNG       : if( sizeof( long) != sizeof( NSInteger))
                          goto type_fail;
                       animate_integer_property( property, ctx);
                       return( mulle_objc_walk_ok);

   case _C_LNG_LNG   : if( sizeof( long long) != sizeof( NSInteger))
                          goto type_fail;
                       animate_integer_property( property, ctx);
                       return( mulle_objc_walk_ok);

   case _C_FLT       : if( sizeof( float) != sizeof( CGFloat))
                          goto type_fail;
                       animate_float_property( property, ctx);
                       return( mulle_objc_walk_ok);

   case _C_DBL       : if( sizeof( double) != sizeof( CGFloat))
                          goto type_fail;
                       animate_float_property( property, ctx);
                       return( mulle_objc_walk_ok);
   case _C_STRUCT_B  : // drop down to following,
                       break;

   default           : goto type_fail;
   }

   // TODO: if struct is [ff] [fff] or [ffff], then use generic animation
   //       code ?
   //
   // struct code
   name_b = signature + 1;
   name_e = strchr( name_b, '=');
   assert( name_e && strchr( name_b, ',') > name_e);
   name_len = name_e - name_b;

   // Mulle[C]ornerInsets
   // Mulle[E]dgeInsets
   // CGSiz[e]
   // NSRan[g]e is actually mulle_range though
   // NVGCo[l]or
   // CGPoi[n]t
   // mulle[_]range
   // CGRec[t]
   // CACir[c]le
   // CAPol[a]rPoint

   if( name_len >= 6)
   {
      switch( name_b[ 5])
      {
      // soon to be CGEdgeInsets ?
      case 'C' : if( ! string_matcher( "MulleCornerInsets", name_b, name_len))
                 {
                     animate_corner_insets_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 'E' : if( ! string_matcher( "MulleEdgeInsets", name_b, name_len))
                 {
                     animate_edge_insets_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 'a' : if( ! string_matcher( "CAPolarPoint", name_b, name_len))
                 {
                     animate_polar_point_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 'c' : if( ! string_matcher( "CACircle", name_b, name_len))
                 {
                     animate_circle_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 'e' : if( ! string_matcher( "CGSize", name_b, name_len))
                 {
                     animate_size_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 'g' : if( ! string_matcher( "NSRange", name_b, name_len))
                 {
                    animate_range_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 'n' : if( ! string_matcher( "CGPoint", name_b, name_len))
                 {
                     animate_point_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case '_' : if( ! string_matcher( "mulle_range", name_b, name_len))
                 {
                     animate_range_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      case 't' : if( ! string_matcher( "CGRect", name_b, name_len))
                 {
                     animate_rect_property( property, ctx);
                     return( mulle_objc_walk_ok);
                 }
                 break;
      }
   }

   p = CAAnimationPropertyDefinitionSearchExtension( name_b, name_len);
   if( p)
   {
      (*p->animateProperty)( property, ctx);
      return( mulle_objc_walk_ok);
   }

type_fail:
   MulleUICLog( "CABasicAnimation does not support type \"%s\" of property \"%s\"",
                signature, _mulle_objc_property_get_name( property));
   assert( 0 && "wrong type for observable property");
   return( mulle_objc_walk_ok);
}


- (void) generateAnimationsForPropertiesWithSnapshot:(id) snapshot
                                      animationGroup:(CAAnimationGroup *) animationGroup
{
   struct CAPropertyAnimationContext   ctxt;
   struct _mulle_objc_infraclass       *infra;

   if( ! snapshot || ! animationGroup)
      return;

   infra               = mulle_objc_object_get_infraclass( snapshot);
   ctxt.snapshot       = snapshot;
   ctxt.animationGroup = animationGroup;
   ctxt.flags          = add_to_animation_group;
   ctxt.self           = self;

   [animationGroup setupBasicAnimationOptions:&ctxt.animationOptions];
   [animationGroup setAnimationObject:self];
   _mulle_objc_infraclass_walk_properties( infra,
                                           _mulle_objc_infraclass_get_inheritance( infra),
                                           caanimation_walkproperties_callback,
                                           &ctxt);
}

@end
