# MulleCA Library Documentation for AI
<!-- Keywords: animation, properties, real-time, interpolation, timing, transactions, layers -->

## 1. Introduction & Purpose

MulleCA is a real-time property animation library for mulle-objc that enables smooth interpolation of object property values over time. It provides a comprehensive animation system for animating NSInteger, CGFloat, CGPoint, CGRect, CGSize, NSRange, BOOL, CGColor, and custom interpolatable objects. The library supports both explicit animations (via `CABasicAnimation` and `CAPathAnimation`) and implicit animations (via `CATransaction`), with features including time delays, durations, repeat counts, auto-reverse, additive blending, cumulative effects, and customizable timing curves. MulleCA differs from Apple's CoreAnimation by directly modifying object properties rather than operating on a presentation tree, making animated values persistent. It is a foundational component of the MulleUI framework, depending on `mulle-gfx`, `MulleUIBase`, and `mulle-objc-list`.

## 2. Key Concepts & Design Philosophy

**Direct Property Mutation**: Unlike Apple's CoreAnimation which operates on a presentation tree, MulleCA animations directly modify the properties of target objects. This means animated values persist and are immediately reflected in the object's state.

**Animation Storage Protocol**: The `CAAnimationStorage` protocolclass provides a standardized way for objects to store and manage animations. Objects like `CAAnimator`, `CAAnimationGroup`, and `CALayer` implement this protocol to hold animation collections.

**Explicit vs Implicit Animations**: MulleCA supports two animation paradigms:
- **Explicit animations**: Created manually using `CABasicAnimation` or `CAPathAnimation`, configured with start/end values, and added to a `CAAnimator` or directly to a `CALayer`
- **Implicit animations**: Generated automatically via `CATransaction` when modifying `observable` properties on objects conforming to `CAImplicitlyAnimatableObject`

**Interpolation and Timing**: Animations interpolate values using timing functions (linear, ease-in, ease-out, ease-in-out) or custom tween functions. The interpolation factor `t` (0.0 to 1.0) represents progress through the animation duration.

**Additive and Cumulative Modes**: Animations can be additive (adding interpolated differences to current values) enabling multiple animations to blend, or cumulative (preserving accumulated values across repeat cycles). This allows for complex animation layering.

**Frame Quantization**: Optional quantization ensures that animations align with discrete frame times (e.g., 60 Hz), guaranteeing accurate final values when `animationRate` is specified.

**Thread-Local Transactions**: `CATransaction` objects operate on a per-thread basis, allowing safe implicit animation generation without global state conflicts.

## 3. Core API & Data Structures

### 3.1. `CAAnimation.h`

#### `@protocol CAAnimation`
- **Purpose:** Core protocol defining the animation contract that all animation types must implement
- **Key Methods:**
  - `-animateObject:absoluteTime:animationRate:` - Advances animation state and returns `CAAnimationReturnState` indicating whether animation is active, animating, or done
  - `-reset` - Resets animation to initial state
  - `-interrupt` - Stops animation at current values
  - `-finish` - Jumps animation to end values
  - `-reverse` - Reverses animation direction (used with `CAAnimationReverses` flag)
  - `-changesLayout` - Returns `YES` if animation affects UIView frame or bounds
- **Key Properties:**
  - `animationObject` - The object being animated (retained)
  - `removedOnCompletion` - Whether animation is automatically removed when finished

#### `struct CAAnimationOptions`
- **Purpose:** Configuration structure for animation timing and behavior
- **Key Fields:**
  - `timeRange` - Contains `delay` and `duration` (`mulle_relativetimerange`)
  - `offset` - Starting offset into animation cycle (0.0 to 1.0)
  - `repeatCount` - Number of times to repeat animation (use `INFINITY` for endless)
  - `bits` - Flags including `CAAnimationReverses`, `CAAnimationAdditive`, `CAAnimationCumulative`, `CAAnimationQuantize`
- **Helper Functions:**
  - `CAAnimationOptionsMake()` - Create options structure
  - `CAAnimationOptionsSetTimeRange()` - Set delay and duration
  - `CAAnimationOptionsSetOffset()` - Set starting offset
  - `CAAnimationOptionsSetRepeatCount()` - Set repeat count
  - `CAAnimationOptionsSetBit()` / `CAAnimationOptionsClearBit()` - Manipulate option flags

#### `enum CAAnimationBits`
- **Purpose:** Flags controlling animation behavior and state
- **User Options (preserved across resets):**
  - `CAAnimationReverses` - Animation bounces back from end to start (requires repeatCount > 1)
  - `CAAnimationAdditive` - Values are added to object's current value rather than replacing
  - `CAAnimationCumulative` - With additive, values accumulate across repeat cycles
  - `CAAnimationQuantize` - Snap animation to discrete frame boundaries
  - `CAAnimationRateCorrect` - Scale timing according to animation rate
- **Internal State (reset automatically):**
  - `CAAnimationStarted`, `CAAnimationAnimating`, `CAAnimationFinalized`, `CAAnimationEnded`

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
  - `-animationWillStart:` - Called before animation begins
  - `-animationDidStart:` - Called when animation starts animating
  - `-animationDidStop:finished:` - Called when animation stops (finished=YES if completed normally)

#### `struct CAAnimationFrameInfo`
- **Purpose:** Provides temporal information during animation frame processing
- **Key Fields:**
  - `t` - Normalized time (0.0 to 1.0) through current animation cycle
  - `i` - Current animation index (increments with each repeat)
  - `delta` - Time elapsed since previous frame
  - `elapsedTime` - Total time elapsed since animation start

#### `@interface CAAnimation`
- **Purpose:** Base class implementing core animation timing and lifecycle
- **Lifecycle Functions:**
  - `+animationWithAnimationOptions:` / `-initWithAnimationOptions:` - Create animation with timing configuration
  - `CAAnimationStart()` - Function to start an animation with given time and rate
  - `CAAnimationComputeFrameInfo()` - Pure math function to compute frame info without side effects
  - `CAAnimationDidAnimate()` - Function to finalize animation frame processing
- **Core Operations:**
  - `-animateObject:absoluteTime:animationRate:` - Primary animation tick method
  - `-animateObject:animationFrameInfo:` - Subclasses override this to perform interpolation
  - `-animationIndexDidChange` - Called when animation crosses a repeat boundary
  - `-hasEnded` - Returns `YES` if animation has completed
- **Properties:**
  - `delegate` - Animation delegate (not retained, unlike Apple's implementation)
  - `animationFunction` - Custom C function for animation effects
  - `debuggingFlags` - Thread-safe debugging flags

### 3.2. `CABasicAnimation.h`

#### `@interface CABasicAnimation`
- **Purpose:** Interpolates a single property between start and end values over time
- **Key Fields:**
  - `start` / `end` - Union storing animation start/end values (`union CAAnimationValue`)
  - `property` - Runtime property descriptor (`struct _mulle_objc_property *`)
  - `valueType` - Type of value being animated (`CAAnimationValueType`)
  - `tween` - Custom tweening function pointer
  - `quadratic` - Built-in cubic bezier curve (`CACubic`)

#### `enum CAAnimationValueType`
- **Purpose:** Identifies the type of value being animated
- **Built-in Types:**
  - `CAAnimationValueBOOL` - Boolean values
  - `CAAnimationValueNSInteger` - Signed integers
  - `CAAnimationValueNSRange` - NSRange structures
  - `CAAnimationValueCGFloat` - Single float
  - `CAAnimationValueCGFloat2` - Two floats (CGPoint, CGSize, CGVector)
  - `CAAnimationValueCGFloat4` - Four floats (CGRect, MulleEdgeInsets)
  - `CAAnimationValueFloatArray` - Dynamic float arrays
  - `CAAnimationValueObject` - Objects conforming to `CAInterpolatableValue`

#### `struct CABasicAnimationOptions`
- **Purpose:** Extended options including timing curve configuration
- **Key Fields:**
  - `base` - Base `CAAnimationOptions` structure
  - `curve` - Predefined curve type (`CAAnimationCurve`)
  - `tween` - Custom tween function pointer (`CATweenFunction *`)
- **Helper Functions:**
  - `CABasicAnimationOptionsMakeCurve()` - Create options with curve and repeat/reverse
  - `CABasicAnimationOptionsMakeTween()` - Create options with custom tween function
  - `CABasicAnimationOptionsMakeLinear()` - Create linear interpolation options
  - `CABasicAnimationOptionsMakeEaseInOut()` - Create ease-in-out options
  - `CABasicAnimationOptionsMakeEaseIn()` - Create ease-in options
  - `CABasicAnimationOptionsMakeEaseOut()` - Create ease-out options

#### `enum CAAnimationCurve`
- **Purpose:** Predefined timing curve types
- **Values:**
  - `CAAnimationCurveEaseInOut` - Slow start and end, fast middle
  - `CAAnimationCurveEaseIn` - Slow start, fast end
  - `CAAnimationCurveEaseOut` - Fast start, slow end
  - `CAAnimationCurveLinear` - Constant speed

#### Factory Methods (Type-Specific)
- **Purpose:** Convenience constructors for common value types
- **Integer:** `+animationWithProperty:startIntegerValue:endIntegerValue:options:`
- **Float:** `+animationWithProperty:startFloatValue:endFloatValue:options:`
- **CGFloat2:** `+animationWithProperty:startFloat2Value:endFloat2Value:options:`
- **CGFloat4:** `+animationWithProperty:startFloat4Value:endFloat4Value:options:`
- **CGPoint:** `+animationWithProperty:startPointValue:endPointValue:options:`
- **CGSize:** `+animationWithProperty:startSizeValue:endSizeValue:options:`
- **CGRect:** `+animationWithProperty:startRectValue:endRectValue:options:`
- **MulleEdgeInsets:** `+animationWithProperty:startEdgeInsetsValue:endEdgeInsetsValue:options:`
- **NSRange:** `+animationWithProperty:startRangeValue:endRangeValue:options:`
- **BOOL:** `+animationWithProperty:startBOOLValue:endBOOLValue:options:`
- **Object:** `+animationWithProperty:startObjectValue:endObjectValue:options:`
- **Float Array:** `+animationWithProperty:startFloatArrayValue:endFloatArrayValue:options:`

#### Initializer Methods
- **Purpose:** Corresponding initializers for all factory methods (for animation reuse)
- **Pattern:** All factory methods have matching `-initWithProperty:start...:end...:options:` initializers

#### `@protocol CAInterpolatableValue`
- **Purpose:** Protocol for custom objects that can be animated
- **Required Methods:**
  - `-interpolateTo:factor:additive:` - Standard or additive interpolation
  - `-interpolatedValueWithDiff:previousDiff:` - Additive mode with diff accumulation
- **Note:** Objects must also conform to `NSCopying` and `NSObject`

#### Interpolation Macros
- **`CAInterpolate(start, end, x)`** - Standard linear interpolation: `start + (end - start) * x`
- **`CAInterpolateAdditive(start, end, x)`** - Additive interpolation: `(end - start) * x`

#### Extension Interface
- **`struct CABasicAnimationTypeDefinition`** - Register custom value types
  - `type` - Custom type identifier
  - `name` - Type name string
  - `interpolate` - Standard interpolation function
  - `interpolateAdditive` - Additive interpolation function
  - `valueUTF8String` - Debug string function
- **`CABasicAnimationTypeDefinitionRegister()`** - Register custom type (call in `+initialize`)
- **`CABasicAnimationTypeDefinitionGet()`** - Retrieve type definition

### 3.3. `CAPathAnimation.h`

#### `@interface CAPathAnimation`
- **Purpose:** Animates properties along a CGPath trajectory
- **Key Properties:**
  - `path` - CGPath defining the animation trajectory
  - `pathValueType` - Specifies what geometric property to extract from path

#### `enum CAPathAnimationValueType`
- **Purpose:** Defines which path property to animate
- **1D Values (CGFloat):**
  - `CAPathAnimationValueRotation` - Rotation of normal vector
  - `CAPathAnimationValueAngle` - Angle of normal vector
  - `CAPathAnimationValueTangentAngle` - Angle of tangent vector
  - `CAPathAnimationValueXPosition` - X coordinate only
  - `CAPathAnimationValueYPosition` - Y coordinate only
  - `CAPathAnimationValueDistance` - Distance traveled along path
- **2D Values (CGFloat2):**
  - `CAPathAnimationValuePosition` - Point coordinates along path
  - `CAPathAnimationValueNormal` - Normal vector at point
  - `CAPathAnimationValueTangent` - Tangent vector (direction of travel)
  - `CAPathAnimationValuePositionPlusNormal` - Point offset by normal
- **CGRect Values:**
  - `CAPathAnimationValuePose` - Full pose information
  - `CAPathAnimationValuePositionAsOrigin` - Animate frame origin along path
  - `CAPathAnimationValuePositionAsSize` - Animate frame size along path

#### Factory and Initializer
- **`+pathAnimationWithProperty:path:pathValueType:options:`** - Create path animation
- **`-initWithProperty:path:pathValueType:options:`** - Initialize path animation

### 3.4. `CAAnimator.h`

#### `@interface CAAnimator`
- **Purpose:** Container and executor for multiple animations
- **Implements:** `CAAnimationStorageObject` protocol
- **Key Instance Variable:**
  - `_animationStorage` - Storage for animation collection

#### Core Methods
- **`-animationStorage`** - Returns pointer to storage structure (required by protocol)
- **`-animateWithAbsoluteTime:animationRate:`** - Primary animation loop method, returns `YES` if any animations are still running
- **Query Methods:**
  - `-numberOfActiveAnimations` - Count of animations that exist
  - `-numberOfRunningAnimations` - Count of currently animating
  - `-numberOfFinishedAnimations` - Count of completed animations

#### Animation Management
- **`-addAnimation:`** - Add animation to animator (from `CAAnimationStorageObject`)
- **`-removeAnimation:`** - Remove specific animation
- **`-removeAllAnimations`** - Clear all animations
- **`-getAnimations:maxCount:animationID:animationObject:`** - Query animations matching criteria
- **`-finishAnimationsWithAnimationID:animationObject:`** - Force animations to completion

### 3.5. `CAAnimationStorage.h`

#### `struct CAAnimationStorage`
- **Purpose:** Internal storage structure for animation collections
- **Key Fields:**
  - `_numberOfAnimations` - Cached count
  - `_animations` - Pointer array of animation objects

#### `PROTOCOLCLASS CAAnimationStorageObject`
- **Purpose:** Protocolclass providing animation storage and management capabilities
- **Required Method:**
  - `-animationStorage` - Returns pointer to storage structure

#### Optional Methods
- **Lifecycle:**
  - `-initAnimationStorage` - Initialize storage (call in `-init`)
  - `-deallocAnimationStorage` - Clean up storage (call in `-dealloc`)
- **Query:**
  - `-hasAnimations` - Returns `YES` if any animations exist
  - `-numberOfAnimations` - Returns animation count
  - `-hasRunningAnimations` - Returns `YES` if any are animating
  - `-hasLayoutChangingAnimations` - Returns `YES` if any affect layout
- **Management:**
  - `-addAnimation:` - Add animation to collection
  - `-removeAnimation:` - Remove specific animation
  - `-resetAllAnimations` - Reset all animations without removing
  - `-removeAllAnimations` - Remove all animations
  - `-resetAnimationsForAnimationObject:` - Reset animations for specific object
  - `-removeAnimationsForAnimationObject:` - Remove animations for specific object
- **Execution:**
  - `-animateWithAbsoluteTime:animationRate:` - Animate all stored animations
- **Lookup:**
  - `-animationWithAnimationID:` - Find animation by string identifier

#### Convenience Macros
- **`CAAnimationStorageObjectIvars`** - Declares `struct CAAnimationStorage _animationStorage`
- **`CAAnimationStorageObjectInterface`** - Declares `-animationStorage` method
- **`CAAnimationStorageObjectImplementation`** - Implements `-animationStorage` method
- **`CAAnimationStorageObjectCopy(dst, src)`** - Copies storage between objects (for NSCopying)

### 3.6. `CAAnimationGroup.h`

#### `@interface CAAnimationGroup`
- **Purpose:** Container for multiple animations that are managed as a unit, typically created by `CATransaction`
- **Inherits From:** `CAAnimation`
- **Implements:** `CAAnimationStorageObject`
- **Key Instance Variables:**
  - `_animationStorage` - Storage for grouped animations
  - `_animationID` - String identifier for the group
  - `_hasStarted` - Tracks whether group has begun

#### Properties - Delegate Configuration
- **`animationDelegate`** - Delegate object receiving callbacks
- **`animationWillStartSelector`** - Selector for will-start callback
- **`animationDidStopSelector`** - Selector for did-stop callback
- **`animationContext`** - User context pointer

#### Properties - Animation Parameters (for child animations)
- **Purpose:** These properties configure animations created during the group's lifetime, not the group itself
- **`animationDelay`** - Delay before child animations start
- **`animationDuration`** - Duration of child animations
- **`animationOffset`** - Starting offset for child animations
- **`animationRepeatCount`** - Repeat count for child animations
- **`animationCurve`** - Timing curve for child animations
- **`animationTweenFunction`** - Custom tween function for child animations
- **`animationAutoreverses`** - Whether child animations auto-reverse
- **`animationIsAdditive`** - Whether child animations are additive

#### Methods
- **`-setAnimationID:` / `-animationID`** - Set/get string identifier (uses strcpy)
- **`-setupAnimationOptions:`** - Configure `CAAnimationOptions` from group properties
- **`-setupBasicAnimationOptions:`** - Configure `CABasicAnimationOptions` from group properties

### 3.7. `CATransaction.h`

#### `@interface CATransaction`
- **Purpose:** Generates implicit animations for observable property changes
- **Thread Safety:** Thread-local via `CATransactionGetCurrentTransaction()`
- **Key Instance Variables:**
  - `_animatedObjects` - Array of objects with property changes (not retained)
  - `_animationGroup` - Group collecting generated animations (retained)

#### Lifecycle Methods
- **`-begin`** - Start transaction, enables animation generation
- **`-commit`** - End transaction, generate animations, returns `CAAnimationGroup`
- **`-reset`** - Clear transaction state

#### Object Management
- **`-addAnimatableObject:`** - Register object with property changes
- **`-removeAnimatableObject:`** - Unregister object (use via `-forgetImplicitAnimations`)

#### Properties (forwarded to animation group)
- **Delegate:**
  - `animationContext`, `animationDelegate`, `animationWillStartSelector`, `animationDidStopSelector`, `animationID`
- **Timing:**
  - `animationDelay`, `animationOffset`, `animationDuration`, `animationRepeatCount`
- **Curve:**
  - `animationCurve`, `animationTweenFunction`, `animationAutoreverses`
- **Mode:**
  - `animationIsAdditive` - Controls whether animations replace or add to existing

#### `enum CATransactionState`
- **Values:** `CATransactionIdle`, `CATransactionStarted`, `CATransactionCommitting`

#### Global Functions
- **`CATransactionGetCurrentTransaction()`** - Get thread-local transaction
- **`CATransactionSetCurrentTransaction()`** - Set thread-local transaction

#### `CATransactionSuspendedDo(name)` Macro
- **Purpose:** Execute block with transaction temporarily suspended
- **Usage:** Prevents implicit animation generation within block

### 3.8. `CAImplicitlyAnimatableObject.h`

#### `PROTOCOLCLASS CAImplicitlyAnimatableObject`
- **Purpose:** Protocol for objects that support implicit animation via `CATransaction`
- **Inherits:** `MullePropertyObserving`

#### Required Property
- **`snapshot`** - Stores pre-transaction property values (retained)

#### Required Methods
- **`-generateAnimationsForPropertiesWithSnapshot:animationGroup:`** - Create animations by comparing current values to snapshot

#### Optional Methods
- **`-observablePropertiesSnapshot`** - Create snapshot of observable properties
- **`-willChange`** - Called before observable property changes (from `MullePropertyObserving`)
- **`-commitImplicitAnimations:`** - Finalize implicit animations
- **`-forgetImplicitAnimations`** - Discard uncommitted animations

#### Convenience Macros
- **`CAImplicitlyAnimatableObjectIvars`** - Declares `id _snapshot`
- **`CAImplicitlyAnimatableObjectInterface`** - Declares `@property(retain) id snapshot`
- **`CAImplicitlyAnimatableObjectImplementation`** - Empty implementation (for protocol conformance)

#### Important Notes
- **Observable Properties:** Only properties marked `observable` generate implicit animations
- **Supported Types:** id, NSInteger, CGFloat, CGPoint, CGRect, CGSize, NSRange, MulleEdgeInsets, MulleCornerInsets (BOOL, unsigned types, char, short, int, long, pointers, unions are NOT supported)

### 3.9. `CALayer.h`

#### `@interface CALayer`
- **Purpose:** Basic layer class for layout geometry and animation, base for rendering layers
- **Inherits:** `MulleObject`
- **Implements:** `NSCopying`, `CAImplicitlyAnimatableObject`, `CAAnimationStorageObject`
- **Key Instance Variables:**
  - `_animationStorage` - Storage for layer animations
  - `_snapshot` - Property snapshot for implicit animations
  - `_atomicNameUTF8String` - Thread-safe debug name

#### Observable Properties (animatable)
- **`opacity`** - Layer opacity (CGFloat)
- **`frame`** - Layer frame rectangle (CGRect)
- **`bounds`** - Layer bounds rectangle (CGRect)
- **`canvas`** - Layer canvas rectangle (CGRect)

#### Non-Observable Properties
- **`masksToBounds`** - Whether to clip to bounds
- **`transform`** - Affine transform (set by UIView, do not modify directly)
- **`clipRect`** - Clip rectangle (set by UIView, do not modify directly)
- **`alpha`** - Alpha value (set by UIView, do not modify directly)
- **`frameTracking`** - Bitfield controlling bounds/canvas tracking
- **`tag`** - Integer tag for identification
- **`hidden`** - Visibility flag
- **`nameUTF8String`** - Debug name string
- **`debuggingFlags`** - Thread-safe debugging flags

#### Frame Tracking Constants
- **`CALayerCanvasSizeTracksFrameSize`** - Canvas size automatically matches frame size
- **`CALayerBoundsSizeTracksFrameSize`** - Bounds size automatically matches frame size

#### Factory Methods
- **`+layer`** - Create layer with zero frame
- **`+layerWithFrame:`** - Create layer with specified frame

#### Initializers
- **`-initWithFrame:`** - Initialize with frame rectangle

#### Methods
- **`-layoutWithLayoutInfo:`** - Perform layout with given info
- **`-dumpWithIndent:FILE:`** - Debug dump layer hierarchy

### 3.10. `NSObject+CAAnimation.h`

#### `@interface NSObject(CAAnimation)`
- **Purpose:** Category enabling custom animation generation for object properties

#### Methods
- **`-generateAnimationsForPropertiesWithSnapshot:animationGroup:`** - Default implementation for implicit animation generation

#### `@interface NSObject(CAAnimation_Forward)`
- **Purpose:** Category for creating custom animations for value objects

#### Methods
- **`+createAnimationFrom:to:property:options:`** - Class method for custom animation creation (alternative to `CAInterpolatableValue` protocol)

#### `struct CAPropertyAnimationContext`
- **Purpose:** Context structure passed to custom property animators
- **Key Fields:**
  - `self` - Object being animated
  - `snapshot` - Pre-change property snapshot
  - `animationGroup` - Group to add animations to
  - `animationOptions` - Animation timing options
  - `flags` - Animation flags

#### Extension Interface
- **`struct CAAnimationPropertyDefinition`** - Register custom property type handlers
  - `matchRuntimeStructName` - Function to match property type signature
  - `animateProperty` - Function to create animation for property
- **`CAAnimationPropertyDefinitionRegister()`** - Register custom property handler
- **`CAPropertyAnimationContextAddAnimation()`** - Add animation to context

### 3.11. `CGGeometry+MulleObjC.h` and `MulleEdgeInsets+MulleObjC.h`

#### Purpose
- **MulleCA-specific geometry extensions** for CGFloat-based types
- **Enables animation** of CGPoint, CGSize, CGRect, MulleEdgeInsets

#### Typical Contents
- **NSValue extensions** for boxing/unboxing geometry types
- **Utility functions** for geometry calculations

## 4. Performance Characteristics

**Animation Execution:** `O(n)` where n is the number of active animations. Each animation is evaluated independently per frame.

**Storage Operations:** Adding/removing animations is `O(1)` amortized using `mulle_pointerarray`. Lookups by ID or object are `O(n)`.

**Interpolation:** Most interpolation operations are `O(1)` (arithmetic). Object-based interpolation (`CAInterpolatableValue`) depends on object implementation. Path animations require path sampling which may involve curve evaluation.

**Memory:** Each `CABasicAnimation` stores start/end values (typically 8-32 bytes), property pointer, timing info (~64 bytes total). `CAAnimationStorage` uses dynamic pointer array with growth strategy.

**Thread Safety:** Animations are **not thread-safe** by default. Access to CALayer animations should be serialized through the UIView's lock. `CATransaction` is thread-local. Certain properties (`debuggingFlags`) are marked `MULLE_OBJC_THREADSAFE_PROPERTY`.

**Frame Rate Independence:** Animations use absolute time (`mulle_absolutetime_t`) making them frame-rate independent. Optional `animationRate` parameter enables frame quantization for consistent final values at discrete refresh rates (e.g., 60 Hz).

## 5. AI Usage Recommendations & Patterns

### Best Practices

**Lifecycle Management:** Always use factory methods or explicit initializers. For objects that need animations, implement `CAAnimationStorageObject` and call `-initAnimationStorage` in `-init` and `-deallocAnimationStorage` in `-dealloc`. For implicit animations, implement `CAImplicitlyAnimatableObject` and mark properties as `observable`.

**Property Access:** Use `MulleObjCInstanceSearchProperty(object, @selector(propertyName))` to obtain property descriptors at runtime for animation creation. Cache property pointers if creating many animations for the same property.

**Options Configuration:** Pass `NULL` for options to get default values (delay=0, duration=1, repeatCount=1). Use convenience constructors like `CABasicAnimationOptionsMakeLinear()` or `CABasicAnimationOptionsMakeEaseInOut()`. Set flags with `CABasicAnimationOptionsSetBit(&options, CAAnimationAdditive)`.

**Animation Timing:** Specify time in seconds using `mulle_relativetimerange_make(delay, duration)`. Use `INFINITY` for `repeatCount` to loop forever. Set `animationRate` to `1.0/fps` (e.g., `1.0/60.0`) for quantized animations; use `0.0` for continuous interpolation.

**Additive Animations:** Set `CAAnimationAdditive` flag to allow multiple animations to blend on the same property. This adds interpolated differences rather than replacing values. Combine with `CAAnimationCumulative` to accumulate values across repeat cycles.

**Implicit Animations:** Wrap property modifications in `CATransaction` begin/commit blocks. Transaction generates animations automatically for `observable` properties. Set transaction properties (duration, curve, etc.) before modifying object properties.

### Common Pitfalls

**Direct Field Access:** Never directly access internal fields prefixed with `_`. Use property accessors or documented API methods.

**Memory Management:** Unlike Apple's CoreAnimation, `delegate` property is **not retained**. Ensure delegate outlives the animation. `animationObject` **is** retained.

**Boolean Animations:** Use `CAAnimationValueBOOL` with start=NO, end=YES. Booleans interpolate as discrete values (flip at t=0.5).

**Unsigned Types:** NSUInteger and other unsigned types are not directly supported. Cast to NSInteger or use custom interpolation.

**Transform Properties:** Do not animate `transform`, `clipRect`, or `alpha` on `CALayer` directly—these are managed by UIView. Animate `frame`, `bounds`, `opacity` instead.

**Repeat and Reverse:** `CAAnimationReverses` requires `repeatCount > 1` to take effect. Unlike Apple's implementation, reversal does not affect effective duration—a 2-second animation with reverse and repeatCount=2 takes 2 seconds total (not 4).

**Transaction Lifecycle:** Don't retain or copy `CATransaction` objects—they are short-lived. Don't call `-commit` twice on the same transaction.

**Path Animation Properties:** Ensure the property type matches `pathValueType` (e.g., CGFloat for rotation, CGPoint for position, CGRect for pose).

### Idiomatic Usage

**Animation Loop Pattern:** Create `CAAnimator`, add animations, then repeatedly call `-animateWithAbsoluteTime:animationRate:` in your render loop, passing current timestamp and frame rate.

**Reusing Animations:** Call `-init...` methods again on existing animation objects to reconfigure them without reallocation.

**Custom Value Types:** Implement `CAInterpolatableValue` protocol on custom objects, or register a `CABasicAnimationTypeDefinition` for new primitive types.

**Debugging:** Set `debuggingFlags` property and use `CAAnimationBitsUTF8String()`, `CAAnimationOptionsUTF8String()`, and `-UTF8String` methods for debug output.

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

### Example 4: Path Animation for Movement Along Curve

```c
#import <MulleCA/MulleCA.h>

@interface Sprite : NSObject
@property CGPoint   center;
@end

@implementation Sprite
- (void) setCenter:(CGPoint) point
{
   _center = point;
   printf( "(%.1f, %.1f)\n", point.x, point.y);
}
@end

int   main( void)
{
   CAPathAnimation                  *animation;
   Sprite                           *sprite;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;
   CGPathRef                        path;
   mulle_absolutetime_t             t;

   sprite   = [Sprite object];
   property = MulleObjCInstanceSearchProperty( sprite, @selector( center));

   path = CGPathCreateMutable();
   CGPathMoveToPoint( path, CGPointMake( 0, 0));
   CGPathAddLineToPoint( path, CGPointMake( 100, 0));
   CGPathAddLineToPoint( path, CGPointMake( 100, 100));
   CGPathAddLineToPoint( path, CGPointMake( 0, 100));
   CGPathCloseSubpath( path);

   options = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 2.0),
                                                 1.0,
                                                 NO);

   animation = [[[CAPathAnimation alloc] initWithProperty:property
                                                     path:path
                                            pathValueType:CAPathAnimationValuePosition
                                                  options:&options] autorelease];
   [animation setAnimationObject:sprite];

   for( t = 0.0; t <= 2.0; t += 0.2)
   {
      [animation animateObject:sprite
                  absoluteTime:t
                 animationRate:0.0];
   }

   CGPathDestroy( path);
   return( 0);
}
```

### Example 5: Custom Interpolatable Value Object

```c
#import <MulleCA/MulleCA.h>

@interface Color : NSObject <CAInterpolatableValue>
{
   CGFloat   _r;
   CGFloat   _g;
   CGFloat   _b;
}
+ (instancetype) colorWithR:(CGFloat) r g:(CGFloat) g b:(CGFloat) b;
@end

@implementation Color

+ (instancetype) colorWithR:(CGFloat) r g:(CGFloat) g b:(CGFloat) b
{
   Color   *color;

   color     = [[self alloc] init];
   color->_r = r;
   color->_g = g;
   color->_b = b;
   return( [color autorelease]);
}

- (id) copyWithZone:(NSZone *) zone
{
   return( [[[self class] allocWithZone:zone] colorWithR:_r g:_g b:_b]);
}

- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive
{
   Color     *endColor;
   CGFloat   r;
   CGFloat   g;
   CGFloat   b;

   endColor = end;
   if( additive)
   {
      r        = (endColor->_r - _r) * x;
      g        = (endColor->_g - _g) * x;
      b        = (endColor->_b - _b) * x;
   }
   else
   {
      r        = _r + (endColor->_r - _r) * x;
      g        = _g + (endColor->_g - _g) * x;
      b        = _b + (endColor->_b - _b) * x;
   }
   return( [[self class] colorWithR:r g:g b:b]);
}

- (id) interpolatedValueWithDiff:(id) diff
                    previousDiff:(id) previous
{
   Color     *diffColor;
   Color     *prevColor;
   CGFloat   r;
   CGFloat   g;
   CGFloat   b;

   diffColor = diff;
   prevColor = previous;

   r         = _r - (prevColor ? prevColor->_r : 0.0) + diffColor->_r;
   g         = _g - (prevColor ? prevColor->_g : 0.0) + diffColor->_g;
   b         = _b - (prevColor ? prevColor->_b : 0.0) + diffColor->_b;

   return( [[self class] colorWithR:r g:g b:b]);
}

@end

@interface ColorBox : NSObject
@property( retain) Color   *tint;
@end

@implementation ColorBox
@end

int   main( void)
{
   CABasicAnimation                 *animation;
   ColorBox                         *box;
   Color                            *start;
   Color                            *end;
   struct _mulle_objc_property      *property;
   struct CABasicAnimationOptions   options;

   box      = [ColorBox object];
   start    = [Color colorWithR:1.0 g:0.0 b:0.0];
   end      = [Color colorWithR:0.0 g:0.0 b:1.0];
   property = MulleObjCInstanceSearchProperty( box, @selector( tint));

   options  = CABasicAnimationOptionsMakeLinear( mulle_relativetimerange_make( 0, 1.0),
                                                  1.0,
                                                  NO);

   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                          startObjectValue:start
                                            endObjectValue:end
                                                   options:&options] autorelease];
   [animation setAnimationObject:box];

   [animation animateObject:box absoluteTime:0.0 animationRate:0.0];
   [animation animateObject:box absoluteTime:0.5 animationRate:0.0];
   [animation animateObject:box absoluteTime:1.0 animationRate:0.0];

   return( 0);
}
```

## 7. Dependencies

MulleCA directly depends on the following mulle-sde libraries:

- **mulle-gfx** - Graphics primitives including CGPath, CGPoint, CGRect, CGSize, CGColor, CGAffineTransform
- **MulleUIBase** - Base UI types including MulleEdgeInsets, MulleCornerInsets
- **mulle-objc-list** - Objective-C runtime support and foundation classes (NSObject, NSValue, NSRange, etc.)
