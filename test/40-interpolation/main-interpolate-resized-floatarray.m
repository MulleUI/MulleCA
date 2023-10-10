#import <MulleCA/MulleCA.h>

#import <stdio.h>



@interface Foo : NSObject

@property( assign) struct mulle__floatarray  r;

@end

@implementation Foo

- (void) setR:(struct mulle__floatarray) r
{
   char    *sep;
   float   v;

   if( mulle__floatarray_get_count( &r) == 0)
   {
      _mulle__floatarray_done( &_r, NULL);
      memset( &_r, 0, sizeof( struct mulle__floatarray));
      return;
   }

   _mulle__floatarray_reset( &_r);
   _mulle__floatarray_add_array( &_r, &r, mulle_range_make_all(), NULL);

   sep = "";
   mulle__floatarray_for( &r, v)
   {
      printf( "%s%.2f", sep, v);
      sep = " ";
   }
   printf( "\n");
}

- (void) dealloc
{
   [self setR:(struct mulle__floatarray) { 0 }];
   [super dealloc];
}

@end



int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *animation;
   NSInteger                        i;
   NSInteger                        j;
   struct mulle__floatarray         start;
   struct mulle__floatarray         end;
   static float                     values_1[] = { -10.0f };
   static float                     values_2[] = { 10.0f, 0.0f, 30.0f, -10.0f };
   struct CABasicAnimationOptions   options;
   static NSUInteger                 bits[ 3] = { 0, CAAnimationStickyArrayCenter, CAAnimationStickyArrayEnd };


   for( j = 0; j < 3; j++)
   {
      switch( bits[ j])
      {
      case 0 :                            printf( "CAAnimationStickyArrayLeft:\n"); break;
      case CAAnimationStickyArrayCenter : printf( "CAAnimationStickyArrayCenter:\n"); break;
      case CAAnimationStickyArrayEnd    : printf( "CAAnimationStickyArrayEnd:\n"); break;
      }
      _mulle__floatarray_init_with_floats( &start, values_1, sizeof( values_1) / sizeof( float), NULL);
      _mulle__floatarray_init_with_floats( &end, values_2, sizeof( values_2) / sizeof( float), NULL);

      foo       = [Foo object];
      options   = CA_BASIC_ANIMATION_OPTIONS_INIT_CURVE( 0, 1, 0.0, 1.0, bits[ j], CAAnimationCurveLinear);
      animation = [[[CABasicAnimation alloc] initWithProperty:MulleObjCInstanceSearchProperty( foo, @selector( r))
                                         startFloatArrayValue:start
                                           endFloatArrayValue:end
                                                      options:&options] autorelease];
      _mulle__floatarray_done( &start, NULL);
      _mulle__floatarray_done( &end, NULL);

      for( i = 0; i <= 5; i++)
      {
         printf( "%ld: ", i);
         [animation animateObject:foo
                     absoluteTime:i / 5.0
                    animationRate:0.0];
      }
   }


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

