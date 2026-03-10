#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject <CAAnimationDelegate>

@property( assign) CGFloat   f;

@property( assign) NSInteger outputStep;  // just for printing

@end


@implementation Foo

- (void) setF:(CGFloat) f
{
   _f = f;  // don't need to store it for non additive
   printf( "%td: %.1f\n", _outputStep, f);
}


- (void) animationWillStart:(CAAnimation *) animation
{
   printf( "%td: %.1f // will start\n", _outputStep, _f);
}


- (void) animationDidStart:(CAAnimation *) animation;
{
   printf( "%td: %.1f // did start\n", _outputStep, _f);
}


- (void) animationDidStop:(CAAnimation *) animation
                 finished:(BOOL) flag;
{
   printf( "%td: %.1f // did stop %s\n", _outputStep, _f, flag ? "finished" : "unfinished");
}

@end


#define REPEATS  1
#define STEPS    10


int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *animation;
   NSInteger                        i;
   struct CABasicAnimationOptions   options;
   struct _mulle_objc_property      *property;

   foo       = [Foo instance];
   // though this looks a little wordy, its easier to figure out
   // what what is
   options   = (struct CABasicAnimationOptions)
               {
                  .base = (struct CAAnimationOptions)
                          {
                              .timeRange   = mulle_relativetimerange_make( 0, 1),
                              .offset      = 0.0,
                              .repeatCount = REPEATS,
                              .bits        = 0
                          },
                  .curve = CAAnimationCurveLinear,
                  .tween = NULL
               };

   property  = MulleObjCInstanceSearchProperty( foo, @selector( f));
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startFloatValue:-5
                                             endFloatValue:+5
                                                   options:&options] autorelease];
   [animation setDelegate:foo];

   for( i = 0; i <= REPEATS * STEPS + 1; i++)
   {
      [foo setOutputStep:i];
      [animation animateObject:foo
                  absoluteTime:(double) i / STEPS
                 animationRate:0.0];
   }

   fprintf( stderr, "\n\n# Understanding the Output:\n"
"# \n"
"# In the continous, non-quantized, non-discrete, animationRate=0.0 case\n"
"# The interpolation starts at 0.0 for elapsedTime=0 and ends at 10.0 for\n"
"# elapsedTime=10.0\n"
"# \n"
"# 0: 0.0    // will start\n"
"# 0: -5.0\n"
"# 0: -5.0   // did start\n"
"# 1: -4.0   // first animation step (after 1s), the value changes to -4\n"
"# 2: -3.0\n"
"# 3: -2.0\n"
"# 4: -1.0\n"
"# 5: -0.0\n"
"# 6: 1.0\n"
"# 7: 2.0\n"
"# 8: 3.0\n"
"# 9: 4.0\n"
"# 10: 5.0   // duration matches or exceeds 10, last value is set\n"
"# 11: 5.0   // did stop finished\n"
);

   return( 0);
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

