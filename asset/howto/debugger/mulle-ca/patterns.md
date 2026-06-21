<!-- keywords: debugger patterns, mulle-ca, caanimator, catransaction, capathanimation, calayer -->
# patterns

## Start by reproducing the right family

- Use `test/40-interpolation/caanimation-in-depth2.m` for explicit interpolation timing, `test/30-transaction/catransaction.m` for implicit animation generation, and `demo/src/main-path.m` for property-shape/path-shape mismatches.
- For overlap bugs on layers, compare `demo/src/main-animate-additive.m` and `demo/src/main-animate-non-additive.m` before reading implementation.

## Explicit animation triage

- The shortest trustworthy shape is still the README/test pattern: resolve the property, create a typed animation, set `animationObject`, then tick it through `CAAnimator`.
- If output looks quantized or late, compare the passed `animationRate` with `test/40-interpolation/caanimation-in-depth2.m`; `0.0` keeps interpolation continuous, a real rate makes frame math matter.

```objc
property = MulleObjCInstanceSearchProperty( foo, @selector( f));
animation = [CABasicAnimation animationWithProperty:property
                                    startFloatValue:0
                                      endFloatValue:1
                                             options:&options];
[animation setAnimationObject:foo];

animator = [CAAnimator instance];
[animator addAnimation:animation];
[animator animateWithAbsoluteTime:now
                    animationRate:1.0 / 60.0];
```

## Inspect live storage before blaming timing

- `src/CAAnimator.h` exposes `getAnimations:maxCount:animationID:animationObject`, `numberOfActiveAnimations`, `numberOfRunningAnimations`, and `numberOfFinishedAnimations`; use them to prove whether the animation is stored, running, or already done.
- If a custom target owns animations directly, `src/CAAnimationStorage.h` expects `-initAnimationStorage` in `-init` and `-deallocAnimationStorage` in `-dealloc`.

```objc
count = [animator getAnimations:NULL
                       maxCount:0
                    animationID:"wizard-step"
                animationObject:layer];
```

## Reduce implicit animation bugs to the transaction pattern

- `test/30-transaction/catransaction.m` is the minimal repro: set transaction options first, mutate `observable` properties second, add the committed group to an animator last.
- If the object never joins the transaction, look for missing `CAImplicitlyAnimatableObjectIvars`, `CAImplicitlyAnimatableObjectInterface`, or `CAImplicitlyAnimatableObjectImplementation`.

```objc
transaction = [CATransaction instance];
[transaction begin];
{
   [transaction setAnimationDuration:1.0];
   [foo setValue:1848];
}
group = [transaction commit];
[animator addAnimation:group];
```

## Separate additive clobbering from path/property mismatch

- If two implicit layer animations interact, debug additive first. `demo/src/main-animate-non-additive.m` shows a later non-additive commit removing earlier layer animation state.
- If path motion is wrong, debug property shape next. `demo/src/main-path.m` uses `pose` with `CAPathAnimationValuePose`, but switches to `frame` with `CAPathAnimationValuePositionAsOrigin` when only the origin should move.

```objc
pathProperty  = MulleObjCInstanceSearchProperty( layer, @selector( pose));
pathValueType = CAPathAnimationValuePose;

pathAnimation = [CAPathAnimation pathAnimationWithProperty:pathProperty
                                                      path:path
                                             pathValueType:pathValueType
                                                   options:&options];
[pathAnimation setAnimationObject:layer];
```

## Snapshot and layer debugging

- `test/20-animatable/snapshot.m` is the fast proof that only `observable` properties enter the snapshot. If a value is missing from implicit animation, confirm that it is observed before debugging timing.
- `src/CALayer.h` documents the three geometry spaces. Debug `frame`, `bounds`, and `canvas` separately; many apparent animation bugs are really the wrong space being inspected.
- For layer-side bugs, prefer `opacity`, `frame`, `bounds`, `canvas`, or subclass-owned animatable properties such as `fillColor` from `demo/src/main-path.m`.
