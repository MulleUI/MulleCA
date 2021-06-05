#include <MulleCA/_MulleCA-include.h>
#include <MulleCA/_MulleCA-provide.h>

#include <stdio.h>


int   main( int argc, char *argv[])
{
   CGFloat   deg;
   CGFloat   dir;
   CGFloat   degdir;

   printf( ":: %f\n", fmodf( 1.0f, 1.0f));
   for( dir = -1.0f; dir <= 1.01f; dir += 0.1f)
   {
      deg    = CAAngleDirectionalToDegrees( dir);
      degdir = CAAngleDegreesToDirectional( deg);

      printf( "dir: %.3f deg: %.3f (%.3f)\n",
                     dir, deg, degdir);
   }
   return( 0);
}
