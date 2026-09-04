# MulleCA Library Documentation for AI
<!-- Keywords: animation, interpolation, timing, properties, sequence, grouping, implicit -->

## 1. Introduction & Purpose

MulleCA is a real-time property animation library for mulle-objc that enables smooth interpolation of object property values over time. It provides a comprehensive animation system for animating NSInteger, CGFloat, CGFloat2, CGFloat4, CGPoint, CGRect, CGSize, NSRange, BOOL, float arrays, and custom interpolatable objects. The library supports both explicit animations (via `CABasicAnimation` and `CAPathAnimation`) and implicit animations (via `CATransaction`), along with sequential animation choreography via `CAAnimationSequence` and parallel grouping via `CAAnimationGroup`. Features include time delays, durations, repeat counts, auto-reverse, additive blending, cumulative effects, `animationRate` quantization, and customizable timing curves with 30+ easing presets. MulleCA differs from Apple's CoreAnimation by directly modifying object properties rather than operating on a presentation tree, making animated values persistent. It is a foundational component of the MulleUI framework, depending on `MulleUIBase` and `mulle-objc-list` (build-time).

## 2. Key Concepts & Design Philosophy

**Direct Property Mutation**: Unlike Apple's CoreAnimation which operates on a presentation tree, MulleCA animations directly modify the properties of target objects. This means animated values persist and are immediately reflected in the object's state.

**Animation Storage Protocol**: The `CAAnimationStorage` protocolclass (via `@mixin CAAnimationStorageObject`) provides a standardized way for objects to store and manage animations. Objects like `CAAnimator`, `CAAnimationSequence`, `CAAnimationGroup`, and `CALayer` include this mixin to hold animation collections.

**Explicit vs Implicit Animations**: MulleCA supports two animation paradigms:
- **Explicit animations**: Created manually using `CABasicAnimation` or `CAPathAnimation`, configured with start/end values, and added to a `CAAnimator`, `CAAnimationSequence`, or `CAAnimationGroup`
- **Implicit animations**: Generated automatically via `CATransaction` when modifying `observable` properties on objects conforming to `@mixin CAImplicitlyAnimatableObject`

**Sequential Choreography (`CAAnimationSequence`)**: Animations can be arranged to run one after another by adding them to a `CAAnimationSequence`. Internally, sequencing is achieved through staggered delays — all children run in the `CAAnimationStorage` in parallel but their individual delays are computed so they execute in order. Operations like `insertAnimation:beforeAnimation:`, `insertAnimation:afterAnimation:`, and `removeAnimation:` splice and shift the sequence.

**Parallel Groups (`CAAnimationGroup`)**: `CAAnimationGroup` inherits from `CAAnimationSequence` but overrides `addAnimation:` to place all children at the same start time (concurrent execution). It is typically created by `CATransaction` during `-begin` and collects animations generated during the transaction.

**Interpolation and Timing**: Animations interpolate values using timing functions (linear, ease-in, ease-out, ease-in-out) or custom tween functions (30+ easing presets: Quadratic, Cubic, Quartic, Quintic, Sine, Exponential, Circular, Back, Bounce, Elastic). The interpolation factor `t` (0.0 to 1.0) represents progress through the animation duration.

**Additive and Cumulative Modes**: Animations can be additive (adding interpolated differences to current values) enabling multiple animations to blend, or cumulative (preserving accumulated values across repeat cycles). This allows for complex animation layering.

**Frame Quantization**: Optional quantization ensures that animations align with discrete frame times (e.g., 60 Hz), guaranteeing accurate final values when `animationRate` is specified.

**Thread-Local Transactions**: `CATransaction` objects operate on a per-thread basis, allowing safe implicit animation generation without global state conflicts.

**Animation Stop Semantics**: Four distinct stop behaviors are available:
- `-interrupt`: Stop at current value, delegate gets `animationDidStop:finished:NO`
- `-finish`: Jump to end value, delegate gets `animationDidStop:finished:YES`
- `-cancel`: Revert to start value, delegate gets `animationDidStop:finished:NO`
- `-reset`: Reset internal timing state without writing to the object (no delegate callback)

**Animation Identification**: Animations can carry an `animationID` (a C string), enabling selective finishing or cancellation of animation subsets by ID. `CAAnimationSequence` and `CAAnimationGroup` store and forward the ID; base `CAAnimation` returns `NULL`.

## 3. Core API & Data Structures

### 3.1. `CAAnimation.h`

#### `@protocol CAAnimation`
- **Purpose:** Core protocol defining the animation contract that all animation types must implement
- **Key Properties:**
  - `removedOnCompletion` - Whether animation is automatically removed when finished
  - `animationObject` - The object being animated (retain)
- **Key Methods:**
  - `-animationID` - Returns a C string identifier for the animation kind (base returns `NULL`; sequence/group forward stored value)
  - `-animateObject:absoluteTime:animationRate:` - Advances animation state and returns `CAAnimationReturnState`
  - `-reverse` - Reverses animation direction (used with `CAAnimationReverses`)
  - `-reset` - Resets animation internal timing state (no property write, no delegate callback)
  - `-interrupt` - Stops animation at current interpolated value (delegate: `animationDidStop:finished:NO`)
  - `-finish` - Jumps animation to end value (delegate: `animationDidStop:finished:YES`)
  - `-cancel` - Reverts animation to start value; for sequences/groups, children are cancelled in reverse order (delegate: `animationDidStop:finished:NO`)
  - `-changesLayout` - Returns `YES` if animation affects UIView frame or bounds

#### `struct CAAnimationOptions`
- **Purpose:** Configuration structure for animation timing and behavior
- **Key Fields:**
  - `timeRange` - Contains `delay` and `duration` (`struct mulle_relativetimerange`)
  - `offset` - Starting offset into animation cycle (0.0 to 1.0)
  - `repeatCount` - Number of times to repeat animation (use `INFINITY` for endless)
  - `bits` - Flags from `CAAnimationBits`
- **Functions:**
  - `CAAnimationOptionsMake( timeRange, offset, repeatCount, bits)` - Create options
  - `CAAnimationOptionsSetTimeRange()`, `CAAnimationOptionsSetOffset()`, `CAAnimationOptionsSetRepeatCount()` - Mutate options
  - `CAAnimationOptionsSetBit()` / `CAAnimationOptionsClearBit()` - Manipulate flags
  - `CAAnimationOptionsUTF8String()` - Debug string representation

#### `enum CAAnimationBits`
- **Purpose:** Flags controlling animation behavior and state
- **User Options (preserved across resets):**
  - `CAAnimationReverses` (0x10000) - Reverse direction on each repeat; requires `repeatCount > 1`
  - `CAAnimationQuantize` (0x20000) - Snap animation to discrete frame boundaries
  - `CAAnimationAdditive` (0x40000) - Values are added to object's current value rather than replacing
  - `CAAnimationCumulative` (0x80000) - With additive, values accumulate across repeat cycles
  - `CAAnimationRateCorrect` (0x100000) - Scale timing according to animation rate
- **Internal State (reset automatically):**
  - `CAAnimationStarted`, `CAAnimationAnimating`, `CAAnimationScrubbing`, `CAAnimationHasReversed`, `CAAnimationIsReverse`, `CAAnimationFinalized`, `CAAnimationEnded`
  - `CAAnimationDelegateWillStartNotified`, `CAAnimationDelegateDidStartNotified`
- **Signal Bits:**
  - `CAAnimationInterruptSignal` (0x100), `CAAnimationFinishSignal` (0x200)
- **Other Flags:**
  - `CAAnimationHasIntegerRepeat` (0x200000)
  - `CAAnimationStickyArrayCenter` (0x400000), `CAAnimationStickyArrayEnd` (0x800000)

#### `enum CAAnimationReturnState`
- **Purpose:** Return codes from `-animateObject:absoluteTime:animationRate:`
- **Values:**
  - `CAAnimationReturnStateDone` - Animation has completed
  - `CAAnimationReturnStateActive` - Animation exists but is waiting (e.g., during delay)
  - `CAAnimationReturnStateStarted` - Animation just began this frame
  - `CAAnimationReturnStateAnimating` - Animation is actively interpolating
  - `CAAnimationReturnStateFinalAnimation` - Animation just set final value (useful for chaining)

#### `@protocol CAAnimationDelegate`
- **Purpose:** Delegate protocol for animation lifecycle notifications
- **Methods:**
  - `- (void) animationWillStart:(CAAnimation *) animation;`
  - `- (void) animationDidStart:(CAAnimation *) animation;`
  - `- (void) animationDidStop:(CAAnimation *) animation finished:(BOOL) flag;`

#### `struct CAAnimationFrameInfo`
- **Purpose:** Provides temporal information during animation frame processing
- **Key Fields:**
  - `t` - Normalized time (0.0 to 1.0) through current animation cycle (`double`)
  - `i` - Current animation index (increments with each repeat) (`NSUInteger`)
  - `nextState` - Bitfield for next state transitions (`NSUInteger`)
  - `delta` - Time elapsed since previous frame (`mulle_relativetime_t`)
  - `elapsedTime` - Total time elapsed since animation start (`mulle_relativetime_t`)

#### `struct CAAnimationMutableState`
- **Purpose:** Internal mutable timing state for animation playback (exposed for `@defs()` access)
- **Key Fields:**
  - `start` - Absolute start timestamp (`mulle_absolutetime_t`)
  - `duration` - Copied duration for frame computation (`mulle_relativetime_t`)
  - `bits` - Runtime state bits (`NSUInteger`)
  - `previousAnimationIndex` - Prior repeat index (`NSUInteger`)
  - `previousFrameTimestamp` - Timestamp of previous frame (`mulle_absolutetime_t`)

#### `@interface CAAnimation`
- **Purpose:** Base class implementing core animation timing and lifecycle
- **Inherits From:** `NSObject`
- **Lifecycle Functions:**
  - `+animationWithAnimationOptions:` / `-initWithAnimationOptions:` - Create animation with timing configuration
  - `CAAnimationStart()` - C function to start an animation with given time and rate
  - `CAAnimationComputeFrameInfo()` - Pure math function to compute frame info without side effects; returns `struct CAAnimationFrameInfo`
  - `CAAnimationDidAnimate()` - C function to finalize animation frame processing; returns `BOOL`
- **Class Methods:**
  - `+animateObjects:absoluteTime:animationRate:` - Batch animate a `mulle_pointerarray` of objects; returns `BOOL`
- **Core Operations:**
  - `-animateObject:absoluteTime:animationRate:` - Primary animation tick method; returns `NSUInteger` (CAAnimationReturnState)
  - `-animateObject:animationFrameInfo:` - Subclasses override this to perform interpolation
  - `-animationIndexDidChange` - Called when animation crosses a repeat boundary
  - `-hasEnded` - Returns `YES` if animation has completed
- **Properties:**
  - `debuggingFlags` - Thread-safe debugging flags (`assign`, `NSUInteger`)
  - `removedOnCompletion` - Whether animation is removed when done (`BOOL`)
  - `animationObject` - The object being animated (retained, `id`)
  - `delegate` - Animation delegate (assigned, **not retained**, unlike Apple's implementation)
  - `finishedInvocation` - `NSInvocation` triggered when animation finishes (retained); alternative to delegate
  - `animationFunction` - Custom C function pointer for animation effects (assigned, `CAAnimationFunction_t *`)

### 3.2. `CABasicAnimation.h`

#### `@interface CABasicAnimation`
- **Purpose:** Interpolates a single property between start and end values over time
- **Inherits From:** `CAAnimation`
- **Readonly Properties:**
  - `start` / `end` - Union storing animation start/end values (`union CAAnimationValue`)
  - `property` - Runtime property descriptor (`struct _mulle_objc_property *`)
  - `tween` - Tween function pointer (`CATweenFunction *`)
  - `quadratic` - Built-in cubic bezier curve (`CACubic`)
  - `valueType` - Type of value being animated (`CAAnimationValueType`)
- **Query Methods:**
  - `-isAdditive` - Returns `YES` if animation uses additive blending
  - `-isCumulative` - Returns `YES` if cumulative mode is enabled

#### `enum CAAnimationValueType`
- **Purpose:** Identifies the type of value being animated
- **Values:**
  - `CAAnimationValueBOOL` - Boolean values
  - `CAAnimationValueNSInteger` - Signed integers
  - `CAAnimationValueNSRange` - NSRange structures
  - `CAAnimationValueCGFloat` - Single float
  - `CAAnimationValueCGFloat2` / `CAAnimationValueCGPoint` / `CAAnimationValueCGSize` / `CAAnimationValueCACircle` - Two floats
  - `CAAnimationValueCGFloat4` / `CAAnimationValueCGRect` / `CAAnimationValueEdgeInsets` / `CAAnimationValueCornerInsets` - Four floats
  - `CAAnimationValueFloatArray` - Dynamic float arrays (`struct mulle__floatarray`)
  - `CAAnimationValueObject` - Objects conforming to `CAInterpolatableValue`

#### `enum CAAnimationCurve`
- **Purpose:** Predefined timing curve types
- **Values:**
  - `CAAnimationCurveEaseInOut`, `CAAnimationCurveEaseIn`, `CAAnimationCurveEaseOut`, `CAAnimationCurveLinear`
  - `CAAnimationCurveEaseInQuadratic`, `CAAnimationCurveEaseOutQuadratic`, `CAAnimationCurveEaseInOutQuadratic`
  - `CAAnimationCurveEaseInCubic`, `CAAnimationCurveEaseOutCubic`, `CAAnimationCurveEaseInOutCubic`
  - `CAAnimationCurveEaseInQuartic`, `CAAnimationCurveEaseOutQuartic`, `CAAnimationCurveEaseInOutQuartic`
  - `CAAnimationCurveEaseInQuintic`, `CAAnimationCurveEaseOutQuintic`, `CAAnimationCurveEaseInOutQuintic`
  - `CAAnimationCurveEaseInSine`, `CAAnimationCurveEaseOutSine`, `CAAnimationCurveEaseInOutSine`
  - `CAAnimationCurveEaseInExponential`, `CAAnimationCurveEaseOutExponential`, `CAAnimationCurveEaseInOutExponential`
  - `CAAnimationCurveEaseInCircular`, `CAAnimationCurveEaseOutCircular`, `CAAnimationCurveEaseInOutCircular`
  - `CAAnimationCurveEaseInBack`, `CAAnimationCurveEaseOutBack`, `CAAnimationCurveEaseInOutBack`
  - `CAAnimationCurveEaseInBounce`, `CAAnimationCurveEaseOutBounce`, `CAAnimationCurveEaseInOutBounce`
  - `CAAnimationCurveEaseInElastic`, `CAAnimationCurveEaseOutElastic`, `CAAnimationCurveEaseInOutElastic`
- **Helper Functions:**
  - `CACubicForAnimationCurve( curvetype)` - Get cubic bezier for legacy curve types
  - `CATweenForAnimationCurve( curvetype)` - Get tween function for advanced curve types
  - `CAAnimationCurveUTF8String( curve)` - String representation

#### `struct CABasicAnimationOptions`
- **Purpose:** Extended options including timing curve configuration
- **Key Fields:**
  - `base` - Base `CAAnimationOptions` structure
  - `curve` - Predefined curve type (`CAAnimationCurve`)
  - `tween` - Custom tween function pointer (`CATweenFunction *`)
- **Convenience Constructors:**
  - `CABasicAnimationOptionsMake( base, curve, tween)` - Full constructor
  - `CABasicAnimationOptionsMakeCurve( timeRange, curve, repeatCount, reverses)` - Curve-based
  - `CABasicAnimationOptionsMakeTween( timeRange, tween, repeatCount, reverses)` - Tween-based
  - `CABasicAnimationOptionsMakeLinear( timeRange, repeatCount, reverses)` - Linear
  - `CABasicAnimationOptionsMakeEaseInOut( timeRange, repeatCount, reverses)` - Ease-in-out
  - `CABasicAnimationOptionsMakeEaseIn( timeRange)` - Ease-in with defaults
  - `CABasicAnimationOptionsMakeEaseOut( timeRange)` - Ease-out with defaults

#### Factory Methods (Type-Specific)
- `+animationWithProperty:valueType:valueRange:options:` - Generic
- `+animationWithProperty:startRectValue:endRectValue:options:` - CGRect
- `+animationWithProperty:startEdgeInsetsValue:endEdgeInsetsValue:options:` - MulleEdgeInsets
- `+animationWithProperty:startSizeValue:endSizeValue:options:` - CGSize
- `+animationWithProperty:startPointValue:endPointValue:options:` - CGPoint
- `+animationWithProperty:startFloatValue:endFloatValue:options:` - CGFloat
- `+animationWithProperty:startFloat2Value:endFloat2Value:options:` - CGFloat2
- `+animationWithProperty:startFloat4Value:endFloat4Value:options:` - CGFloat4
- `+animationWithProperty:startFloatArrayValue:endFloatArrayValue:options:` - Float Array
- `+animationWithProperty:startObjectValue:endObjectValue:options:` - Object
- `+animationWithProperty:startRangeValue:endRangeValue:options:` - NSRange
- `+animationWithProperty:startIntegerValue:endIntegerValue:options:` - NSInteger
- `+animationWithProperty:startBOOLValue:endBOOLValue:options:` - BOOL
- All factory methods have matching `-initWithProperty:start...:end...:options:` initializers

#### `@protocol CAInterpolatableValue`
- **Purpose:** Protocol for custom objects that can be animated (inherits `NSCopying`, `NSObject`)
- **Required Methods:**
  - `-interpolateTo:factor:additive:` - Standard or additive interpolation
  - `-interpolatedValueWithDiff:previousDiff:` - Additive mode with diff accumulation (previous is nil on first call)

#### Interpolation Macros
- **`CAInterpolate(start, end, x)`** - Standard linear: `start + (end - start) * x`
- **`CAInterpolateAdditive(start, end, x)`** - Additive: `(end - start) * x`

#### Public Functions
- `CAArrayIndexForInterpolation( startLength, length, mode)` - Compute array index for given length and mode; returns `NSInteger`
- `CAInterpolatedArrayIndex( startLength, endLength, x, mode)` - Compute interpolated array index between two lengths; returns `NSInteger`
- `CABasicAnimationSetInterpolatedFloatAdditive()`, `CABasicAnimationSetInterpolatedFloat2Additive()`, `CABasicAnimationSetInterpolatedFloat4Additive()` - Inline interpolation helpers
- `CABasicAnimationAnimateObject( self, object, x)` - Inline standard interpolation
- `CABasicAnimationAnimateObjectAdditive( self, object, x)` - Inline additive interpolation

#### Extension Interface
- **`struct CABasicAnimationTypeDefinition`** - Register custom value types
  - `type` - Type identifier (`NSUInteger`)
  - `name` - C string name
  - `interpolate` / `interpolateAdditive` - Interpolation function pointers (`CABasicAnimationInterpolator_t *`)
  - `valueUTF8String` - Debug string function (`CAAnimationValueUTF8Printer`)
- **`CABasicAnimationTypeDefinitionRegister( definition)`** - Call in `+initialize`
- **`CABasicAnimationTypeDefinitionGet( type)`** - Retrieve type definition (nonnull return)

### 3.3. `CAAnimationSequence.h`

#### `@interface CAAnimationSequence`
- **Purpose:** Runs child animations sequentially by managing their delays. When an animation is added, its delay is set to the current end time of the sequence. Internally all children run in parallel via `CAAnimationStorage` — sequencing is achieved purely through staggered delays.
- **Inherits From:** `CAAnimation`
- **Implements:** `CAAnimationStorageObject`
- **Key Ivars:**
  - `_animationStorage` - Storage for child animations
  - `_animationID` - C string identifier for the sequence
  - `_animationContext` - User-defined context pointer
- **Properties:**
  - `animationContext` - User-defined context pointer (assign, `void *`)
- **Animation Management:**
  - `-setAnimationID:` / `-animationID` - Set/get string identifier (uses `strcpy`); returns `char *`
  - `-addAnimation:` - Append to end of sequence; sets removedOnCompletion to NO (sequence owns child lifecycle); delay = current sequence end time
  - `-insertAnimation:beforeAnimation:` - Splice before reference; new animation gets reference's delay; reference and subsequent shift forward
  - `-insertAnimation:afterAnimation:` - Splice after reference; new animation's delay = reference's end time; subsequent shift forward
  - `-removeAnimation:` - Remove and close the gap; subsequent animations shift backward
  - `-addPause:` - Add a no-op pause of given duration (`mulle_relativetime_t`) to the sequence
- **Query:**
  - `-sequenceDuration` - Computed: max(delay[i] + duration[i] * repeatCount[i]) across all children; returns `mulle_relativetime_t`
- **Factory:**
  - `+sequenceAnimation` - Creates an auto-sizing sequence; duration is computed from children when animation starts

### 3.4. `CAAnimationGroup.h`

#### `@interface CAAnimationGroup`
- **Purpose:** Container for multiple animations that run in parallel, typically created by `CATransaction`. Overrides `addAnimation:` so children are NOT delayed — they all start at the same time.
- **Inherits From:** `CAAnimationSequence`
- **Properties (forwarded to child animations):**
  - `animationDelay` - Timing for child animations (`mulle_relativetime_t`)
  - `animationDuration` - Duration for child animations (`mulle_relativetime_t`)
  - `animationOffset` - Offset for child animations (`mulle_relativetime_t`)
  - `animationRepeatCount` - Repeat count for child animations (`float`)
  - `animationCurve` - Timing curve enum for child animations (`NSUInteger`)
  - `animationTweenFunction` - Custom tween function for child animations (`CATweenFunction *`)
  - `animationAutoreverses` - Whether child animations auto-reverse (`BOOL`)
  - `animationIsAdditive` - Whether child animations are additive (`BOOL`)
- **Methods:**
  - `-addAnimation:` - Adds animation to run in parallel (no delay computation); sets removedOnCompletion to NO
- **Categories:**
  - `CAAnimationGroup(CAAnimationOptions)` - `-setupAnimationOptions:` for configuring base options
  - `CAAnimationGroup(CABasicAnimationOptions)` - `-setupBasicAnimationOptions:` for configuring basic animation options

### 3.5. `CAAnimationStorage.h`

#### `struct CAAnimationStorage`
- **Purpose:** Internal storage structure for animation collections
- **Key Fields:**
  - `_numberOfAnimations` - Cached count (`NSUInteger`)
  - `_animations` - `struct mulle_pointerarray` of `CAAnimation` pointers

#### `@mixin CAAnimationStorageObject`
- **Purpose:** Protocolclass providing animation storage and management capabilities
- **Required Method:**
  - `-animationStorage` - Returns pointer to storage structure (`struct CAAnimationStorage *`)

#### Optional Methods
- **Lifecycle:** `-initAnimationStorage` (call in `-init`), `-deallocAnimationStorage` (call in `-dealloc`)
- **Query:** `-hasAnimations`, `-numberOfAnimations`, `-hasRunningAnimations`, `-hasLayoutChangingAnimations`
- **Management:** `-addAnimation:`, `-removeAnimation:`, `-resetAllAnimations`, `-removeAllAnimations`, `-resetAnimationsForAnimationObject:`, `-removeAnimationsForAnimationObject:`
- **Selective Operations:**
  - `-finishAnimationsWithAnimationID:` - Jump to final value for all animations matching the given `char *` ID
  - `-cancelAnimationsWithAnimationID:` - Revert to start value for all animations matching the given `char *` ID
  - `-getAnimations:maxCount:animationID:animationObject:` - Query animations matching criteria; either filter may be `NULL`/nil to skip; if `maxCount` is 0, returns count without writing; returns `NSUInteger`
- **Execution:** `-animateWithAbsoluteTime:animationRate:` - Animate all stored animations; returns `BOOL`
- **Debug/Thread Safety:**
  - `-_numberOfAnimationsWithStateBitsSet:stateBitsCleared:` - Count animations by state bits
  - `-mulleGainAccessToAnimationsWithUniquingSet:` - Thread-safe access acquire
  - `-mulleRelinquishAccessToAnimationsWithUniquingSet:` - Thread-safe access release

#### Convenience Macros
- **`CAAnimationStorageObjectIvars`** - Declares `struct CAAnimationStorage _animationStorage`
- **`CAAnimationStorageObjectProperties`** - Empty (no additional properties)
- **`CAAnimationStorageObjectInterface`** - Declares `-animationStorage` method
- **`CAAnimationStorageObjectImplementation`** - Implements `-animationStorage` returning `&_animationStorage`
- **`CAAnimationStorageObjectCopy(dst, src)`** - Copies animation storage between objects (for `NSCopying`)

### 3.6. `CAAnimator.h`

#### `@interface CAAnimator`
- **Purpose:** Container and executor for multiple animations. Stores animations via `CAAnimationStorageObject` and when asked to animate, animates them. `CAAnimationGroup` objects (created by `CATransaction`) are also stored as `CAAnimation` instances.
- **Inherits From:** `NSObject`
- **Implements:** `CAAnimationStorageObject`
- **Key Ivar:**
  - `_animationStorage` - Storage for animation collection
- **Core Methods:**
  - `-animationStorage` - Returns pointer to storage structure
  - `-animateWithAbsoluteTime:animationRate:` - Inherited from `CAAnimationStorageObject` mixin; returns `YES` if any animations are still running
  - `-getAnimations:maxCount:animationID:animationObject:` - Inherited from `CAAnimationStorageObject` mixin
- **Query Methods:**
  - `-numberOfActiveAnimations` - Count of animations that exist
  - `-numberOfRunningAnimations` - Count of currently animating
  - `-numberOfFinishedAnimations` - Count of completed animations

### 3.7. `CATransaction.h`

#### `@interface CATransaction`
- **Purpose:** Generates implicit animations for observable property changes
- **Thread Safety:** Thread-local via `CATransactionGetCurrentTransaction()`
- **Key Ivars:**
  - `_animatedObjects` - Array of objects with property changes (not retained, `struct mulle_pointerarray`)
  - `_animationGroup` - Group collecting generated animations (retained, `CAAnimationGroup *`)
- **Property:**
  - `state` - `CATransactionState` enum (readonly): `CATransactionIdle`, `CATransactionStarted`, `CATransactionCommitting`

#### Lifecycle Methods
- `-begin` - Start transaction, enables animation generation
- `-commit` - End transaction, generate animations, returns `CAAnimationGroup *`
- `-reset` - Clear transaction state
- `-areAnimationsEnabled` - Query if transaction is active

#### Object Management
- `-addAnimatableObject:` - Register object with property changes
- `-removeAnimatableObject:` - Unregister object (use via `-forgetImplicitAnimations`)

#### Forwarded Properties (to animation group)
- Delegate: `animationDelegate` (id), `animationContext` (`void *`), `animationID` (`char *`)
- Timing: `animationDelay`, `animationOffset`, `animationDuration` (all `mulle_relativetime_t`), `animationRepeatCount` (`float`)
- Curve: `animationCurve` (`NSUInteger`), `animationTweenFunction` (`CATweenFunction *`), `animationAutoreverses` (`BOOL`)
- Mode: `animationIsAdditive` (`BOOL`)
- Methods: `-setAnimationID:` / `-animationID` - Forwarded to group

#### Global Functions
- **`CATransactionGetCurrentTransaction()`** - Get thread-local transaction
- **`CATransactionSetCurrentTransaction()`** - Set thread-local transaction

#### Macros
- **`CATransactionSuspendedDo(name)`** - Execute block with transaction temporarily suspended; disables implicit animation generation within the block
- **`CATransactionDo(ta, group)`** - Begin/commit a transaction; `group` variable receives the returned `CAAnimationGroup *`

### 3.8. `CAImplicitlyAnimatableObject.h`

#### `@mixin CAImplicitlyAnimatableObject`
- **Purpose:** Mixin for objects that support implicit animation via `CATransaction`
- **Inherits:** `MullePropertyObserving`
- **Required Property:** `snapshot` - Stores pre-transaction property values (retained, dynamic, `id`)
- **Required Method:** `-generateAnimationsForPropertiesWithSnapshot:animationGroup:` - Create animations by comparing current values to snapshot
- **Optional Methods:**
  - `-observablePropertiesSnapshot` - Create snapshot of observable properties
  - `-willChange` - Called before observable property changes (from `MullePropertyObserving`)
  - `-commitImplicitAnimations:` - Finalize implicit animations
  - `-forgetImplicitAnimations` - Discard uncommitted animations

#### Convenience Macros
- **`CAImplicitlyAnimatableObjectIvars`** - Declares `id _snapshot`
- **`CAImplicitlyAnimatableObjectInterface`** - Declares `@property(retain) id snapshot`
- **`CAImplicitlyAnimatableObjectImplementation`** - Empty implementation (for protocol conformance)

#### Important Notes
- **Observable Properties:** Only properties marked `observable` generate implicit animations
- **Supported Types:** id, NSInteger, CGFloat, CGPoint, CGRect, CGSize, CAPolarPoint, CACircle, MulleCornerInsets, MulleEdgeInsets, NSRange, mulle_range
- **NOT Supported:** BOOL, unsigned types, short, int, char, long, long long, long double, pointer types, unions

### 3.9. `CALayer.h`

#### `@interface CALayer`
- **Purpose:** Basic layer class for layout geometry and animation, base for rendering layers
- **Inherits:** `MulleObject`
- **Implements:** `MulleAutolockingObjectProtocols`, `NSCopying`, `CAImplicitlyAnimatableObject`, `CAAnimationStorageObject`
- **Key Ivars:** `_animationStorage` (via `CAAnimationStorageObjectIvars`), `_atomicNameUTF8String` (`mulle_atomic_pointer_t`)

#### Observable Properties (animatable)
- `opacity` (CGFloat), `frame` (CGRect), `bounds` (CGRect), `canvas` (CGRect)

#### Non-Observable / UIView-Managed Properties
- `masksToBounds` (BOOL), `transform` (CGAffineTransform, do not touch), `clipRect` (CGRect, do not touch), `alpha` (CGFloat, do not touch)
- `frameTracking` - Bitfield controlling bounds/canvas tracking (`CALayerCanvasSizeTracksFrameSize = 0x1`, `CALayerBoundsSizeTracksFrameSize = 0x2`)
- `tag` (NSInteger), `hidden` (BOOL), `nameUTF8String` (dynamic, `char *`), `debuggingFlags` (thread-safe, `NSUInteger`)

#### Factory Methods
- `+layer` - Create layer with zero frame
- `+layerWithFrame:` - Create layer with specified frame

#### Initializers
- `-initWithFrame:` - Initialize with frame rectangle

#### Methods
- `-layoutWithLayoutInfo:` - Perform layout with given `struct UILayoutInfo *`
- `-dumpWithIndent:FILE:` - Debug dump layer hierarchy

### 3.10. `NSObject+CAAnimation.h`

#### `@interface NSObject(CAAnimation)`
- **Purpose:** Category providing default implicit animation generation for object properties
- **Method:** `-generateAnimationsForPropertiesWithSnapshot:animationGroup:` - Default implementation for implicit animation generation

#### `@interface NSObject(CAAnimation_Forward)`
- **Purpose:** Category for creating custom animations for value objects
- **Method:** `+animationFrom:to:property:options:` - Class method for custom animation creation (alternative to `CAInterpolatableValue` protocol)

#### `struct CAPropertyAnimationContext`
- **Purpose:** Context structure passed to custom property animators
- **Key Fields:** `self` (`id`), `snapshot` (`id`), `animationGroup` (`CAAnimationGroup *`), `animationOptions` (`struct CABasicAnimationOptions`), `flags` (`NSUInteger`)

#### Extension Interface
- **`struct CAAnimationPropertyDefinition`** - Register custom property type handlers
  - `matchRuntimeStructName` - Function to match property type signature; returns `BOOL`
  - `animateProperty` - Function to create animation for property
- **`CAAnimationPropertyDefinitionRegister( p)`** - Register custom property handler
- **`CAPropertyAnimationContextAddAnimation( ctx, animation)`** - Add animation to context

### 3.11. `CAPathAnimation.h`

#### `@interface CAPathAnimation`
- **Purpose:** Animates a property along a `CGPath`, sampling position, tangent, normal, or derived values
- **Inherits From:** `CABasicAnimation`
- **Properties:**
  - `path` - The path to animate along (assign, `CGPath *`)
  - `pathValueType` - What to sample from the path (assign, `CAPathAnimationValueType`)

#### `enum CAPathAnimationValueType`
- **1D values (CGFloat):** `CAPathAnimationValueRotation`, `CAPathAnimationValueAngle`, `CAPathAnimationValueTangentAngle`, `CAPathAnimationValueXPosition`, `CAPathAnimationValueYPosition`, `CAPathAnimationValueDistance`
- **2D values (CGFloat2):** `CAPathAnimationValuePosition`, `CAPathAnimationValueNormal`, `CAPathAnimationValueTangent`, `CAPathAnimationValuePositionPlusNormal`
- **CGRect values:** `CAPathAnimationValuePose`, `CAPathAnimationValuePositionAsOrigin`, `CAPathAnimationValuePositionAsSize`

#### Factory / Initializer
- `+pathAnimationWithProperty:path:pathValueType:options:` - Factory
- `-initWithProperty:path:pathValueType:options:` - Designated initializer

#### Helper Function
- `CAPathAnimationGetAnimationValueType( pathValueType)` - Get the `CAAnimationValueType` for a given path value type

### 3.12. `CGGeometry+MulleObjC.h` and `MulleEdgeInsets+MulleObjC.h`

#### Purpose
- MulleCA-specific geometry extensions for CGFloat-based types
- Utility functions for setting/getting geometry values via `mulle_objc_object_call`:
  - `MulleObjectSetBOOL` / `MulleObjectGetBOOL`
  - `MulleObjectSetNSInteger` / `MulleObjectGetNSInteger`
  - `MulleObjectSetNSRange` / `MulleObjectGetNSRange`
  - `MulleObjectSetCGFloat` / `MulleObjectGetCGFloat`
  - `MulleObjectSetCGFloat2` / `MulleObjectGetCGFloat2`
  - `MulleObjectSetCGFloat4` / `MulleObjectGetCGFloat4`
  - `MulleObjectSetCGRect` / `MulleObjectGetCGRect`
  - `MulleObjectSetCGSize` / `MulleObjectGetCGSize`
  - `MulleObjectSetCGPoint` / `MulleObjectGetCGPoint`
  - `MulleObjectSetObject` / `MulleObjectGetObject`
  - `MulleObjectSetEdgeInsets` / `MulleObjectGetEdgeInsets`
  - `MulleObjectSetCornerInsets` / `MulleObjectGetCornerInsets`
  - `MulleObjectSetCACircle` / `MulleObjectGetCACircle`
  - `MulleObjectSetCAPolarPoint` / `MulleObjectGetCAPolarPoint`
- **Debug:** `CAPoseUTF8String( value)` - String representation of a `CAPose` value

### 3.13. `MulleCA.h`

- **Purpose:** Umbrella header for the entire MulleCA library
- **Defines:** `MULLE_CA_VERSION` macro (`((0 << 20) | (0 << 8) | 1)`)
- **Includes:** Export and provide headers, optional version check

## 4. Performance Characteristics

**Animation Execution:** `O(n)` where n is the number of active animations. Each animation is evaluated independently per frame.

**Storage Operations:** Adding/removing animations is `O(1)` amortized using `mulle_pointerarray`. Lookups by ID or object are `O(n)`.

**Sequence Splice/Insert:** `O(n)` due to delay recalculation of subsequent animations.

**Interpolation:** Most interpolation operations are `O(1)` (arithmetic). Object-based interpolation (`CAInterpolatableValue`) depends on object implementation. Path animations require path sampling which may involve curve evaluation.

**Memory:** Each `CABasicAnimation` stores start/end values (typically 8-32 bytes), property pointer, timing info (~64 bytes total). `CAAnimationStorage` uses dynamic pointer array with growth strategy.

**Thread Safety:** Animations are **not thread-safe** by default. Access to CALayer animations should be serialized through the UIView's lock. `CATransaction` is thread-local. Certain properties (`debuggingFlags`) are marked `MULLE_OBJC_THREADSAFE_PROPERTY`.

**Frame Rate Independence:** Animations use absolute time (`mulle_absolutetime_t`) making them frame-rate independent. Optional `animationRate` parameter enables frame quantization for consistent final values at discrete refresh rates (e.g., 60 Hz).

## 5. AI Usage Recommendations & Patterns

### Best Practices

**Lifecycle Management:** Always use factory methods or explicit initializers. For objects that need animations, include `CAAnimationStorageObject` mixin and call `-initAnimationStorage` in `-init` and `-deallocAnimationStorage` in `-dealloc`. For implicit animations, include `CAImplicitlyAnimatableObject` mixin and mark properties as `observable`.

**Property Access:** Use `MulleObjCInstanceSearchProperty(object, @selector(propertyName))` to obtain property descriptors at runtime for animation creation. Cache property pointers if creating many animations for the same property.

**Options Configuration:** Pass `NULL` for options to get default values (delay=0, duration=1, repeatCount=1). Use convenience constructors like `CABasicAnimationOptionsMakeLinear()` or `CABasicAnimationOptionsMakeEaseInOut()`. Set flags with `CABasicAnimationOptionsSetBit(&options, CAAnimationAdditive)`.

**Animation Timing:** Specify time in seconds using `mulle_relativetimerange_make(delay, duration)`. Use `INFINITY` for `repeatCount` to loop forever. Set `animationRate` to `1.0/fps` (e.g., `1.0/60.0`) for quantized animations; use `0.0` for continuous interpolation.

**Additive Animations:** Set `CAAnimationAdditive` flag to allow multiple animations to blend on the same property. This adds interpolated differences rather than replacing values. Combine with `CAAnimationCumulative` to accumulate values across repeat cycles.

**Implicit Animations:** Wrap property modifications in `CATransaction` begin/commit blocks. Transaction generates animations automatically for `observable` properties. Set transaction properties (duration, curve, etc.) before modifying object properties, or use the `CATransactionDo(ta, group)` macro.

**Sequential Animations:** Use `CAAnimationSequence` for choreographed multi-step animations. Add animations with `-addAnimation:` (they queue sequentially). Use `-addPause:` for delays between steps. Use `-insertAnimation:beforeAnimation:` / `-insertAnimation:afterAnimation:` for splicing.

**Animation Identification:** Set `animationID` on `CAAnimationSequence` or `CAAnimationGroup` to identify animation "kinds." Use `-finishAnimationsWithAnimationID:` and `-cancelAnimationsWithAnimationID:` on any `CAAnimationStorageObject` to selectively complete or undo specific animation subsets.

**Stop Semantics:** Use `-finish` to jump animations to their end values (e.g., when a view is being removed). Use `-interrupt` to stop at current values (user cancels an action). Use `-cancel` to revert to start values (undo an action). Use `-reset` to replay an animation from the start.

**Batch Animation:** Use `+animateObjects:absoluteTime:animationRate:` on `CAAnimation` to animate a `mulle_pointerarray` of objects in a single frame step.

### Common Pitfalls

**Direct Field Access:** Never directly access internal fields prefixed with `_`. Use property accessors or documented API methods.

**Memory Management:** Unlike Apple's CoreAnimation, `delegate` property is **not retained**. Ensure delegate outlives the animation. `animationObject` **is** retained.

**Boolean Animations:** Use `CAAnimationValueBOOL` with start=NO, end=YES. Booleans interpolate as discrete values (flip at t=0.5).

**Unsigned Types:** NSUInteger and other unsigned types are not directly supported. Cast to NSInteger or use custom interpolation.

**Transform Properties:** Do not animate `transform`, `clipRect`, or `alpha` on `CALayer` directly — these are managed by UIView. Animate `frame`, `bounds`, `opacity` instead.

**Repeat and Reverse:** `CAAnimationReverses` requires `repeatCount > 1` to take effect. With `autoreverses=YES` and `repeatCount=2`, you get a full out-and-back cycle. With `repeatCount=1` and autoreverses, the animation only goes forward (no reversal occurs).

**Transaction Lifecycle:** Don't retain or copy `CATransaction` objects — they are short-lived. Don't call `-commit` twice on the same transaction.

**Path Animation Properties:** Ensure the property type matches `pathValueType` (e.g., CGFloat for rotation, CGPoint for position, CGRect for pose).

**Group vs Sequence:** `CAAnimationGroup` descends from `CAAnimationSequence` but overrides `addAnimation:` to place children at the same start time (no delay computation). Both use the standard `CAAnimation` delegate protocol (the old group-specific delegate properties are gone).

### Idiomatic Usage

**Animation Loop Pattern:** Create `CAAnimator`, add animations, then repeatedly call `-animateWithAbsoluteTime:animationRate:` in your render loop, passing current timestamp and frame rate.

**Reusing Animations:** Call `-init...` methods again on existing animation objects to reconfigure them without reallocation.

**Custom Value Types:** Implement `CAInterpolatableValue` protocol on custom objects, or register a `CABasicAnimationTypeDefinition` for new primitive types.

**Debugging:** Set `debuggingFlags` property and use `CAAnimationBitsUTF8String()`, `CAAnimationOptionsUTF8String()`, `CABasicAnimationOptionsUTF8String()`, `CAAnimationValueUTF8String()`, and `CAAnimationValueRangeUTF8String()` for debug output.

**Suspending Transactions:** Use `CATransactionSuspendedDo(name)` macro to temporarily disable implicit animation generation within a block.

## 6. Integration Examples

### Example 1: Creating and Running a Basic Integer Animation

```c
#import <MulleCA/MulleCA.h>

@interface Counter : NSObject
@property NSInteger   count;
@end

@implementation Counter
- (void) setCount:(NSInteger) value
{
   _count = value;
   printf( "%td\n", value);
}
@end

int   main( void)
{
   CAAnimator                       *animator;
   CABasicAnimation                 *animation;
   Counter                          *counter;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;
   mulle_absolutetime_t             t;

   counter  = [Counter object];
   property = MulleObjCInstanceSearchProperty( counter, @selector( count));

   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0.0, 2.0),
                                                  1.0,
                                                  NO);

   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:0
                                           endIntegerValue:100
                                                   options:&options] autorelease];
   [animation setAnimationObject:counter];

   animator = [CAAnimator object];
   [animator addAnimation:animation];

   for( t = 0.0; t <= 2.0; t += 0.1)
      [animator animateWithAbsoluteTime:t
                          animationRate:0.0];

   return( 0);
}
```

### Example 2: Using CATransaction for Implicit Animations

```c
#import <MulleCA/MulleCA.h>

@interface Box : NSObject <CAImplicitlyAnimatableObject>
{
   CAImplicitlyAnimatableObjectIvars;
}

@property( observable) CGRect   frame;

CAImplicitlyAnimatableObjectInterface;
@end

@implementation Box
CAImplicitlyAnimatableObjectImplementation;
@end

int   main( void)
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;
   Box                *box;

   box = [Box object];
   [box setFrame:CGRectMake( 0, 0, 100, 100)];

   transaction = [CATransaction object];
   [transaction begin];
   {
      [transaction setAnimationDuration:1.0];
      [transaction setAnimationCurve:CAAnimationCurveEaseInOut];
      [box setFrame:CGRectMake( 200, 200, 150, 150)];
   }
   group = [transaction commit];

   // group now contains animation for frame property
   printf( "Generated %td animations\n", [group numberOfAnimations]);

   return( 0);
}
```

### Example 3: Additive Animation with Repeat

```c
#import <MulleCA/MulleCA.h>

@interface Oscillator : NSObject
@property CGFloat   position;
@end

@implementation Oscillator
- (void) setPosition:(CGFloat) value
{
   _position = value;
   printf( "%.2f\n", value);
}
@end

int   main( void)
{
   CABasicAnimation                 *animation;
   Oscillator                       *osc;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;
   NSInteger                        i;

   osc      = [Oscillator object];
   [osc setPosition:50.0];  // initial center position

   property = MulleObjCInstanceSearchProperty( osc, @selector( position));

   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0.0, 1.0),
                                                  3.0,
                                                  YES);  // autoreverse
   CABasicAnimationOptionsSetBit( &options, CAAnimationAdditive);

   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startFloatValue:-10.0
                                             endFloatValue:10.0
                                                   options:&options] autorelease];

   for( i = 0; i <= 12; i++)
   {
      [animation animateObject:osc
                  absoluteTime:i / 4.0
                 animationRate:0.0];
   }

   return( 0);
}
```

### Example 4: Animation Sequence with Pauses

```c
#import <MulleCA/MulleCA.h>

@interface Mover : NSObject
@property CGPoint   position;
@end

@implementation Mover
- (void) setPosition:(CGPoint) value
{
   _position = value;
   printf( "(%.1f, %.1f)\n", value.x, value.y);
}
@end

int   main( void)
{
   CAAnimationSequence              *sequence;
   CABasicAnimation                 *anim1;
   CABasicAnimation                 *anim2;
   CAAnimator                       *animator;
   Mover                            *mover;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;
   mulle_absolutetime_t             t;

   mover    = [Mover object];
   property = MulleObjCInstanceSearchProperty( mover, @selector( position));

   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1.0),
                                                 1.0,
                                                 NO);

   // Create "move right"
   anim1 = [[[CABasicAnimation alloc] initWithProperty:property
                                       startPointValue:CGPointMake( 0, 0)
                                         endPointValue:CGPointMake( 100, 0)
                                               options:&options] autorelease];
   [anim1 setAnimationObject:mover];

   // Create "move down"
   anim2 = [[[CABasicAnimation alloc] initWithProperty:property
                                       startPointValue:CGPointMake( 100, 0)
                                         endPointValue:CGPointMake( 100, 100)
                                               options:&options] autorelease];
   [anim2 setAnimationObject:mover];

   sequence = [CAAnimationSequence sequenceAnimation];
   [sequence addAnimation:anim1];
   [sequence addPause:0.5];      // half-second pause between movements
   [sequence addAnimation:anim2];

   animator = [CAAnimator object];
   [animator addAnimation:sequence];

   for( t = 0.0; t <= 3.0; t += 0.1)
      [animator animateWithAbsoluteTime:t animationRate:0.0];

   return( 0);
}
```

### Example 5: Selective Finishing by Animation ID

```c
#import <MulleCA/MulleCA.h>

int   main( void)
{
   CAAnimationGroup   *old;
   CAAnimationGroup   *new;
   CAAnimator         *animator;

   animator = [CAAnimator object];

   // First transition: animate opacity
   old = [CAAnimationGroup object];
   [old setAnimationID:"transition"];

   // ... add animations to old group ...
   [animator addAnimation:old];

   // Later: a new transition replaces the old one
   // Finish only "transition" animations (jump to end values),
   // then start the new ones
   [animator finishAnimationsWithAnimationID:"transition"];
   [animator removeAllAnimations];

   new = [CAAnimationGroup object];
   [new setAnimationID:"transition"];
   // ... add new animations ...
   [animator addAnimation:new];

   return( 0);
}
```

## 7. Dependencies

MulleCA directly depends on the following mulle-sde libraries:

- **MulleUIBase** - Base UI types including MulleEdgeInsets, MulleCornerInsets, MulleObject, MulleAutolockingObjectProtocols, MullePropertyObserving, MulleObjCForwarding, CGPath, CGPoint, CGRect, CGSize, CGAffineTransform, CACubic, CATweenFunction, CGFloat2, CGFloat4, and mulle-gfx transitively
- **mulle-objc-list** - Objective-C runtime information tool (build-time only: no-all-load, no-bequeath, no-cmake-inherit, no-header, no-link, no-singlephase)
