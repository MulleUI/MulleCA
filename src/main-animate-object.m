#import "import-private.h"

#import "CALayer.h"
#import "CAAnimation.h"
#import "CGGeometry.h"
#import "CGGeometry+CString.h"
#import <string.h>

@interface Foo : NSObject

// doesn't need to be observable, as we do the animation manually
@property( assign) CGRect   rect;

@end

@implementation Foo

- (void) setRect:(CGRect) rect
{
   fprintf( stderr, "%s %s -> %s\n",
                     __PRETTY_FUNCTION__,
                     CGRectCStringDescription( _rect),
                     CGRectCStringDescription( rect));
   _rect = rect;
}

@end


int   main()
{
   Foo              *foo;
   CAAnimation      *animation;
   CAAbsoluteTime   time;

   foo = [Foo object];
   [foo setRect:CGRectMake( 0, 1, 1, 1)];

   animation = [[[CAAnimation alloc] initWithPropertySetter:@selector( setRect:)
                                                  startRect:CGRectMake( 0, 1, 2, 2)
                                                    endRect:CGRectMake( 1, 2, 3, 3)
                                                    options:NULL] autorelease];

   for( time = 0.0; time <= 1.1; time += 0.1)
   {
      fprintf( stderr, "%.1f: ", time);
      [animation animateObject:foo
                  absoluteTime:time];
   }

   // animation is used up at this point
   fprintf( stderr, "%.1f: ", 0.5);
   [animation animateObject:foo
               absoluteTime:0.5];

   // can reset though, now interestingly the absolute time doesn't
   // matter as its the start point, whatever we pass
   [animation reset];
   [animation animateObject:foo
               absoluteTime:0.5];

   // animation is used up at this point

   fprintf( stderr, "\n");
   [foo setRect:CGRectMake( 0, 1, 1, 1)];

   animation = [[[CAAnimation alloc] initWithPropertySetter:@selector( setRect:)
                                                  startRect:CGRectMake( 0, 1, 2, 2)
                                                    endRect:CGRectMake( 1, 2, 3, 3)
                                                    options:NULL] autorelease];

   // we miss the 1.0, but we should end up with the end
   for( time = 0.0; time <= 1.3; time += 0.3)
   {
      fprintf( stderr, "%.1f: ", time);
      [animation animateObject:foo
                  absoluteTime:time];
   }

   return( 0);
}

