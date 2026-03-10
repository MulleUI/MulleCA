#import <MulleCA/MulleCA.h>

// this is just a fake CAInterpolatableValue, i doesn't interpolate
// its not a value
@interface Foo : NSObject <CAImplicitlyAnimatableObject, CAInterpolatableValue>
{
   CAImplicitlyAnimatableObjectIvars;
   CAAnimationStorageObjectIvars;
}
CAAnimationStorageObjectProperties;

@property( observable, retain) id    value;

CAImplicitlyAnimatableObjectInterface;
CAAnimationStorageObjectInterface;

@end


@implementation Foo

CAImplicitlyAnimatableObjectImplementation;
CAAnimationStorageObjectImplementation;


- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive
{
   return( self);
}            

// additive interpolation (2): self - previous + diff
- (id) interpolatedValueWithDiff:(id) diff
                    previousDiff:(id) previous;  // previous will be nil the first call!
{
   return( self);
}            


- (id) copy
{
   return( [self retain]);
}

@end 



int   main( int argc, char *argv[])
{
   CABasicAnimation                        *animation;
   static struct CABasicAnimationOptions   empty;
   id                                      foo;
   id                                      bar;
   struct _mulle_objc_property             *property;

   // Foo is value and property container (hacky)
   foo       = [Foo instance];
   bar       = [Foo instance];
   property  = MulleObjCInstanceSearchProperty( foo, @selector( value));
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                          startObjectValue:foo 
                                            endObjectValue:bar 
                                                   options:&empty] autorelease];

   // because of 0 duration expect nothing
   assert( ! animation);
   return( 0);
}
