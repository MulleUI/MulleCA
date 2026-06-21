<!-- keywords: debugging, tracing, diagnostics, caanimation, caanimator, catransaction, calayer -->
# mulle-ca

Use this bundle when user code built on MulleCA animates the wrong value, never creates the expected implicit animation, or needs library-side trace output. The main local delta from Apple Core Animation is that MulleCA mutates the real object or `CALayer`; debug the actual target state, not a separate presentation tree.

## Understand first

```bash
mulle-sde api apropos CAAnimation
mulle-sde api apropos CALayer
mulle-sde api cat CAAnimation
mulle-sde api cat CAAnimator
mulle-sde api cat CAPathAnimation
mulle-sde api cat CATransaction
mulle-sde api cat CAImplicitlyAnimatableObject
mulle-sde api cat CALayer
mulle-sde api cat CAAnimationGroup
mulle-sde api cat CAAnimationSequence
```

## Local references

- Overview and semantics: `README.md`, `asset/dox/TOC.md`
- Public diagnostics and storage: `src/CAAnimation.h`, `src/CABasicAnimation.h`, `src/CAPathAnimation.h`, `src/CAAnimator.h`, `src/CAAnimationGroup.h`, `src/CAAnimationSequence.h`, `src/CAAnimationStorage.h`, `src/CALayer.h`
- Implicit-animation rules: `src/CATransaction.h`, `src/CAImplicitlyAnimatableObject.h`
- Debug bit definitions used by startup tracing: `src/CAAnimation+DebugPrivate.h`, `src/CALayer+DebugPrivate.h`
- Focused repros: `demo/src/main-animate-additive.m`, `demo/src/main-animate-non-additive.m`, `demo/src/main-path.m`, `test/20-animatable/snapshot.m`, `test/30-transaction/catransaction.m`, `test/40-interpolation/caanimation-in-depth2.m`

## Tracing hooks

```bash
export CAAnimationDebuggingFlags=0x7
export CALayerDebuggingFlags=0x1041
```

- `CAAnimationDebuggingFlags` seeds new `CAAnimation` instances: `0x1` general logs, `0x2` interpolation logs, `0x4` state-transition logs, `0x1000` verbose logs (`src/CAAnimation+DebugPrivate.h`, `src/CAAnimation.m`).
- `CALayerDebuggingFlags` seeds new `CALayer` instances: `0x1` general logs, `0x40` display-bit logs, `0x1000` verbose logs (`src/CALayer+DebugPrivate.h`, `src/CALayer.m`).
- `UIDebuggingFlags` is a shared fallback for both classes. Prefer the class-specific variables because the bit meanings are not identical.
- These variables are read during class initialization, so set them before the first `CAAnimation` or `CALayer` instance is created.

## Main surfaces

| Symptom | Start with | Local rule |
| --- | --- | --- |
| Explicit animation is a no-op | `CAAnimator` + `CABasicAnimation` | Check `animationObject`, then ask the animator for active/running/finished counts before blaming timing. |
| Implicit animation never appears | `CATransaction` + snapshot rules | Only the first `observable` write inside the transaction snapshots/registers the object, and implicit support excludes `BOOL`, unsigned scalars, pointers, and similar signatures. |
| One layer animation kills another | `CATransaction` additive flag | Non-additive layer commits remove prior layer animations; compare `demo/src/main-animate-additive.m` and `demo/src/main-animate-non-additive.m`. |
| Path-following writes the wrong shape | `CAPathAnimation` | `pathValueType` must match the destination property shape; `demo/src/main-path.m` uses `pose` for full pose and `frame` with `PositionAsOrigin` for origin-only motion. |
| Group/sequence finishes at the wrong time | `CAAnimationGroup` / `CAAnimationSequence` | Groups must outlive their longest child; sequences are delay rewriting, not a separate scheduler. |
| Geometry looks wrong while animating | `CALayer` | Debug in `frame`/`bounds`/`canvas` terms; `transform`, `clipRect`, and `alpha` are explicitly off-limits. |
| Completion callback vanished | `CAAnimation` delegate | Delegates are not retained here. |

## Local workflow

1. Pick the family first: explicit property animation, path animation, implicit transaction animation, container timing, or `CALayer` geometry.
2. Turn on the narrowest trace hook you need, or set per-instance `debuggingFlags` on the suspect `CAAnimation` or `CALayer`.
3. For layer-side bugs, set a stable `nameUTF8String` and call `dumpWithIndent:FILE:` so geometry reports identify the right layer.
4. For owner-side bugs, use `CAAnimator` inventory methods such as `getAnimations:maxCount:animationID:animationObject`, `numberOfActiveAnimations`, `numberOfRunningAnimations`, and `numberOfFinishedAnimations`.
5. For timing/state bugs, stringify the library's own enums instead of inventing labels: `CAAnimationBitsUTF8String`, `CAAnimationOptionsUTF8String`, `CAAnimationReturnStateUTF8String`, `CAPathAnimationValueTypeUTF8String`.
6. Reproduce against the closest repo proof before filing a bug: snapshots in `test/20-animatable/snapshot.m`, transactions in `test/30-transaction/catransaction.m`, overlap rules in the additive/non-additive demos.

## Verify/report

When you report a MulleCA issue, name the family you traced (`CABasicAnimation`, `CAPathAnimation`, `CATransaction`, `CAAnimationGroup`, `CAAnimationSequence`, `CALayer`), include the debug flag mask if you used one, and cite the exact header, demo, or test path that establishes the rule.
