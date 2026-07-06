# MulleCA

#### 🍃 Animate properties in real time with mulle-objc


# 🍃 MulleCA

#### 🍃 Animate properties in real time with mulle-objc

MulleCA is used to stuff values into properties over a desired timespan.


If you want a `NSInteger` property named "someIntegerValue"
on your object `foo` to change value from 0 to 1000 over the next second, you
set up a `CABasicAnimation`:

``` objc
   // get property "someIntegerValue" from 'foo'
   property = MulleObjCInstanceSearchProperty( foo, @selector( someIntegerValue));
   // options: NULL yields convenient  default values `delay=0; duration=1;`)
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:1000
                                                   options:NULL] autorelease];
   [animation setAnimationObject:foo];
```

and run it with an animator:

``` objc
   animator = [CAAnimator object];
   [animator addAnimation:animation];
   hz       = 60.0;

   while( [animator animateWithAbsoluteTime:time( NULL)
                              animationRate:1.0 / hz])
   {
       struct timespec   delay = { 0, (1000 * 1000 * 1000) / hz };
       nanosleep( &delay, NULL);
   }
   return( 0);
```




| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleCA.svg) [![Build Status](https://github.com/MulleUI/MulleCA/workflows/CI/badge.svg)](//github.com/MulleUI/MulleCA/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleCA](https://deepwiki.com/MulleUI/MulleCA)






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



