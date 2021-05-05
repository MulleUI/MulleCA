//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CGAffineTransform+CString.h"

#import "import-private.h"


char   *CGAffineTransformRefCStringDescription( CGAffineTransform *xform)
{
   auto char  *s;

   s = MulleObjC_asprintf( "%.3f %.3f %.3f %.3f %.3f %.3f",
            xform->a,
            xform->b,
            xform->c,
            xform->d,
            xform->tx,
            xform->ty);
   return( s);
}
