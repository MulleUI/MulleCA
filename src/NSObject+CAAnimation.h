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

MULLE_CA_EXTERN_GLOBAL
void  CAAnimationPropertyDefinitionRegister( struct CAAnimationPropertyDefinition *p);

MULLE_CA_EXTERN_GLOBAL
void  CAPropertyAnimationContextAddAnimation( struct CAPropertyAnimationContext *ctx,
                                              CAAnimation *animation);
@interface NSObject( CAAnimation)

- (void) generateAnimationsForPropertiesWithSnapshot:(id) snapshot
                        animationGroup:(CAAnimationGroup *) group;

@end

