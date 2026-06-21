#import "import-private.h"


//
// Show built-in curves and tween functions.
//
#define N_LAYERS     4 + 30
#define SIZE         CGSizeMake( 8, 8)

static void   setupScene( UIWindow *window)
{
   CGGraphicsLayer    *layers[ N_LAYERS];
   CGRect             frame;
   CGRect             rects[ N_LAYERS];
   CGRect             rect;
   NSUInteger         i;
   CATransaction      *ta;
   CAAnimationGroup   *group;

   frame = [[window contentView] contentRect];
   frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 10, 10, 10, 10));

   ta = [CATransaction instance];

   CGRectPartitionVertically( frame, 0, N_LAYERS, rects);
   for( i = 0; i < N_LAYERS; i++)
   {
      rect = CGSizePlaceInRect( SIZE, rects[ i], CGContentModeLeft);
      layers[ i] = [CGGraphicsLayer layerWithFrame:rect];
      if( i < 4)
         [layers[ i] setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.0, 0.0, 1.0)];
      else
         [layers[ i] setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 1.0, 1.0)];

      [[window contentView] addLayer:layers[ i]];

      [ta begin];
      {
         [ta setAnimationDuration:2];
         [ta setAnimationAutoreverses:YES];
         [ta setAnimationRepeatCount:INFINITY];

         switch( i)
         {
         case  0 : [ta setAnimationCurve:UIViewAnimationCurveEaseInOut]; break;
         case  1 : [ta setAnimationCurve:UIViewAnimationCurveEaseIn]; break;
         case  2 : [ta setAnimationCurve:UIViewAnimationCurveEaseOut]; break;
         case  3 : [ta setAnimationCurve:UIViewAnimationCurveLinear]; break;

         case  4 : [ta setAnimationCurve:CAAnimationCurveEaseInQuadratic]; break;
         case  5 : [ta setAnimationCurve:CAAnimationCurveEaseOutQuadratic]; break;
         case  6 : [ta setAnimationCurve:CAAnimationCurveEaseInOutQuadratic]; break;
         case  7 : [ta setAnimationCurve:CAAnimationCurveEaseInCubic]; break;
         case  8 : [ta setAnimationCurve:CAAnimationCurveEaseOutCubic]; break;
         case  9 : [ta setAnimationCurve:CAAnimationCurveEaseInOutCubic]; break;
         case 10 : [ta setAnimationCurve:CAAnimationCurveEaseInQuartic]; break;
         case 11 : [ta setAnimationCurve:CAAnimationCurveEaseOutQuartic]; break;
         case 12 : [ta setAnimationCurve:CAAnimationCurveEaseInOutQuartic]; break;
         case 13 : [ta setAnimationCurve:CAAnimationCurveEaseInQuintic]; break;
         case 14 : [ta setAnimationCurve:CAAnimationCurveEaseOutQuintic]; break;
         case 15 : [ta setAnimationCurve:CAAnimationCurveEaseInOutQuintic]; break;
         case 16 : [ta setAnimationCurve:CAAnimationCurveEaseInSine]; break;
         case 17 : [ta setAnimationCurve:CAAnimationCurveEaseOutSine]; break;
         case 18 : [ta setAnimationCurve:CAAnimationCurveEaseInOutSine]; break;
         case 19 : [ta setAnimationCurve:CAAnimationCurveEaseInExponential]; break;
         case 20 : [ta setAnimationCurve:CAAnimationCurveEaseOutExponential]; break;
         case 21 : [ta setAnimationCurve:CAAnimationCurveEaseInOutExponential]; break;
         case 22 : [ta setAnimationCurve:CAAnimationCurveEaseInCircular]; break;
         case 23 : [ta setAnimationCurve:CAAnimationCurveEaseOutCircular]; break;
         case 24 : [ta setAnimationCurve:CAAnimationCurveEaseInOutCircular]; break;
         case 25 : [ta setAnimationCurve:CAAnimationCurveEaseInBack]; break;
         case 26 : [ta setAnimationCurve:CAAnimationCurveEaseOutBack]; break;
         case 27 : [ta setAnimationCurve:CAAnimationCurveEaseInOutBack]; break;
         case 28 : [ta setAnimationCurve:CAAnimationCurveEaseInBounce]; break;
         case 29 : [ta setAnimationCurve:CAAnimationCurveEaseOutBounce]; break;
         case 30 : [ta setAnimationCurve:CAAnimationCurveEaseInOutBounce]; break;
         case 31 : [ta setAnimationCurve:CAAnimationCurveEaseInElastic]; break;
         case 32 : [ta setAnimationCurve:CAAnimationCurveEaseOutElastic]; break;
         case 33 : [ta setAnimationCurve:CAAnimationCurveEaseInOutElastic]; break;
         }
         rect = CGSizePlaceInRect( SIZE, rects[ i], CGContentModeRight);
         [layers[ i] setFrame:rect];
      }
      group = [ta commit];

      [[window postLayoutAnimator] addAnimation:group];
      // can now use transaction again
   }
}



int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

      setupScene( window);

      [app addWindow:window];
   }
   return( [app runApp]);
}



//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`
