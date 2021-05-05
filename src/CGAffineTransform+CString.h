//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local CGAffineTransform over one in import.h
#ifdef __has_include
# if __has_include( "CGAffineTransform.h")
#  import "CGAffineTransform.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


char   *CGAffineTransformRefCStringDescription( CGAffineTransform *xform);


static inline char   *CGAffineTransformCStringDescription( CGAffineTransform xform)
{
   return( CGAffineTransformRefCStringDescription( &xform));
}


static inline char   *_NVGtransformCStringDescription( _NVGtransform xform)
{
   return( CGAffineTransformRefCStringDescription( _NVGtransformAsCGAffineTransformRef( xform)));
}
