#define _GNU_SOURCE

#import "import-private.h"

#import "CGContext.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "UIColor.h"
#import "CALayer.h"
#import "UIEdgeInsets.h"
#import "MulleLayout.h"
#include <string.h>


/*
 * Das eine was beim resize auffällt. Die Grafik ist unten
 * verankert und nicht oben. Daher komme das schwimmen. Bzw. beim resizen
 * wird dann kurz der alte framebuffer unverändert tieferliegend angezeigt.
 * OK das war aber noch als die Window FIFO nur 4 Einträget hatte.
 *
 * Jetzt mit ADD_RANDOM_LAG_AFTER_SWAP und LAG_FRAMES 20, ist die Grafik
 * oben verankert und man sieht wie unten was fehlt beim resize.
 *
 * Versteh ich das ? Nein.
 *
 * Tags darauf:
 *
 * Also gedanklich mal von von. Das Fenster zeigt vermutlich igendwelchen
 * Grafikspeicher relativ direkt an. Beim Resize braucht man mehr Speicher
 * und bei einem realloc kriegen wir u.U. völlig neuen, der normalerweise
 * leer ist oder Müll drin hat. Der muss dann innerhalb eines Frames ?
 * befüllt werden sonst flackert es.
 *
 * Was passiert denn beim page flipping eigentlich. Idealerweise ja ein
 * umsetzen der grafikadresse, schlimmstenfalls ein memcpy.
 *
 * Man könnte erstmal in einen FBO malen und den jedesmal blitten, wenn sich
 * das Fenster neuzeichnen soll. Dazu malt man im Hintergrund gelegentlich mal
 * ein neues FBO (so vielleich im 10Hz Rythmis). Das FBO wird dann auf den
 * gelöschten Hintergrund geblittet.
 *
 * Problem! Dazu brauchen wir einen zweiten Thread. Problem! es gibt sichbaren
 * lag im layouting. Also ein mix aus einem statischen Bild was ev. skaliert
 * und dem "live resize". Was es vereinfacht, unser Layout wird nur weiterhin
 * von einem Thread bespielt. Problem! manchmal ist skalieren falsch,
 * eigentlich immer. Weisser Rand oder abgeschnitten sieht aber auch nicht
 * toll aus. (Firefox macht allerdings weisser Rand, wenn man kompliziertes
 * JS laufen lässt)
 *
 * Alternative. Programmatisch Fenster auf der Grösse halten, die man gerade
 * darstellen kann.
 */
//#define ADD_LAG_BEFORE_SWAP
#define ADD_LAG_AFTER_SWAP

#define LAG_FRAMES    40.0


static void   lag( long refreshRate)
{
   struct timespec   sleep;
   long              nsperframe;

   nsperframe    = (1000000000L + (refreshRate - 1)) / refreshRate;
   sleep.tv_sec  = 0.0;
   sleep.tv_nsec = (long) round( nsperframe * LAG_FRAMES);
   nanosleep( &sleep, NULL);
}


static void   didRenderCallback( UIWindow *window,
                                 struct MulleFrameInfo *info,
                                 CAAbsoluteTime renderTime)
{
   NVGcontext   *vg;
   CGRect       rect;
   NSUInteger   depth;

   vg = MulleContextGetNVGContext( [window context]);

   rect.origin = CGPointZero;
   rect.size   = info->size;

   depth = 1;
   for(;;)
   {
      rect = CGRectInset( rect, 10, 10);
      if( rect.size.width < 1.0 || rect.size.height < 1.0)
         break;

      nvgBeginPath( vg);
      nvgRect( vg, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
      nvgFillColor( vg, (depth & 1) ? CGColorCreateGenericRGB( 0.5, 0.0, 0.5, 1.0)
                                    : CGColorCreateGenericRGB( 0.0, 0.5, 0.0, 1.0));
      nvgFill( vg);
      ++depth;
   }

#ifdef ADD_LAG_BEFORE_SWAP
   lag( info->refreshRate);
#endif
}


static void   didSwapCallback( UIWindow *window,
                               struct MulleFrameInfo *info)
{
#ifdef ADD_LAG_AFTER_SWAP
   lag( info->refreshRate);
#endif
}


//
// this is a super barebones test file, for windows resize and redraw
// checks without flickering.
//
int   main()
{
   CGContext   *context;
   UIWindow    *window;

   window  = [[[UIWindow alloc] initWithFrame:CGRectMake( 0.0, 0.0, 800, 600)] autorelease];
   [[UIApplication sharedInstance] addWindow:window];

   [window setDidRenderCallback:didRenderCallback];
   [window setDidSwapCallback:didSwapCallback];
   context = [window context];
   [context setBackgroundColor:CGColorCreateGenericRGB( 0.0, 0.5, 0.0, 1.0)];

   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
}

