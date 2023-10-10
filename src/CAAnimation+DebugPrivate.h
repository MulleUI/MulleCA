// use generic OSWindow for this and SDLOSWindow
enum
{
   CAAnimationDebug            = 0x000001,
   CAAnimationDebugVerbose     = 0x001000,
   CAAnimationDebugInterpolate = 0x000002
};



#if ! defined( CA_ANIMATION_DEBUG_DISABLED)

@interface NSObject( CAAnimationDebug)

- (BOOL) __isCAAnimation;

@end


#define CAAnimationLog( format, ...)                                     \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debugEnabled & CAAnimationDebug)                           \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)

#define CAAnimationLogVerbose( format, ...)                              \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debugEnabled & CAAnimationDebugVerbose)                    \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)

#define CAAnimationInterpolateLog( format, ...)                          \
do                                                                       \
{                                                                        \
   assert( [self __isCAAnimation]);                                      \
   if( self->_debugEnabled & CAAnimationDebugInterpolate)                \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                       (char *) format, ## __VA_ARGS__); \
}                                                                        \
while( 0)


#else

#define CAAnimationLog( format, ...)                  do {} while( 0)
#define CAAnimationLogVerbose( format, ...)           do {} while( 0)
#define CAAnimationInterpolateLog( format, ...)       do {} while( 0)

#endif 
