//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#import "CAImplicitlyAnimatableObject.h"

#import "import-private.h"

#import "CATransaction.h"

#import "NSObject+CAAnimation.h"


@interface NSObject( NSCopyingClassClusterForward)

- (id) copy;

@end


@implementation CAImplicitlyAnimatableObject

- (void) dealloc
{
   [_snapshot release];

   [super dealloc];
}


/*
 * Snapshot management
 */
- (id) copy
{
   CAImplicitlyAnimatableObject   *clone;

   // compiler would warn because it can't figure out that we inherit this
   // from NSCopying. So we declare a category on top
   clone = [super copy];

   clone->_snapshot = nil;

   return( clone);
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
   manager = CATransactionGetCurrentTransaction();
   if( ! manager)
      return;
   if( _snapshot)
      return;

   _snapshot = [self copy];
   [manager addAnimatableObject:self];
}


- (void) commitImplicitAnimations:(CAAnimationGroup *) group
{
   if( ! _snapshot)
      return;

   //
   // implemented by NSObject+CAAnimation
   //
   [self generateAnimationsForPropertiesWithSnapshot:_snapshot
                                      animationGroup:group]; // add to layer

   [_snapshot autorelease];
   _snapshot = nil;
}


- (void) forgetImplicitAnimations
{
   id   manager;

   if( ! _snapshot)
      return;

   // this is called frequently so use C
   manager = CATransactionGetCurrentTransaction();
   [manager removeAnimatableObject:self];   

   [_snapshot autorelease];
   _snapshot = nil;
}

@end
