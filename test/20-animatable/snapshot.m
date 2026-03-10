#import <MulleCA/MulleCA.h>


struct huge_struct
{
   char     bytes[ 256];
   size_t   length;
};


@interface SimpleStaticString : NSObject < NSCopying>
{
   char   *_s;
}
@end


@implementation SimpleStaticString

+ (instancetype) stringWithStaticUTF8String:(char *) s
{
   SimpleStaticString  *obj;

   obj = [self instance];
   obj->_s = s;
   return( obj);
}

- (id) copy
{
   SimpleStaticString   *copy;

   copy = [[self class] stringWithStaticUTF8String:_s];
   [copy retain];
   return( copy);
}


- (char *) UTF8String
{
   return( _s);
}

@end


@interface TestClass : MulleObject < CAImplicitlyAnimatableObject>

@property( retain) id                                         snapshot;

@property( retain) id                                         anUnobservedValue;
@property( dynamic, retain) id                                aDynamicUnobservedValue;


@property( observable, assign) struct huge_struct             aName;
@property( observable, assign) double                         aDoubleValue;
@property( observable, retain) id                             aRetainValue;
@property( observable, copy) id                               aCopyValue;

@property( dynamic, observable, assign) struct huge_struct    aDynamicName;
@property( dynamic, observable, assign) double                aDynamicDoubleValue;
@property( dynamic, observable, retain) id                    aDynamicRetainValue;
@property( dynamic, observable, copy) id                      aDynamicCopyValue;

@end


@implementation TestClass

@dynamic aDynamicUnobservedValue;
@dynamic aDynamicName;
@dynamic aDynamicDoubleValue;
@dynamic aDynamicRetainValue;
@dynamic aDynamicCopyValue;


- (void) print
{
   struct huge_struct  value;

   mulle_printf( "unobservedValue    : %@\n", [self anUnobservedValue]);

   value = [self aName];
   mulle_printf( "name               : %.*s\n", (int) value.length, value.bytes);
   mulle_printf( "doubleValue        : %.2f\n", [self aDoubleValue]);

   mulle_printf( "retainValue        : %@\n", [self aRetainValue]);
   mulle_printf( "copyValue          : %@\n", [self aCopyValue]);

   mulle_printf( "unobservedValue    : %@\n", [self aDynamicUnobservedValue]);

   value = [self aDynamicName];
   mulle_printf( "dynamicName        : %.*s\n", (int) value.length, value.bytes);
   mulle_printf( "dynamicDoubleValue : %.2f\n", [self aDynamicDoubleValue]);

   mulle_printf( "dynamicRetainValue : %@\n", [self aDynamicRetainValue]);
   mulle_printf( "dynamicCopyValue   : %@\n", [self aDynamicCopyValue]);
}

@end


int   main( void)
{
   TestClass            *object;
   id                   snapshot;
   SimpleStaticString   *a;
   SimpleStaticString   *b;
   SimpleStaticString   *c;
   SimpleStaticString   *d;
   SimpleStaticString   *e;
   SimpleStaticString   *f;
   struct huge_struct   value;

   a = [SimpleStaticString stringWithStaticUTF8String:"a"];

   b = [SimpleStaticString stringWithStaticUTF8String:"b"];
   c = [SimpleStaticString stringWithStaticUTF8String:"c"];

   d = [SimpleStaticString stringWithStaticUTF8String:"d"];
   e = [SimpleStaticString stringWithStaticUTF8String:"e"];
   f = [SimpleStaticString stringWithStaticUTF8String:"f"];

   object = [TestClass instance];

   [object setAnUnobservedValue:a];
   strcpy( value.bytes, "VfL Bochum");
   value.length = strlen( value.bytes);
   [object setAName:value];
   [object setADoubleValue:18.48];

   [object setARetainValue:b];
   [object setACopyValue:c];

   [object setADynamicUnobservedValue:d];
   strcpy( value.bytes, "FC Wismut Aue");
   value.length = strlen( value.bytes);
   [object setADynamicName:value];
   [object setADynamicDoubleValue:1990];

   [object setADynamicRetainValue:e];
   [object setADynamicCopyValue:f];

   [object print];

   snapshot = [object observablePropertiesSnapshot];

   [snapshot print];

   return( 0);
}
