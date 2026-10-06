### 0.1.1


* float properties whose start or end value is `INFINITY` or `NaN` are no longer interpolated, but left unchanged
* avoids huge intermediate values that downstream consumers cannot handle (a derived font size otherwise overflows the nanovg glyph atlas and aborts)
* `CATextLayer`'s `fontPixelSize` and `textLineHeight` can now keep their "derive from the canvas" sentinel instead of being animated

## 0.1.0





* new `animationWithAnimationOptions:` factory methods on CAAnimationGroup, CAAnimationSequence and CABasicAnimation replace alloc/init/autorelease setup
* `NSObject+CAAnimation` now uses `animationFrom:` in place of `createAnimationFrom:` to build animations between objects (**BREAKING**: renamed method)
* README rewritten with a self-contained example and demo build instructions
* license headers added to all src files
