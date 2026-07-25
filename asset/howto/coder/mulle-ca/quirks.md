<!-- keywords: mulle-ca quirks, catransaction, calayer, additive, autoreverses, snapshot -->
# quirks

## Cross-cutting behavior

- MulleCA mutates the real object or layer. Do not reason in Apple presentation-layer terms; the animated value persists when the animation ends (`README.md`, `asset/dox/TOC.md`).
- `autoreverses` does **not** double the effective duration here. A reverse pass only happens once `repeatCount > 1` (`src/CAAnimation.h`, `src/CABasicAnimation.h`).
- `repeatCount <= 0.0` is corrected to `1.0` at creation time — zero repeats is treated as "play once" (`src/CAAnimation.h`).
- The animation delegate is **not retained** (`src/CAAnimation.h`). Keep the delegate owner alive yourself.
- `-interrupt`, `-finish`, `-cancel`, and `-reset` have different end states: current value, end value, start value, and timing reset without rewriting the object (`src/CAAnimation.h`).

## CAAnimation lifecycle

- Animations can be reused by calling `-init...` again on the same instance (`src/CABasicAnimation.h`). This reconfigures the animation without allocating a new object.
- `CAAnimationStart()` is a C function that initialises timing state; `CAAnimationComputeFrameInfo()` does pure math with no side effects; `CAAnimationDidAnimate()` finalises the frame. Use the raw functions (`test/40-interpolation/caanimation1.m`) when you need frame-by-frame control without the `-animateObject:absoluteTime:animationRate:` wrapper.

## CAInterpolatableValue protocol

- Objects conforming to `CAInterpolatableValue` must also conform to `NSCopying` and `NSObject` (`src/CABasicAnimation.h`). The `CAAnimationValueMakeWithObject` helper calls `[obj copy]` internally, so the copied object is stored.
- The `interpolatedValueWithDiff:previousDiff:` method receives `nil` for `previous` on the first call (`src/CABasicAnimation.h`). Handle that nil explicitly.

## CABasicAnimation and CAPathAnimation

- Two basic animations on the same property do not mix well by default; `demo/src/main-animate-non-additive.m` shows the later non-additive animation effectively winning.
- Additive mode blends by reading the current property value and adding diffs. That makes overlap possible (`demo/src/main-animate-additive.m`) but also means accumulated interpolation error is possible (`src/CABasicAnimation.h`).
- `CAAnimationCumulative` only makes sense together with additive behavior (`src/CAAnimation.h`).
- `CAPathAnimation` only works when `pathValueType` matches the target property shape. `CAPathAnimationValuePose` is not a drop-in replacement for `frame`, and `PositionAsOrigin` expects a rect-like property (`src/CAPathAnimation.h`, `demo/src/main-path.m`).

## Groups, sequences, and ownership

- Changing child animation values after a `CAAnimationGroup` has been created does not retroactively change what the group will run (`src/CAAnimationGroup.h`).
- Group duration does **not** clip children, but the group is removed when its own duration ends. If the group is shorter than a child, that child dies early (`src/CAAnimationGroup.h`).
- `CAAnimationSequence` is delay rewriting over normal stored animations, not a distinct scheduler. Insert/remove operations shift later children (`src/CAAnimationSequence.h`).

## Transactions and implicit animation

- `CATransaction` is short-lived and thread-local. Do not retain it, copy it, or use one transaction from multiple threads (`src/CATransaction.h`).
- The first `observable` write inside a transaction snapshots the object and registers it with the transaction (`src/CAImplicitlyAnimatableObject.m`).
- Only `observable` properties go into the snapshot. `test/20-animatable/snapshot.m` shows unobserved values dropping out while observed ones are copied.
- Implicit animation support is narrower than explicit `CABasicAnimation`: `src/CAImplicitlyAnimatableObject.h` explicitly excludes `BOOL`, unsigned types (`unsigned int`, `unsigned long`, etc.), `short`, `int`, `char`, `long`, `long long`, `long double`, pointer types, and `union {}` for implicit animation. Only `id`, `NSInteger`, `CGFloat`, `CGPoint`, `CGRect`, `CGSize`, `CAPolarPoint`, `CACircle`, `MulleCornerInsets`, `MulleEdgeInsets`, `NSRange`, and `mulle_range` work.
- Use `CATransactionSuspendedDo(name)` when code must mutate properties without generating implicit animations (`src/CATransaction.h`).

## CALayer-specific rules

- **CALayer has no sublayers.** There is no `addSublayer:`. A UIView owns
  multiple layers directly — not via a layer tree.
- **CALayer does not know its view.** Communication is view→layer only.
  A layer never references or messages its owning view.
- `transform`, `clipRect`, and `alpha` are render-side values owned by UIView code; `src/CALayer.h` marks them as "DO NOT TOUCH". Animate `frame`, `bounds`, or `opacity` instead.
- `frame`, `bounds`, and `canvas` are different spaces. Once you set `bounds` or `canvas` manually, automatic tracking is no longer the whole story, especially when scaling is involved (`src/CALayer.h`).
- `frameTracking` bitfield controls automatic size syncing: `CALayerCanvasSizeTracksFrameSize` and `CALayerBoundsSizeTracksFrameSize` are the two tracker constants (`src/CALayer.h`).
- CALayer animation access is not generally thread-safe; the public header expects serialization through the owning view's lock or an explicit shared lock (`src/CALayer.h`).

## Custom drawing-layer rules

- Inside `drawInContext:`, call `[super drawInContext:context]` first and stop if it returns `NO`; `demo/src/main-path.m` uses that contract.
- Use `[self canvas]` as the drawable rect inside a drawing layer. That is the repo's content-space API, not just a cached copy of `frame` (`src/CALayer.h`, `demo/src/main-path.m`).
- Keep visual state on `observable` properties if redraw or implicit animation should track it. Snapshotting ignores unobserved state (`src/CAImplicitlyAnimatableObject.m`, `test/20-animatable/snapshot.m`).
