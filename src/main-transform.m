#define _GNU_SOURCE

#import "import-private.h"

#import "CGAffineTransform.h"
#import "CGAffineTransform+CString.h"
#import "CGGeometry.h"
#import "CGGeometry+CString.h"


static CGPoint   apply( char *title, CGPoint point, CGAffineTransform xform)
{
   CGPoint   translated;

   translated = CGPointApplyAffineTransform( point, xform);
   fprintf( stderr, "%s: %s -[%s]-> %s\n",
               title,
               CGPointCStringDescription( point),
               CGAffineTransformCStringDescription( xform),
               CGPointCStringDescription( translated));
   return( translated);
}


static void   test( CGPoint point, CGRect frame, CGRect bounds)
{
   CGAffineTransform   xform;
   CGAffineTransform   inverseXform;
   CGAffineTransform   inverse2;
   CGPoint             translated;

   xform        = MulleAffineTransformMakeProjection( frame, bounds);
   inverse2     = CGAffineTransformInvert( xform);
   inverseXform = MulleAffineTransformMakeInverseProjection( frame, bounds);

//   apply( "before", point, CGAffineTransformMakeIdentity());
//   apply( "xform", point, xform);
//   apply( "inverse2", point, inverse2);
//   apply( "inverseXform", point, inverseXform);

   translated = apply( "chain1::xform", point, xform);
   apply( "chain1::inverse2", translated, inverse2);

   translated = apply( "chain2::xform", point, xform);
   apply( "chain2::inverse2", translated, inverseXform);
}


int   main()
{
   CGRect   frame;
   CGRect   bounds;

   frame  = CGRectMake( 0, 8, 2, 2);
   bounds = CGRectMake( -4, 0, 4, 4);

   test( CGPointMake( 0, 0), frame, bounds);
   test( CGPointMake( 1, 1), frame, bounds);

   return( 0);
}

