//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local CGContext over one in import.h
#ifdef __has_include
# if __has_include( "CGContext.h")
#  import "CGContext.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@protocol CGRenderObject

- (void) renderInContext:(CGContext *) context;

@end


@interface CGContext( Render)

//
// The CGRenderObjects to render.
// They will be rendered front (0) to back (n).
// The objects will *NOT* be retained. The objects array will not be copied or
// kept.
//
- (void) renderObjects:(struct mulle_pointerarray *) layers;

@end
