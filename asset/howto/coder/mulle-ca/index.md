<!-- keywords: mulle-ca, caanimation, cabasicanimation, capathanimation, caanimator, catransaction, calayer, cggraphicslayer -->
# mulle-ca

Use this bundle when you need to add, debug, or extend MulleCA animations or drawing-layer code in this repo. The main local delta from Apple Core Animation is that MulleCA writes animated values back to the real object or layer; there is no separate presentation tree hiding the final state.

## Understand first

```bash
mulle-sde api list
mulle-sde code search CAAnimator
mulle-sde code search CABasicAnimation
mulle-sde code search CAPathAnimation
mulle-sde code search CATransaction
mulle-sde code search CAImplicitlyAnimatableObject
mulle-sde code search CALayer
```

## Local references

- Overview: `README.md`, `asset/dox/TOC.md`
- Explicit animation core: `src/CAAnimation.h`, `src/CABasicAnimation.h`, `src/CAPathAnimation.h`, `src/CAAnimator.h`
- Composition and storage: `src/CAAnimationGroup.h`, `src/CAAnimationSequence.h`, `src/CAAnimationStorage.h`
- Implicit animation and targets: `src/CATransaction.h`, `src/CAImplicitlyAnimatableObject.h`, `src/CALayer.h`
- Working examples: `demo/src/main-animate-additive.m`, `demo/src/main-animate-non-additive.m`, `demo/src/main-path.m`, `demo/src/main-tween.m`
- Small proofs: `test/20-animatable/snapshot.m`, `test/30-transaction/catransaction.m`, `test/40-interpolation/caanimation1.m`, `test/40-interpolation/caanimation-in-depth2.m`

## Main surfaces

| Scenario | Start with | Local rule |
| --- | --- | --- |
| Animate one property explicitly | `CABasicAnimation` + `CAAnimator` | Resolve the runtime property with `MulleObjCInstanceSearchProperty`, then set `animationObject` before adding it. |
| Move along geometry | `CAPathAnimation` | Match `pathValueType` to the property shape: `pose` for pose, `frame` for `PositionAsOrigin`, scalar/point-like properties for the scalar/vector modes. |
| Turn property writes into animations | `CATransaction` + `CAImplicitlyAnimatableObject` | Only `observable` properties participate; the first write inside the transaction snapshots the old values. |
| Run many animations together | `CAAnimationGroup` | Children run in parallel; the group must outlive the longest child. |
| Chain steps | `CAAnimationSequence` | Sequence timing is implemented by child delays, not by a separate runner. |
| Animate layer geometry safely | `CALayer` | Use `frame`, `bounds`, `canvas`, and `opacity`; leave `transform`, `clipRect`, and `alpha` alone. |
| Author a custom drawing layer | `CGGraphicsLayer` + `CALayer` rules | Inside `drawInContext:`, call `[super drawInContext:context]`, draw against `[self canvas]`, and keep visual state on `observable` properties. |

## Local workflow

1. Decide whether the repo wants explicit animation (`CABasicAnimation` or `CAPathAnimation`) or implicit animation (`CATransaction` over `observable` properties).
2. For explicit animation, look up the property, build `CAAnimationOptions` or `CABasicAnimationOptions`, create the animation, and call `[animation setAnimationObject:target]`.
3. Run it through the right owner: `CAAnimator` for a frame loop, `CAAnimationGroup` from `CATransaction commit`, or an object that implements `CAAnimationStorageObject`.
4. For `CALayer`, reason in `frame`/`bounds`/`canvas` terms. The animated end value persists on the real layer after the animation stops.
5. For a custom drawing layer, treat the layer subclass as part of the public authoring surface: expose visual properties as `observable`, draw from `[self canvas]`, and keep the `drawInContext:` contract from `demo/src/main-path.m`.

## Verify/report

When you describe behavior, name the family you relied on (`CABasicAnimation`, `CAPathAnimation`, `CATransaction`, `CAAnimationGroup`, `CALayer`) and cite the exact demo, test, or header path that establishes the rule.
