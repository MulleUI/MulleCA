//
//  CGGeometry+MulleObjC.h
//  MulleCA
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
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
#import "import.h"


// TODO: move this stuff to CGBase+MulleObjC.h until CGRect
static inline void   MulleObjectSetBOOL( id obj, SEL sel, BOOL value)
{
   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, (id) value);
}


static inline BOOL   MulleObjectGetBOOL( id obj, SEL sel)
{
   return( (BOOL) (intptr_t) mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, obj));
}


static inline void   MulleObjectSetNSInteger( id obj, SEL sel, NSInteger value)
{
   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, (id) value);
}


static inline NSInteger   MulleObjectGetNSInteger( id obj, SEL sel)
{
   return( (NSInteger) mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, obj));
}


static inline void   MulleObjectSetNSRange( id obj, SEL sel, NSRange range)
{
   mulle_metaabi_union_void_return( struct { NSRange range; })  param;

   param.p.range = range;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline NSRange   MulleObjectGetNSRange( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { NSRange range; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.range);
}


static inline void   MulleObjectSetCGFloat( id obj, SEL sel, CGFloat value)
{
   mulle_metaabi_union_void_return( struct { CGFloat value; })  param;

   param.p.value = value;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CGFloat   MulleObjectGetCGFloat( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGFloat value; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.value);
}



static inline CGFloat2   MulleObjectGetCGFloat2
( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGFloat2 value; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.value);
}


static inline void   MulleObjectSetCGFloat2
( id obj, SEL sel, CGFloat2 value)
{
   mulle_metaabi_union_void_return( struct { CGFloat2 value; })  param;

   param.p.value = value;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}



static inline CGFloat4   MulleObjectGetCGFloat4
( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGFloat4 value; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.value);
}


static inline void   MulleObjectSetCGFloat4
( id obj, SEL sel, CGFloat4 value)
{
   mulle_metaabi_union_void_return( struct { CGFloat4 value; })  param;

   param.p.value = value;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}



static inline void   MulleObjectSetCGRect( id obj, SEL sel, CGRect rect)
{
   mulle_metaabi_union_void_return( struct { CGRect rect; })  param;

   param.p.rect = rect;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CGRect   MulleObjectGetCGRect( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGRect rect; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.rect);
}


static inline void   MulleObjectSetCGSize( id obj, SEL sel, CGSize size)
{
   mulle_metaabi_union_void_return( struct { CGSize size; })  param;

   param.p.size = size;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CGSize   MulleObjectGetCGSize( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGSize size; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.size);
}


static inline void   MulleObjectSetCGPoint( id obj, SEL sel, CGPoint point)
{
   mulle_metaabi_union_void_return( struct { CGPoint point; })  param;

   param.p.point = point;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CGPoint   MulleObjectGetCGPoint( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGPoint point; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.point);
}


static inline void   MulleObjectSetObject( id obj, SEL sel, id value)
{
   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, value);
}


static inline id   MulleObjectGetObject( id obj, SEL sel)
{
   return( mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, obj));
}


static inline void   MulleObjectSetCACircle( id obj, SEL sel, CACircle circle)
{
   mulle_metaabi_union_void_return( struct { CACircle circle; })  param;

   param.p.circle = circle;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CACircle   MulleObjectGetCACircle( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CACircle circle; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.circle);
}


static inline void   MulleObjectSetCAPolarPoint( id obj, SEL sel, CAPolarPoint polar)
{
   mulle_metaabi_union_void_return( struct { CAPolarPoint polar; })  param;

   param.p.polar = polar;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CAPolarPoint   MulleObjectGetCAPolarPoint( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CAPolarPoint polar; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.polar);
}



static inline char   *CAPoseUTF8String( CAPose value)
{
   return( CGFloat4UTF8String( CAPoseGetFloat4( value)));
}

