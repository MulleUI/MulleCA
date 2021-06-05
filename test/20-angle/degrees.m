#include <MulleCA/_MulleCA-include.h>
#include <MulleCA/_MulleCA-provide.h>

#include <stdio.h>


int   main( int argc, char *argv[])
{
   int       angle;
   CGFloat   deg;
   CGFloat   hour;
   CGFloat   dir;
   CGFloat   rad;
   CGFloat   degdir;
   CGFloat   radhour;

   for( angle = -720; angle <= 720; angle += 45)
   {
      deg  = (CGFloat) angle;
      rad  = CAAngleDegreesToRadians( deg);
      hour = CAAngleRadiansToHour( rad);
      dir  = CAAngleDegreesToDirectional( deg);

      degdir= CAAngleDirectionalToDegrees( dir);
      radhour= CAAngleHourToRadians( hour);

      printf( "a: %d d: %3.f r:%.3f h: %.3f (%.3f) d: %.3f (%.3f)\n", angle,
                     deg, rad, hour, radhour, dir, degdir);
   }
   return( 0);
}