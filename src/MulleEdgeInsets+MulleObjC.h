//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#include "import.h"


static inline void   MulleObjectSetEdgeInsets( id obj, SEL sel, MulleEdgeInsets insets)
{
   mulle_metaabi_union_voidptr_return( struct { MulleEdgeInsets insets; })  param;

   param.p.insets = insets;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline MulleEdgeInsets   MulleObjectGetEdgeInsets( id obj, SEL sel)
{
   mulle_metaabi_union_voidptr_parameter( struct { MulleEdgeInsets insets; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.insets);
}


static inline void   MulleObjectSetCornerInsets( id obj, SEL sel, MulleCornerInsets insets)
{
   mulle_metaabi_union_voidptr_return( struct { MulleCornerInsets insets; })  param;

   param.p.insets = insets;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline MulleCornerInsets   MulleObjectGetCornerInsets( id obj, SEL sel)
{
   mulle_metaabi_union_voidptr_parameter( struct { MulleCornerInsets insets; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.insets);
}


