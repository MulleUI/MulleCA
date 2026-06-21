//
// Demonstrates: nested groups inside a repeating sequence fail to animate
// on the second sequential child (Group2) because children's start times
// are absolute, not relative to their group's activation within the cycle.
//
// Structure:
//   CAAnimationSequence (duration=2.0, repeatCount=INFINITY)
//     ├── CAAnimationGroup "pulse1" (duration=0.5, repeatCount=1)
//     │     └── CABasicAnimation x: 0→100 (duration=0.5)
//     ├── CAAnimationGroup "pulse2" (duration=0.5, repeatCount=1)
//     │     └── CABasicAnimation x: 0→200 (duration=0.5)
//     └── CABasicAnimation "rest" x: 0→0 (duration=1.0)
//
// Expected behavior:
//   t=0.0 → 0.5:  Group1 active, x interpolates 0→100
//   t=0.5 → 1.0:  Group2 active, x interpolates 0→200
//   t=1.0 → 2.0:  Rest, x stays at 0
//   t=2.0:         Repeat edge, cycle restarts
//
// Actual behavior:
//   t=0.0 → 0.5:  Group1 active, x interpolates 0→100  ← works
//   t=0.5 → 1.0:  Group2 active, but its child was already started at
//                  t=0.0 (absolute), so by virtualNow≈0.5 the child thinks
//                  it has been running 0.5s — past its 0.5s duration —
//                  and immediately finalizes. x snaps to 200 (end value)
//                  on the first tick, then stays dead.   ← BUG
//
// Root cause:
//   CAAnimationSequence's animateObject:absoluteTime:animationRate: calls
//   [self animateWithAbsoluteTime:virtualNow] UNCONDITIONALLY after the
//   super call — even when super returned CAAnimationReturnStateActive
//   (meaning "I haven't reached my start time yet, don't run").
//
//   When Group2 is a child of the outer sequence, the outer sequence's
//   storage iteration calls [group2 animateObject:... absoluteTime:virtualNow].
//   Group2 inherits CAAnimationSequence's animateObject: override. The super
//   call says "Active" (Group2's delay=0.5 hasn't been reached), but the code
//   falls through and calls [self animateWithAbsoluteTime:] anyway, driving
//   Group2's children prematurely.
//
//   The fix: gate the [self animateWithAbsoluteTime:] call on the state
//   being at least Started (not Active/waiting).
//
#import <MulleCA/MulleCA.h>

#import <stdio.h>


@interface Foo : NSObject

@property( assign) NSInteger   x;

@end


@implementation Foo

- (void) setX:(NSInteger) x
{
   _x = x;
}

@end


int   main( int argc, char *argv[])
{
   Foo                              *foo;
   CABasicAnimation                 *anim;
   CAAnimationGroup                 *group1;
   CAAnimationGroup                 *group2;
   CAAnimationSequence              *seq;
   struct CABasicAnimationOptions   opts;
   struct _mulle_objc_property      *property;
   mulle_absolutetime_t             t;
   NSInteger                        lastX;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( x));

   // Outer sequence: 2.0s, repeats forever
   seq = [[[CAAnimationSequence alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, 2.0 }, 0, INFINITY, 0 }] autorelease];

   // Group1: duration=0.5s — child animates x from 0→100 over 0.5s
   group1 = [[[CAAnimationGroup alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, 0.5 }, 0, 1.0, 0 }] autorelease];
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.5), 1.0, NO);
   anim = [[[CABasicAnimation alloc] initWithProperty:property
                                     startIntegerValue:0
                                       endIntegerValue:100
                                               options:&opts] autorelease];
   [anim setAnimationObject:foo];
   [group1 addAnimation:anim];
   [seq addAnimation:group1];

   // Group2: duration=0.5s — child animates x from 0→200 over 0.5s
   // This is the SECOND child of the sequence, so it should activate
   // at t=0.5 (after Group1 finishes).
   group2 = [[[CAAnimationGroup alloc] initWithAnimationOptions:
      &(struct CAAnimationOptions){ { 0, 0.5 }, 0, 1.0, 0 }] autorelease];
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 0.5), 1.0, NO);
   anim = [[[CABasicAnimation alloc] initWithProperty:property
                                     startIntegerValue:0
                                       endIntegerValue:200
                                               options:&opts] autorelease];
   [anim setAnimationObject:foo];
   [group2 addAnimation:anim];
   [seq addAnimation:group2];

   // Rest: duration=1.0s — holds x at 0
   opts = CABasicAnimationOptionsMakeLinear(
      mulle_relativetimerange_make( 0, 1.0), 1.0, NO);
   anim = [[[CABasicAnimation alloc] initWithProperty:property
                                     startIntegerValue:0
                                       endIntegerValue:0
                                               options:&opts] autorelease];
   [anim setAnimationObject:foo];
   [seq addAnimation:anim];

   // Animate at 0.1s intervals, report x
   // If working correctly:
   //   t=0.0-0.5: x ramps 0→100 (Group1)
   //   t=0.5-1.0: x ramps 0→200 (Group2)  ← this is what fails
   //   t=1.0-2.0: x=0 (rest)
   lastX = -1;
   for( t = 0.0; t <= 1.2; t += 0.1)
   {
      [foo setX:-1];  // sentinel
      [seq animateObject:foo
            absoluteTime:t
           animationRate:0.0];
      if( [foo x] != lastX)
      {
         printf( "t=%.1f: x=%td\n", t, [foo x]);
         lastX = [foo x];
      }
   }

   return( 0);
}
