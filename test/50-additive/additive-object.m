#import <MulleCA/MulleCA.h>

#import <stdio.h>

@interface Float : NSObject <CAInterpolatableValue>

@property( assign) float   value;

@end


@implementation Float

+ (instancetype) objectWithFloat:(float) v
{
   Float   *p;

   p = [self object];
   p->_value = v;
   return( p);
}


// standard interpolation self is start: start + (end - start) * x;
- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive
{
   float   value;

   assert( [end isKindOfClass:[Float class]]);
   if( additive)
      value = CAInterpolateAdditive( self->_value, ((Float *) end)->_value, x);
   else
      value = CAInterpolate( self->_value, ((Float *) end)->_value, x);
   return( [MulleObjCObjectGetClass( self) objectWithFloat:value]);
}


// self - previous + diff
- (id) interpolatedValueWithDiff:(id) diff
                    previousDiff:(id) previous
{
   float   value;

   assert( [diff isKindOfClass:[Float class]]);
   assert( ! previous [previous isKindOfClass:[Float class]]);

   value = self->_value - (previous ? ((Float *) previous)->_value : nil) + ((Float *) diff)->_value;
   return( [MulleObjCObjectGetClass( self) objectWithFloat:value]);
}

@end



@interface Foo : NSObject

@property( copy) Float  *f;

@end


@implementation Foo

- (void) setF:(Float *) f
{
   [_f autorelease];
   _f = [f copy];  // don't need to store it for non additive
   printf( "%.3f\n", [f value]);
}

@end




int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *animation;
   NSInteger                        i;
   Float                            *start;
   Float                            *end;
   struct CABasicAnimationOptions   options;

   foo = [Foo object];
   [foo setF:[Float objectWithFloat:-10.0f]];

   options   = CABasicAnimationOptionsMakeCurve( mulle_relativetimerange_make( 0, 1),
                                                 2.0,
                                                 CAAnimationAdditive,
                                                 CAAnimationCurveLinear);
   fprintf( stderr, "%s\n", CABasicAnimationOptionsUTF8String( &options));

   start     = [Float objectWithFloat:-10.0f];
   end       = [Float objectWithFloat:+10.0f];
   animation = [[[CABasicAnimation alloc] initWithProperty:MulleObjCInstanceSearchProperty( foo, @selector( f))
                                          startObjectValue:start
                                            endObjectValue:end
                                                   options:&options] autorelease];

   for( i = 0; i <= 10; i++)
   {
      printf( "%ld: ", i);
      [animation animateObject:foo
                  absoluteTime:i / 5.0
                  animationRate:0.0];
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

