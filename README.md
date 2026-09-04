# MulleCA

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### 🫧 Animate properties in real time with mulle-objc

MulleCA is used to stuff values into properties over a desired timespan.

You animate a property by setting up a `CABasicAnimation` for it and adding it
to a `CAAnimator`, which you then step with a clock each frame. The [example
below](#example) shows a complete animation of an `NSInteger` property named
`someIntegerValue`.



| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleCA.svg) [![Build Status](https://github.com/MulleUI/MulleCA/workflows/CI/badge.svg)](//github.com/MulleUI/MulleCA/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleCA](https://deepwiki.com/MulleUI/MulleCA)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-ca)
* [Debugger Guide](asset/howto/debugger/mulle-ca)
* [Verifier Guide](asset/howto/verifier/mulle-ca)

## Example

This animates an `NSInteger` property `someIntegerValue` from 0 to 1000 over
one second:

``` objc
#import <MulleCA/MulleCA.h>


@interface Foo : NSObject

@property NSInteger   someIntegerValue;

@end


@implementation Foo

- (void) setSomeIntegerValue:(NSInteger) value
{
   printf( "%td\n", value);
   _someIntegerValue = value;
}

@end


int   main( void)
{
   CAAnimator                       *animator;
   CABasicAnimation                 *animation;
   Foo                              *foo;
   double                           timestamp;
   struct _mulle_objc_property      *property;

   // create object, get property, create an animation for this property

   foo      = [Foo object];
   property = MulleObjCInstanceSearchProperty( foo, @selector( someIntegerValue));

   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:1000
                                                   options:NULL] autorelease];
   [animation setAnimationObject:foo];

   /*
    * animator now runs animation with our fake timestamps
    */
   animator = [CAAnimator object];
   [animator addAnimation:animation];

   for( timestamp = 0.0; timestamp <= 1.2; timestamp += 0.2)
      [animator animateWithAbsoluteTime:timestamp
                          animationRate:1.0 / 60.0];
   return( 0);
}
```

In a real display loop you call `animateWithAbsoluteTime:animationRate:`
before drawing, passing the current time and the expected frame rate
(`1.0/60.0` for 60Hz). The `animationRate` is used for quantizing the
animation, which ensures an accurate final value is stored in the property;
passing `0.0` keeps the values continuous.

## Build the demo

The `demo/` folder is a [mulle-sde](//github.com/mulle-sde) project:

``` sh
cd demo
mulle-sde craft
```


### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleCA to your project:

``` sh
mulle-sde add github:MulleUI/MulleCA
```

To only add the sources of MulleCA with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleCA
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleCA and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleCA/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleUIBase](https://github.com/MulleUI/MulleUIBase)             | 💺 MulleUIBase adds Objective-C to mulle-geometry and friends
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleCA/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleCA/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleCA** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



