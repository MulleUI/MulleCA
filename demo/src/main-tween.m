#import "import-private.h"


//
// These curves are part of the demo only.
//
            // accelerating from zero velocity
static CGFloat   paperjs_ease_in_quad(struct CAQuadratic *quadratic, CGFloat t)
{
    return t * t;
}

            // decelerating to zero velocity
static CGFloat   paperjs_ease_out_quad(struct CAQuadratic *quadratic, CGFloat t)
{
   return t * (2 - t);
}

            // acceleration until halfway, then deceleration
static CGFloat   paperjs_ease_in_out_quad(struct CAQuadratic *quadratic, CGFloat t)
{
   return t < 0.5
              ? 2 * t * t
              : -1 + 2 * (2 - t) * t;
}

            // accelerating from zero velocity
static CGFloat   paperjs_ease_in_cubic(struct CAQuadratic *quadratic, CGFloat t)
{
   return t * t * t;
}

            // decelerating to zero velocity
static CGFloat   paperjs_ease_out_cubic(struct CAQuadratic *quadratic, CGFloat t)
{
   CGFloat  t_1 = t - 1.0;
   return t_1 * t_1 * t_1 + 1;
}

            // acceleration until halfway, then deceleration
static CGFloat   paperjs_ease_in_out_cubic(struct CAQuadratic *quadratic, CGFloat t)
{
    return t < 0.5
        ? 4 * t * t * t
        : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
}

            // accelerating from zero velocity
static CGFloat   paperjs_ease_in_quart(struct CAQuadratic *quadratic, CGFloat t)
{
                return t * t * t * t;
}

            // decelerating to zero velocity
static CGFloat   paperjs_ease_out_quart(struct CAQuadratic *quadratic, CGFloat t)
{
   CGFloat  t_1 = t - 1.0;
   return 1 - t_1 * t_1 * t_1 * t_1;
}

            // acceleration until halfway, then deceleration
static CGFloat   paperjs_ease_in_out_quart(struct CAQuadratic *quadratic, CGFloat t)
{
   CGFloat  t_1 = t - 1.0;
    return t < 0.5
        ? 8 * t * t * t * t
        : 1 - 8 * t_1 * t_1 * t_1 * t_1;
}

            // accelerating from zero velocity
static CGFloat   paperjs_ease_in_quint(struct CAQuadratic *quadratic, CGFloat t)
{
   return t * t * t * t * t;
}

            // decelerating to zero velocity
static CGFloat   paperjs_ease_out_quint(struct CAQuadratic *quadratic, CGFloat t)
{
   CGFloat  t_1 = t - 1.0;

   return 1 + t_1 * t_1 * t_1 * t_1 * t_1;
}

            // acceleration until halfway, then deceleration
static CGFloat   paperjs_ease_in_out_quint(struct CAQuadratic *quadratic, CGFloat t)
{
   CGFloat  t_1 = t - 1.0;

   return t < 0.5
            ? 16 * t * t * t * t * t
            : 1 + 16 * t_1 * t_1 * t_1 * t_1 * t_1;
}




#define N_LAYERS     4 + 12
#define SIZE         CGSizeMake( 10, 10)

static void   setupScene( UIWindow *window)
{
   CALayer            *layers[ N_LAYERS];
   CGRect             frame;
   CGRect             rects[ N_LAYERS];
   CGRect             rect;
   NSUInteger         i;
   CATransaction      *ta;
   CAAnimationGroup   *group;

   frame = [[window contentView] contentRect];
   frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 10, 10, 10, 10));

   ta = [CATransaction object];

   CGRectPartitionVertically( frame, 0, N_LAYERS, rects);
   for( i = 0; i < N_LAYERS; i++)
   {
      rect = CGSizePlaceInRect( SIZE, rects[ i], CGContentModeLeft);
      layers[ i] = [CALayer layerWithFrame:rect];
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

         case  4 : [ta setAnimationTweenFunction:paperjs_ease_in_quad]; break;
         case  5 : [ta setAnimationTweenFunction:paperjs_ease_out_quad]; break;
         case  6 : [ta setAnimationTweenFunction:paperjs_ease_in_out_quad]; break;
         case  7 : [ta setAnimationTweenFunction:paperjs_ease_in_cubic]; break;
         case  8 : [ta setAnimationTweenFunction:paperjs_ease_out_cubic]; break;
         case  9 : [ta setAnimationTweenFunction:paperjs_ease_in_out_cubic]; break;
         case 10 : [ta setAnimationTweenFunction:paperjs_ease_in_quart]; break;
         case 11 : [ta setAnimationTweenFunction:paperjs_ease_out_quart]; break;
         case 12 : [ta setAnimationTweenFunction:paperjs_ease_in_out_quart]; break;
         case 13 : [ta setAnimationTweenFunction:paperjs_ease_in_quint]; break;
         case 14 : [ta setAnimationTweenFunction:paperjs_ease_out_quint]; break;
         case 15 : [ta setAnimationTweenFunction:paperjs_ease_in_out_quint]; break;
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
   return( [app run]);
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

