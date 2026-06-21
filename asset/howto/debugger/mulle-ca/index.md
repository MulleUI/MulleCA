<!-- keywords: debugger, mulle-ca, caanimation, cabasicanimation, capathanimation, caanimator, catransaction, calayer -->
# mulle-ca

Use this bundle when a MulleCA animation in this repo starts, stops, clobbers another animation, or leaves the wrong final value behind. The main local debugging delta from Apple Core Animation is that MulleCA mutates the real object or `CALayer`; there is no separate presentation tree to inspect instead.

## Understand first

```bash
mulle-sde api list
mulle-sde code map
mulle-sde code search CAAnimation
mulle-sde code search CAAnimator
mulle-sde code search CATransaction
mulle-sde code search CAPathAnimation
mulle-sde code search CALayer
```

## Local references

- Overview and library-level semantics: `README.md`, `asset/dox/TOC.md`
- Explicit animation families: `src/CAAnimation.h`, `src/CABasicAnimation.h`, `src/CAPathAnimation.h`
- Driver and storage: `src/CAAnimator.h`, `src/CAAnimationGroup.h`, `src/CAAnimationSequence.h`, `src/CAAnimationStorage.h`
- Implicit animation path: `src/CATransaction.h`, `src/CAImplicitlyAnimatableObject.h`
- Layer target rules: `src/CALayer.h`
- Repros for overlap, path motion, and timing curves: `demo/src/main-animate-additive.m`, `demo/src/main-animate-non-additive.m`, `demo/src/main-path.m`, `demo/src/main-tween.m`
- Small proofs for snapshots, transactions, and interpolation math: `test/20-animatable/snapshot.m`, `test/30-transaction/catransaction.m`, `test/40-interpolation/caanimation1.m`, `test/40-interpolation/caanimation-in-depth2.m`

## Main surfaces

| Symptom | Start with | Local rule |
| --- | --- | --- |
| Explicit animation does nothing | `CABasicAnimation` + `CAAnimator` | The runtime property lookup and `animationObject` both matter; missing either usually looks like a no-op. |
| One layer animation kills another | `CATransaction` + additive flag | Non-additive layer commits remove prior layer animations; compare `demo/src/main-animate-additive.m` and `demo/src/main-animate-non-additive.m`. |
| Path-following writes the wrong shape | `CAPathAnimation` | `pathValueType` must match the target property shape: `pose` for pose, `PositionAsOrigin` for rect origin movement. |
| Implicit animation never appears | `CATransaction` + `CAImplicitlyAnimatableObject` | Only `observable` properties snapshot, and implicit support excludes `BOOL`, unsigned scalars, pointers, and similar signatures. |
| Child animations die early or sequencing feels wrong | `CAAnimationGroup` / `CAAnimationSequence` | Groups do not clip children, but a short-lived group still removes them; sequences are delay rewriting, not a different runner. |
| Layer geometry looks wrong while animating | `CALayer` | Debug in `frame`/`bounds`/`canvas` terms; `transform`, `clipRect`, and `alpha` are explicitly off-limits. |
| You need live animation inventory | `CAAnimator` + `CAAnimationStorage` | Use the storage/count helpers before assuming a timing bug. |

## Local workflow

1. Classify the failure first: explicit property animation, path animation, implicit transaction animation, container timing, or `CALayer` geometry.
2. Reproduce with the closest demo or test before digging deeper; the repo already has focused proofs for additive overlap, path motion, snapshots, and timing.
3. Inspect the actual owner that stores the animation: `CAAnimator`, `CAAnimationGroup`, `CAAnimationSequence`, or a target implementing `CAAnimationStorageObject`.
4. For transaction bugs, check `observable` coverage, supported implicit types, and whether additive or non-additive behavior explains the result.
5. Report the exact family and repo path that establishes the rule instead of describing it as generic Core Animation behavior.

## Verify/report

When you report a MulleCA bug, name the family you traced (`CABasicAnimation`, `CAPathAnimation`, `CATransaction`, `CAAnimationGroup`, `CAAnimationSequence`, `CALayer`) and cite the exact header, demo, or test path that proves the behavior.
