<!-- keywords: mulle-ca patterns, cabasicanimation, capathanimation, catransaction, calayer -->
# patterns

## Explicit property animation

- `README.md` and `test/40-interpolation/caanimation-in-depth2.m` use the same shape: resolve a property, create a typed animation, set `animationObject`, then tick it through `CAAnimator`.
- Pass a real `animationRate` when you want frame-aligned output; `0.0` keeps interpolation continuous.

```objc
struct _mulle_objc_property      *property;
struct CABasicAnimationOptions   options;
CAAnimator                       *animator;
CABasicAnimation                 *animation;

property = MulleObjCInstanceSearchProperty( foo, @selector( someIntegerValue));
options  = CABasicAnimationOptionsMakeEaseInOut(
              mulle_relativetimerange_make( 0.0, 1.0),
              1.0,
              NO);

animation = [CABasicAnimation animationWithProperty:property
                                  startIntegerValue:0
                                    endIntegerValue:1000
                                           options:&options];
[animation setAnimationObject:foo];

animator = [CAAnimator instance];
[animator addAnimation:animation];
[animator animateWithAbsoluteTime:now
                    animationRate:1.0 / 60.0];
```

## Path-following animation

- `demo/src/main-path.m` uses `pose` with `CAPathAnimationValuePose` when the layer should move and rotate with the path.
- Use `frame` with `CAPathAnimationValuePositionAsOrigin` when only the origin should follow the path and the size should stay fixed.

```objc
struct _mulle_objc_property      *property;
struct CABasicAnimationOptions   options;
CAPathAnimation                  *animation;

property = MulleObjCInstanceSearchProperty( layer, @selector( pose));
options  = CABasicAnimationOptionsMakeEaseInOut(
              mulle_relativetimerange_make( 0.0, 4.0),
              INFINITY,
              YES);

animation = [CAPathAnimation pathAnimationWithProperty:property
                                                  path:path
                                         pathValueType:CAPathAnimationValuePose
                                               options:&options];
[animation setAnimationObject:layer];
[[window postLayoutAnimator] addAnimation:animation];
```

## Transaction-driven implicit animation

- `test/30-transaction/catransaction.m` shows the shortest working pattern: set transaction options first, mutate `observable` properties second, add the committed group to an animator last.
- Use this when the object already conforms to `CAImplicitlyAnimatableObject`; it is the local happy path for `CALayer`.

```objc
CATransaction      *transaction;
CAAnimationGroup   *group;

transaction = [CATransaction instance];
[transaction begin];
{
   [transaction setAnimationDuration:1.0];
   [transaction setAnimationCurve:CAAnimationCurveEaseInOut];
   [foo setValue:1848];
}
group = [transaction commit];
[group setDelegate:foo];
[animator addAnimation:group];
```

## Authoring an implicitly animatable object

- `test/30-transaction/catransaction.m` uses the mixin macros directly; keep that shape.
- `test/20-animatable/snapshot.m` shows that only `observable` properties are copied into the snapshot, so keep transient or unrelated state unobserved.

```objc
@interface Foo : NSObject <CAImplicitlyAnimatableObject>
{
   CAImplicitlyAnimatableObjectIvars;
}
@property( observable, assign) NSInteger   value;
CAImplicitlyAnimatableObjectInterface;
@end

@implementation Foo
CAImplicitlyAnimatableObjectImplementation;
@end
```

- If the object must own animations itself, also implement `CAAnimationStorageObject` and call `-initAnimationStorage` in `-init` and `-deallocAnimationStorage` in `-dealloc` as required by `src/CAAnimationStorage.h`.

## Grouping and sequencing

- `CAAnimationGroup` is the repo's parallel container; `CATransaction commit` returns one.
- `CAAnimationSequence` is for ordered steps; adding or inserting children rewrites delays instead of introducing a different execution model.
- Put delegate, `animationID`, and `animationContext` on the group or sequence when the whole unit matters more than individual child callbacks.
- For repeating sequences, use `duration = INFINITY` to auto-derive the cycle
  length from children. The sequence computes `sequenceDuration` once at start
  and caches it. This eliminates manual bookkeeping and duration mismatches.
- Use an explicit duration only when the cycle should be longer than the
  children sum (e.g. a group that holds before repeating).

```objc
// Auto-duration: cycle length = sum of children (computed once at start)
CAAnimationSequence   *sequence;

sequence = [[[CAAnimationSequence alloc] initWithAnimationOptions:
   &(struct CAAnimationOptions){ { 0, INFINITY }, 0, INFINITY, 0 }] autorelease];
[sequence addAnimation:first];   // 0.5s
[sequence addAnimation:second];  // 0.4s
[sequence addAnimation:third];   // 1.1s
// Repeat cycle = 2.0s (auto-computed)
```

```objc
// Explicit duration: group holds 1.5s after children finish before repeating
CAAnimationGroup   *group;

group = [[[CAAnimationGroup alloc] initWithAnimationOptions:
   &(struct CAAnimationOptions){ { 0, 2.5 }, 0, INFINITY, 0 }] autorelease];
[group addAnimation:child];  // 1.0s — remaining 1.5s is hold time
```

## Layer-side geometry authoring

- `src/CALayer.h` treats `frame`, `bounds`, and `canvas` as separate spaces; pick the property that matches the visual intent instead of forcing everything through `frame`.
- `demo/src/main-animate-additive.m` and `demo/src/main-animate-non-additive.m` animate `frame` directly because the demo wants visible layout movement, not drawing-space changes.
- For color or shape changes, keep them on the layer subclass and animate only the exposed animatable property (`fillColor`, `pose`, `frame`, `opacity`, ...).

## Minimal drawing-layer skeleton

- `demo/src/main-path.m` is the concrete local shape for a custom drawing layer: subclass `CGGraphicsLayer`, keep visual state on the layer object, and render against `[self canvas]`.
- `src/CALayer.h` still supplies the geometry rules underneath that subclass, so keep `frame`/`bounds`/`canvas` semantics in mind while drawing.

```objc
// MulleFooLayer.h
#import "import.h"

@interface MulleFooLayer : CGGraphicsLayer
{
   CGColor   _fillColor;
   CGFloat   _value;
}

@property( observable, assign) CGColor   fillColor;
@property( observable, assign) CGFloat   value;

@end


// MulleFooLayer.m
#import "import-private.h"

@implementation MulleFooLayer

- (BOOL) drawInContext:(CGContext *) context
{
   CGRect   bounds;

   if( ! [super drawInContext:context])
      return( NO);

   bounds = [self canvas];

   CGContextBeginPath( context);
   CGContextAddRect( context, bounds);
   CGContextFillColor( context, [self fillColor]);
   CGContextFill( context);

   return( YES);
}

@end
```

- Mark visual properties `observable` so redraws and implicit animation snapshots stay tied to the same surface (`src/CAImplicitlyAnimatableObject.h`, `test/20-animatable/snapshot.m`).
- Use `[self canvas]`, not ad-hoc rect math, for the drawable area inside `drawInContext:`. `demo/src/main-path.m` prints and draws from that canvas directly.

## Additive animations

Use `CAAnimationAdditive` when you need to layer multiple animations on the
same property without them clobbering each other. An additive animation
computes a *delta* `(end - start) * progress` and adds it to the property's
current value rather than replacing it.

### When to use additive

- **Combining path + scale**: A path animation writes position via `pose`.
  An additive frame animation can grow/shrink the layer on top without
  overwriting the position the path set.
- **Stacking effects**: Multiple animations can contribute to the same
  property simultaneously (e.g., a base idle sway + a hit reaction).
- **Relative adjustments**: When you want "grow by 16px" rather than
  "be exactly 56px wide", additive expresses intent better.

### When NOT to use additive

- When only one animation touches a property — absolute values are simpler.
- When the start/end values must be exact screen coordinates.
- With `cumulative` (`CAAnimationCumulative`) unless you specifically want
  the delta to accumulate across repeats.

### Setting the flag

Set `CAAnimationAdditive` in the options bits before creating the animation:

```objc
struct CABasicAnimationOptions   opts;

opts = CABasicAnimationOptionsMakeCurve(
   mulle_relativetimerange_make( 0, 1.5),
   CAAnimationCurveEaseInOutSine,
   INFINITY, YES);
opts.base.bits |= CAAnimationAdditive;

// Delta: adds (-8,-8,+16,+16) to current frame at full progress
anim = [[[CABasicAnimation alloc]
   initWithProperty:frameProperty
     startRectValue:CGRectMake( 0, 0, 0, 0)
       endRectValue:CGRectMake( -8, -8, 16, 16)
            options:&opts] autorelease];
[anim setAnimationObject:layer];
```

### Execution order matters

In a `CAAnimationGroup`, children execute in add-order. The last writer to a
property determines the base value that subsequent additive animations build
on. Place the non-additive (absolute) animation first, additive ones after:

```objc
[group addAnimation:pathAnim];    // writes pose (sets position)
[group addAnimation:scaleAnim];   // additive on frame (adds size delta)
```
