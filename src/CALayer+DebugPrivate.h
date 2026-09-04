//
//  CALayer+DebugPrivate.h
//  MulleCA
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
enum
{
   CALayerDebug            = 0x00000001,
   CALayerDebugDisplayBits = 0x00000040,  // compatible with UIView
   CALayerDebugVerbose     = 0x00001000
};


@interface NSObject ( CALayer)

- (BOOL) __isCALayer    MULLE_OBJC_THREADSAFE_METHOD;

@end



#if ! defined( CA_LAYER_LOG_DISABLED)

#define CALayerLog( format, ...)                                            \
do                                                                          \
{                                                                           \
   assert( [self __isCALayer]);                                             \
   if( self->_debuggingFlags & CALayerDebug)                                \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define CALayerLogVerbose( format, ...)                                     \
do                                                                          \
{                                                                           \
   assert( [self __isCALayer]);                                             \
   if( self->_debuggingFlags & CALayerDebugVerbose)                         \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define CALayerDisplayBitsLog( format, ...)                                 \
do                                                                          \
{                                                                           \
   assert( [self __isCALayer]);                                             \
   if( self->_debuggingFlags & CALayerDebugDisplayBits)                     \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#else

#define CALayerLog( format, ...)               do {} while( 0)
#define CALayerLogVerbose( format, ...)        do {} while( 0)
#define CALayerDisplayBitsLog( format, ...)    do {} while( 0)

#endif


