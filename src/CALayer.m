#import "import-private.h"

#import "CALayer.h"
#import "CALayer+DebugPrivate.h"


#pragma clang diagnostic ignored "-Wparentheses"
// #define RENDER_DEBUG
// #define CALAYER_DEBUG

@implementation NSObject ( CALayer)

- (BOOL) __isCALayer
{
   return( NO);
}

@end


@implementation CALayer

- (BOOL) __isCALayer
{
   return( YES);
}


static struct
{
   NSUInteger   _debuggingFlags;
} Self;


+ (void) initialize
{
   char   *s;

   // don't rerun for subclass
   if( MulleObjCClassGetID( self) != @selector( CALayer))
      return;

   // __CLASSNAME__ unfortunately does not exist
   s = getenv( MULLE_C_STRINGIFY( CALayer) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      Self._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) deinitialize
{
}


+ (void) setDebuggingFlags:(NSUInteger) flag  MULLE_OBJC_THREADSAFE_METHOD
{
   Self._debuggingFlags = flag;
}



CAAnimationStorageObjectImplementation;

+ (instancetype) layerWithFrame:(CGRect) frame
{
   CALayer   *layer;

   layer = [self alloc];
   layer = [layer initWithFrame:frame];
   layer = [layer autorelease];
   return( layer);
}


//
// this method is shared by the designated intializer and copy so be extra
// careful here. Also ensure that the logic is somewhat similar to UIView
//
- (id) _initWithFrame:(CGRect) frame
{
   self = [self initNoLock];
   if( ! self)
      return( self);

   _frame               = frame;
   CALayerLog( "frame %s", CGRectUTF8String( _frame));

   _bounds.size.width   = INFINITY;
   _canvas.size.width   = INFINITY;
   _clipRect.size.width = INFINITY; // means no clipRect

   // by default only track bounds
   _frameTracking       = CALayerBoundsSizeTracksFrameSize;
   _opacity             = 1.0; // not just background!
   _alpha               = 1.0;
   _transform           = CGAffineTransformMakeIdentity();
   _masksToBounds       = YES;
//   _anchorPoint         = CGPointMake( 0.5, 0.5); // Default to center

#ifdef CALAYER_DEBUGGING_FLAGS
   _debuggingFlags      = CALAYER_DEBUGGING_FLAGS;
#else
   _debuggingFlags      = Self._debuggingFlags;
#endif

    //_pixelCenter     = CGPointMake( 0.5, 0.5);
   return( self);
}


- (instancetype) init
{
   return( [self initWithFrame:CGRectZero]);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   return( [self _initWithFrame:frame]);
}


- (void) finalize
{
   [self removeAllAnimations];
   [super finalize];
}


- (void) dealloc
{
   char  *s;

   s = _mulle_atomic_pointer_read( &_atomicNameUTF8String);
   mulle_allocator_free( MulleObjCInstanceGetAllocator( self), s);
   [super dealloc];
}


- (void) mulleGainAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   [super mulleGainAccessWithUniquingSet:uniquing];

   [self mulleGainAccessToAnimationsWithUniquingSet:uniquing];
}


- (void) mulleRelinquishAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   [self  mulleRelinquishAccessToAnimationsWithUniquingSet:uniquing];
   [super mulleRelinquishAccessWithUniquingSet:uniquing];
}


//
// CALayer copy idea is that we use _initWithFrame: to get a default
// initialized object, this object should not have set paints or other
// retainable/copyiable properties (else we would need to release them
// again in -copy to copy over info)
// Default paints and so forth, should be set in initWithFrame: which then
// calls _initWithFrame:
//
- (id) copy
{
   CALayer   *copy;
   Class     cls;

   cls = [self class];

   // check that the subclass is actually implementing -copy, otherwise the
   // user is probably in a world of pain soon afterwards
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⠚⠋⢙⠉⠛⢶⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⢴⣿⣷⣶⣤⣰⠆⠀⠀⢀⡰⢟⣩⣵⣷⣶⣶⣿⣿⣾⡀⢄⠐⠀⠐⠀⠂⠀⠆⠀⠆⠐⢀⣰⣠⣴⣿⣿⣶
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠿⠿⠻⠀⠂⠀⠂⢻⣯⣿⣿⣿⣿⣿⣿⣿⣿⣷⣌⢮⡀⢆⠀⡂⢐⠀⡆⠠⠣⠌⢻⠛⠟⠩⠉⠍
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠹⣿⣿⠿⠋⠉⠉⢲⡆⠀⡂⠤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀
   // ⣆⠀⣀⢠⡄⠤⢴⣴⣶⣶⣶⣶⣾⣿⣷⡄⠀⠀⢀⠀⠀⢠⣤⣤⣰⣶⣾⣿⣷⠆⠀⢀⠾⠿⠆⣧⣼⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⠆⠀⠀⠀⠀
   // ⡃⠀⠈⢸⢐⢚⣺⣿⠿⣿⣿⣿⣿⣿⣿⠁⠀⠐⠻⣿⣦⣾⣿⣿⣿⣧⣿⣿⣿⣿⣾⡔⣀⠀⣠⣿⣟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀
   // ⡁⠀⠐⠘⢈⣈⣆⣹⣃⣻⣿⣿⣿⣿⣷⣀⠀⠀⠀⣈⡉⠙⢿⣿⣿⠈⣿⣿⣿⣿⣿⢨⣾⣏⢙⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀
   // ⠀⠀⠀⠀⢀⢀⡀⢀⠶⢂⠟⣿⣿⣿⣿⣿⣷⣶⣿⣿⣿⣷⡄⠀⠟⠀⢸⣆⠀⠁⠀⠈⠉⠉⠀⠉⠀⠀⠀⠤⠤⠤⠶⠶⠴⠶⠶⠶⠷⠶⠿⠷⠶
   // ⠂⠀⠀⠠⠶⣸⣘⣩⣉⣈⣉⣿⣿⣿⣿⣟⠉⠉⠙⠿⠿⢟⣵⣆⣠⡔⠀⠙⠷⡆⠀⠀⠀⠀⢀⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢿⣦⡀⠀⠀⠐⣤⣔⡀⢶⣾⣿⡄⠀⠢⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⣁⣠⣤⣭⣷⣿⣷⡄⠹⣷⣤⡀⠀⠈⠻⣿⣿⣿⣿⣿⡆⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿
   // ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠛⠛⣛⣹⣿⣿⡧⠀⣿⣿⣿⣿⣦⠀⠙⢿⣿⣿⣿⡷⠀⠀⠀⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
   // ⣿⣿⣿⣿⡿⠋⠠⠤⠀⠈⠋⠁⡀⠈⠹⢿⣦⣤⠀⠀⠻⢿⣿⣿⡇⠀⣻⣿⣿⣿⣿⣷⡄⠀⠈⠻⣿⡇⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
   // ⣿⣿⡟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠻⣿⡄⠀⠀⠀⠻⣿⠇⠀⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠘⠁⠀⠀⠀⠀⠀⠙⣿⣷⣶⡞⢉⣴⡾⡟⠫
   // ⡞⣷⠇⡟⣷⣿⢸⢸⢸⣻⢾⣟⢤⢸⡃⣿⣼⠘⡟⢸⣟⢸⣻⢸⡇⣷⣿⣼⣻⢹⢿⢿⢹⢹⣼⣧⡇⣿⣷⢸⣻⢸⡇⢸⢻⣎⢱⣿⡆⣟⡛⠛⠃
   // ⣿⠿⢀⠧⠟⠻⠼⢸⡸⠸⠿⠧⢸⠸⠤⠿⠿⠀⠇⠸⠧⠸⠸⠸⠇⠏⠿⠻⠽⢸⠸⠻⢾⡼⣟⡿⠇⠿⠿⠸⠸⠺⠧⠸⠼⣿⣼⠿⡇⠇⠀⠀⠀
   // ⠀⠀⢈⠀⠀⠀⠀⠉⠉⠈⠉⠉⠘⢛⠿⠸⠿⠇⠀⠀⠀⢀⣀⡀⣀⡀⣀⢐⢛⢻⣿⣿⣵⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿
   // ⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠴⠦⠀⠀⣴⣶⣾⡀⠀⠀⢸⡷⢇⣏⡇⣿⢸⣿⢸⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⣽⣿⢹⣿⣿⣿
   // ⡀⠀⢸⢀⣀⣀⡀⠤⢤⡄⠀⠀⠀⠀⠐⡿⠿⣿⣷⣤⣤⠘⡃⠘⠃⠓⠛⠘⣸⣼⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⡇⣇⣈⣈⣉⣉⣹
   assert( MulleObjCClassImplementsSelector( cls, @selector( copy)) &&
           "your subclass must implement -copy and then start by "
           "calling [super copy] then add additional copy code");

   copy = [cls alloc];
   copy = [copy _initWithFrame:self->_frame];
   if( ! copy)
      return( copy);

   // copy animations
   CAAnimationStorageObjectCopy( copy, self);

   // copy these without the property accessors, which do too much
   copy->_frame         = self->_frame;
   copy->_bounds        = self->_bounds;
   copy->_canvas        = self->_canvas;
   copy->_opacity       = self->_opacity;
   copy->_masksToBounds = self->_masksToBounds;

   copy->_transform     = self->_transform;
   copy->_clipRect      = self->_clipRect;
   copy->_alpha         = self->_alpha;
   copy->_hidden        = self->_hidden;

   return( copy);
}


//
//- (struct CAAnimationStorage *) animationStorage
//{
//   return( &_animationStorage);
//}


+ (instancetype) layer
{
   return( [self instance]);
}


static inline CGRect   getBounds( CALayer *self)
{
   CGRect  bounds;

   bounds.origin = self->_bounds.origin;
   bounds.size   = self->_bounds.size.width == INFINITY
                   ? self->_frame.size
                   : self->_bounds.size;
   return( bounds);
}


#pragma clang diagnostic ignored "-Wunused-property-ivar"

- (CGRect) bounds
{
   return( getBounds( self));
}


- (void) setBounds:(CGRect) bounds
{
   [self willChange];    // seems needed

   _bounds.origin = bounds.origin;
   if( (_frameTracking & CALayerBoundsSizeTracksFrameSize) &&
         CGSizeEqualToSize( _frame.size, bounds.size))
      _bounds.size.width = INFINITY;
   else
      _bounds.size = bounds.size;
}


static inline CGRect   getCanvas( CALayer *self)
{
   CGRect  canvas;

   canvas.origin = self->_canvas.origin;
   canvas.size   = self->_canvas.size.width == INFINITY
                   ? self->_frame.size
                   : self->_canvas.size;
   return( canvas);
}


- (CGRect) canvas
{
   return( getCanvas( self));
}


- (void) setCanvas:(CGRect) canvas
{
   [self willChange]; // seems needed

   // some times you use negative origins for the canvas to draw in a more
   // "mathy" way with a circle center at 0,0
   //NSParameterAssert( CGPointEqualToPoint( canvas.origin, CGPointZero));

   _canvas.origin = canvas.origin;
   if( (_frameTracking & CALayerCanvasSizeTracksFrameSize) &&
         CGSizeEqualToSize( _frame.size, canvas.size))
      _canvas.size.width = INFINITY;
   else
      _canvas.size = canvas.size;
}


- (void) layoutWithLayoutInfo:(struct UILayoutInfo *) info
{
   // the default does nothing
   assert( info);
}


- (char *) nameUTF8String
{
   char  *s;

   s = _mulle_atomic_pointer_read( &_atomicNameUTF8String);
   return( s);
}


- (void) setNameUTF8String:(char *) s
{
   struct mulle_allocator       *allocator;
   struct _mulle_objc_universe  *universe;
   void                         *actual;
   void                         *old;

   // need universe allocator for abafree
   universe  = _mulle_objc_object_get_universe( self);
   allocator = _mulle_objc_universe_get_allocator( universe);
   old       = _mulle_atomic_pointer_read( &_atomicNameUTF8String);
   if( s)
      s = mulle_allocator_strdup( allocator, s);

   actual = __mulle_atomic_pointer_cas( &_atomicNameUTF8String, s, old);

   if( actual == old)
      mulle_allocator_abafree( allocator, old);
   else
      mulle_allocator_free( allocator, s);
}


- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   NSUInteger   i;

   for( i = 0; i < indent; i++)
      fputc( ' ', fp);

   fprintf( fp, "%s: frame=[%s] bounds=[%s] clip=[%s]",
               [self UTF8String],
               CGRectUTF8String( [self frame]),
               CGRectUTF8String( [self bounds]),
               CGRectUTF8String( [self clipRect]));
   if( [self masksToBounds])
      fprintf ( fp, " masks");

   fprintf( fp, "\n");
}




//
// This is called very often during animation, it would be good if the
// animation code could use a different setter that does not call
// will change..
//
- (void) willChange
{
   id   manager;

   // -willChange is is called frequently, so use C as much as possible.
   //
   // Generally keep this snappy, as it can bottleneck. We especially don't
   // want this in a classcluster to have to ask [self snapshotPointer] or
   // somesuch
   //
   manager = CATransactionGetCurrentTransaction();
   if( ! manager)
      return;

   // most of the time _snapshot will be NULL, so check after manager
   // which is usually NULL
   if( _snapshot)
      return;

   _snapshot = [[self observablePropertiesSnapshot] retain];
   assert( _snapshot);

   [manager addAnimatableObject:self];
}

@end

