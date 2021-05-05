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


@interface CGContext( Render)


// the layers to render. 
// will be rendered front to back, layers must have their transform setup
// already.
// The layers will *NOT* be retained. The layers array will not be copied.
//
- (void) renderLayers:(struct mulle_pointerarray *) layers;

@end
