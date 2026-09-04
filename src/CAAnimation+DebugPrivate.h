//
//  CAAnimation+DebugPrivate.h
//  MulleCA
//
//  Copyright (c) 2023 Nat! - Mulle kybernetiK.
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
// use generic OSWindow for this and SDLOSWindow
enum
{
   CAAnimationDebug            = 0x000001,
   CAAnimationDebugInterpolate = 0x000002,
   CAAnimationDebugState       = 0x000004,
   CAAnimationDebugVerbose     = 0x001000
};



#if ! defined( CA_ANIMATION_LOG_DISABLED)

@interface NSObject( CAAnimationDebug)

- (BOOL) __isCAAnimation      MULLE_OBJC_THREADSAFE_METHOD;

@end


#define CAAnimationLog( format, ...)                                     \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debuggingFlags & CAAnimationDebug)                         \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)

#define CAAnimationLogVerbose( format, ...)                              \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debuggingFlags & CAAnimationDebugVerbose)                  \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)

#define CAAnimationInterpolateLog( format, ...)                          \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debuggingFlags & CAAnimationDebugInterpolate)              \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)


#define CAAnimationReturnStateLog( format, ...)                          \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debuggingFlags & CAAnimationDebugState)                    \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)


#else

#define CAAnimationLog( format, ...)              do {} while( 0)
#define CAAnimationLogVerbose( format, ...)       do {} while( 0)
#define CAAnimationInterpolateLog( format, ...)   do {} while( 0)
#define CAAnimationReturnStateLog( format, ...)   do {} while( 0)

#endif 
