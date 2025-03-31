//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#import "CAImplicitlyAnimatableObject.h"

#import "import-private.h"

#import "CATransaction.h"

#import "NSObject+CAAnimation.h"


//#define TRACE_COPY_PROPERTY

PROTOCOLCLASS_IMPLEMENTATION( CAImplicitlyAnimatableObject)

//
// This function depends on "clone" being of the exact same class as "self"
// and that "clone" has been zero initialized (not memcpy from "self")
// This allows us to do some shortcuts.
//
static void
   _mulle_objc_infraclass_copy_property_value( struct _mulle_objc_infraclass *infra,
                                               struct _mulle_objc_property *property,
                                               id clone,
                                               id self)
{
   char                      *dst_ivar;
   char                      *src_ivar;
   char                      *signature;
   void                      *value;
   int                       offset;
   mulle_objc_ivarid_t       ivarid;
   struct _mulle_objc_ivar   *ivar;
   uint32_t                  mode;
   unsigned int              size;
   size_t                    n_metaabi_blocks;

   ivarid = _mulle_objc_property_get_ivarid( property);

   // dynamic @property
   if( ! ivarid)  // gotta be dynamic then, which means "just" use getter/setter
   {
      // only problem is figuring out how big the metaABI block needs to
      // be
      signature = _mulle_objc_property_get_signature( property);
      mulle_objc_signature_supply_size_and_alignment( signature, &size, NULL);

      n_metaabi_blocks = mulle_metaabi_voidptr5( size);
      mulle_alloca_do( space, void *, 5 * n_metaabi_blocks)
      {
         // value will be either space or the value, but that's what we push
         // in the setter
#ifdef TRACE_COPY_PROPERTY
         mulle_fprintf( stderr, "%d [%s %s]: @dynamic copy of %td void * (%u bytes)\n",
                                        __LINE__,
                                        infra->base.name,
                                        property->name,
                                        n_metaabi_blocks * 5,
                                        size);
#endif
         value = _mulle_objc_object_call( self, property->getter, space);
         _mulle_objc_object_call( clone, property->setter, value);
      }
      return;
   }

   // ivar backed @property
   ivar   = mulle_objc_infraclass_search_ivar( infra, ivarid);
   offset = _mulle_objc_ivar_get_offset( ivar);

   //
   // copy ivar, that does copy or retain (not atomically)
   //
   mode = property->bits & (_mulle_objc_property_retain|_mulle_objc_property_copy);
   if( mode)
   {
#ifdef TRACE_COPY_PROPERTY
      mulle_fprintf( stderr, "%d %s->%s: ivar based copy/retain of object\n",
                                     __LINE__,
                                     infra->base.name,
                                     property->name);
#endif
      value = mulle_objc_object_get_property_value( self, property->getter, offset, mode);
      mulle_objc_object_set_property_value( clone, property->getter, offset, value, mode);
      return;
   }

   //
   // copy ivar that does not copy or retain an object
   //
   signature = _mulle_objc_ivar_get_signature( ivar);
   mulle_objc_signature_supply_size_and_alignment( signature, &size, NULL);

#ifdef TRACE_COPY_PROPERTY
   mulle_fprintf( stderr, "%d %s->%s: ivar based memcpy of %td bytes\n",
                                  __LINE__,
                                  infra->base.name,
                                  property->name,
                                  size);
#endif
   src_ivar = &((char *) self)[ offset];
   dst_ivar = &((char *) clone)[ offset];

   // must be distinct, so memcpy is fine
   memcpy( dst_ivar, src_ivar, size);
}


struct self_and_clone
{
   id   clone;
   id   self;
};


static mulle_objc_walkcommand_t
   _MulleObjCInstanceCopyObservableProperties( struct _mulle_objc_property *property,
                                               struct _mulle_objc_infraclass *infra,
                                               void *info)
{
   id                        clone;
   id                        self;
   struct self_and_clone     *pair = info;

   if( ! (property->bits & _mulle_objc_property_observable))
      return( mulle_objc_walk_ok);

   clone = pair->clone;
   self  = pair->self;
   assert( clone != self);

   // MEMO: gotta assert somehow that we don't walk properties that have been
   //       overridden already (would copy twice, or if we copy twice that it
   //       is harmless)
   _mulle_objc_infraclass_copy_property_value( infra, property, clone, self);

   return( mulle_objc_walk_ok);
}


//
// This function create a snapshot from "self" of all properties that are
// marked as observable, these can be ivar backed or dynamic. The snapshot
// is an object of the same class, but it will only contain the observable
// properties. It is likely not functional otherwise.
//
id   _CAImplicitlyAnimatableInstanceSnapshot( id self)
{
   id                      clone;
   Class                   infraCls;
   struct self_and_clone   info;

   infraCls = [self class];
   clone    = _MulleObjCClassAllocateInstance( infraCls, 0);

   // ignore -willChange calls for the moment
   [clone setSnapshot:clone];  // -willChange should not snapshot

   info.clone = clone;
   info.self  = self;
   _mulle_objc_infraclass_walk_properties( infraCls,
                                           _mulle_objc_infraclass_get_inheritance( infraCls),
                                           _MulleObjCInstanceCopyObservableProperties,
                                           &info);
   [clone setSnapshot:nil];  // break cycle
   return( [clone autorelease]);
}

//
// CALayer overrides mulleCopyRetainsProperties to return YES, so properties
// are properly retained/copied during -mutableCopy!
//

/*
 * Snapshot management
 */
- (id) observablePropertiesSnapshot
{
   NSObject <CAImplicitlyAnimatableObject>   *snapshot;

   // compiler would warn, because it can't figure out that we inherit this
   // from NSMutableCopying. So we declare a category on top

   snapshot = _CAImplicitlyAnimatableInstanceSnapshot( self);
   return( snapshot);
}


//
// This is called very often during animation, it would be good if the
// animation code could use a different setter that does not call
// will change..
//
- (void) willChange
{
   id   manager;
   id   snapshot;

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
   if( [self snapshot])
      return;

   snapshot = [self observablePropertiesSnapshot];
   [self setSnapshot:snapshot];
   [manager addAnimatableObject:self];
}


- (void) commitImplicitAnimations:(CAAnimationGroup *) group
{
   id   snapshot;

   snapshot = [self snapshot];
   if( ! snapshot)
      return;

   [self setSnapshot:nil];

   //
   // implemented by NSObject+CAAnimation
   //
   [self generateAnimationsForPropertiesWithSnapshot:snapshot
                                      animationGroup:group]; // add to layer
}


- (void) forgetImplicitAnimations
{
   id   manager;
   id   snapshot;

   snapshot = [self snapshot];
   if( ! snapshot)
      return;
   [self setSnapshot:nil];

   // this is called frequently so use C
   manager = CATransactionGetCurrentTransaction();
   [manager removeAnimatableObject:self];   
}

PROTOCOLCLASS_END()
