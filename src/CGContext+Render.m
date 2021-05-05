//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CGContext+Render.h"

#import "import-private.h"

#import "CALayer.h"


@implementation CGContext ( Render)

- (void) renderLayers:(struct mulle_pointerarray *) layers
{
   struct mulle_pointerarrayenumerator   rover;
   CALayer                               *layer;

   rover = mulle_pointerarray_enumerate( layers);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
   {
      [layer renderInContext:self];
   }
   mulle_pointerarrayenumerator_done( &rover);
}

@end
