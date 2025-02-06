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
   if( self->_debuggingFlags & CALayerDebugVerbose)                         \
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


