//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "CGContext+Render.h"

#import "import-private.h"

#import "CALayer.h"


@implementation CGContext ( Render)

- (void) renderObjects:(struct mulle_pointerarray *) objects
{
   struct mulle_pointerarrayenumerator   rover;
   id <CGRenderObject>                   *obj;

   rover = mulle_pointerarray_enumerate( objects);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &obj))
   {
      [obj renderInContext:self];
   }
   mulle_pointerarrayenumerator_done( &rover);
}

@end
