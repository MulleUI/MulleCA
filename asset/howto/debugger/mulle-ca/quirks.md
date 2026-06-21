<!-- keywords: debugger quirks, mulle-ca, catransaction, calayer, additive, snapshot, sequence -->
# quirks

## Cross-cutting behavior

- MulleCA mutates the real object or layer, so final animated values persist (`README.md`, `asset/dox/TOC.md`).
- `CAAnimation` delegates are not retained; dangling delegates are an easy false lead during debugging (`src/CAAnimation.h`).
- `-interrupt`, `-finish`, `-cancel`, and `-reset` do different things: current value, end value, start value, and timing reset without rewriting the object (`src/CAAnimation.h`).
- `CAAnimationReverses` does not behave like Apple Core Animation here. Reverse motion only happens once `repeatCount > 1`, and `repeatCount <= 0.0` is corrected to `1.0` (`src/CAAnimation.h`, `src/CABasicAnimation.h`).

## CABasicAnimation and CAPathAnimation

- Additive overlap is local and deliberate. `demo/src/main-animate-additive.m` works because additive layer commits keep prior animations alive and add diffs to the current value.
- Non-additive layer commits can wipe earlier layer animation state; `demo/src/main-animate-non-additive.m` is the reference repro.
- `CAAnimationCumulative` only makes sense with additive behavior (`src/CAAnimation.h`).
- `CAPathAnimation` is not type-erased. `Pose`, `PositionAsOrigin`, and scalar/vector path modes must match the destination property shape (`src/CAPathAnimation.h`, `demo/src/main-path.m`).

## Driver, group, and sequence pitfalls

- `CAAnimationGroup` children run independently after creation; mutating child values later does not retroactively change the already-created group behavior (`src/CAAnimationGroup.h`).
- Group duration does not clip child timing, but the group is removed when its own duration expires. A too-short group still kills longer children early (`src/CAAnimationGroup.h`).
- `CAAnimationSequence` is just delay rewriting over stored child animations. Insert/remove operations shift later children, so sequence bugs often come from rewritten delays rather than scheduler state (`src/CAAnimationSequence.h`).
- If a target stores its own animations, missing `-initAnimationStorage` or `-deallocAnimationStorage` causes misleading storage bugs (`src/CAAnimationStorage.h`).

## Transactions and implicitly animatable objects

- `CATransaction` is short-lived and thread-local. Do not retain it, copy it, or share one transaction across threads (`src/CATransaction.h`).
- The first `observable` write inside a transaction is what snapshots and registers the object. If that write never happens, there is nothing to commit (`src/CATransaction.h`, `src/CAImplicitlyAnimatableObject.h`).
- Only `observable` properties enter the snapshot; `test/20-animatable/snapshot.m` is the proof.
- Implicit animation support is narrower than explicit `CABasicAnimation`: `BOOL`, unsigned scalar variants, pointer types, and similar signatures are excluded (`src/CAImplicitlyAnimatableObject.h`).
- Transaction forwarding properties such as `animationDuration`, `animationCurve`, `animationID`, and `animationContext` only apply between `-begin` and `-commit`/`-cancel` (`src/CATransaction.h`).
- Use `CATransactionSuspendedDo(name)` when code must mutate properties without generating implicit animations (`src/CATransaction.h`).

## CALayer-specific rules

- `frame`, `bounds`, and `canvas` are different spaces. Bugs that look like wrong interpolation are often just the wrong space being inspected (`src/CALayer.h`).
- `transform`, `clipRect`, and `alpha` are marked `DO NOT TOUCH`; they are render-side values owned elsewhere and will be overwritten (`src/CALayer.h`).
- `CALayer` base-class implicit animation coverage is mostly `opacity`, `frame`, `bounds`, and `canvas`; flags such as `hidden` or `masksToBounds` are not the same kind of observable target (`src/CALayer.h`).
- Layer access is not generally free-threaded. The public header expects serialization through the owning view lock or an explicit shared lock when the layer is standalone (`src/CALayer.h`).
