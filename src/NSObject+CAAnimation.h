//
//  NSObject+CAAnimation.h
//  MulleCA
//
//  Copyright (c) 2022 Nat! - Mulle kybernetiK.
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
#import "import.h"

#import "CABasicAnimation.h"

@class CAAnimationGroup;


struct CAPropertyAnimationContext
{
   id                               self;
   id                               snapshot;
   CAAnimationGroup                 *animationGroup;
   struct CABasicAnimationOptions   animationOptions;
   NSUInteger                       flags;
};

//
// this is a simple extension interface to add more definitions.
// you have to invent a type integer that doesn't conflict with the others
// CAAnimationValueType and other extensions
//
struct CAAnimationPropertyDefinition
{
   BOOL   (*matchRuntimeStructName)( char *, NSUInteger);
   void   (*animateProperty)( struct _mulle_objc_property *,
                              struct CAPropertyAnimationContext *);
};

MULLE_CA_GLOBAL
void  CAAnimationPropertyDefinitionRegister( struct CAAnimationPropertyDefinition *p);

MULLE_CA_GLOBAL
void  CAPropertyAnimationContextAddAnimation( struct CAPropertyAnimationContext *ctx,
                                              CAAnimation *animation);


@interface NSObject( CAAnimation)

- (void) generateAnimationsForPropertiesWithSnapshot:(id) snapshot
                                      animationGroup:(CAAnimationGroup *) group;
@end


@interface NSObject( CAAnimation_Forward)

// implement this on "value" objects class to create a CAAnimation to animate
// from "startObject" to "endObject"
// TODO: is this better in CAInterpolatableValue ?
//
+ (CAAnimation *) animationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) animationOptions;
@end


