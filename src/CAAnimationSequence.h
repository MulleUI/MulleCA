//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "import.h"

#import "CAAnimationStorage.h"

@class CAAnimation;

//
// A CAAnimationSequence runs its child animations sequentially by
// managing their delays. When you add an animation, its delay is set
// to the current end of the sequence. Insert operations splice and
// shift subsequent animations.
//
// Internally all children still run in parallel via CAAnimationStorage —
// sequencing is achieved purely through staggered delays.
//
// For completion notification, use the standard CAAnimation delegate:
//    [sequence setDelegate:self];
// and implement:
//    - (void) animationDidStop:(CAAnimation *) animation finished:(BOOL) flag;
//
@interface CAAnimationSequence : CAAnimation < CAAnimationStorageObject>
{
   struct CAAnimationStorage   _animationStorage;
   char                        *_animationID;
   void                        *_animationContext;
}

// User-defined context pointer, retrievable in delegate callbacks.
@property( assign) void  *animationContext;

- (void) setAnimationID:(char *) s;
- (char *) animationID;

// Append to end of sequence.
// Sets animation's delay = current sequence end time.
// Sets removedOnCompletion to NO (the sequence owns child lifecycle).
- (void) addAnimation:(id <CAAnimation>) animation;

// Splice before reference.
// New animation gets reference's delay.
// Reference and all animations at or after that point shift forward.
- (void) insertAnimation:(id <CAAnimation>) animation
         beforeAnimation:(CAAnimation *) reference;

// Splice after reference.
// New animation's delay = reference's end time.
// All animations after that point shift forward.
- (void) insertAnimation:(id <CAAnimation>) animation
          afterAnimation:(CAAnimation *) reference;

// Remove and close the gap.
// Animations starting at or after the removed animation's end shift backward.
- (void) removeAnimation:(id <CAAnimation>) animation;

// Computed: max(delay[i] + duration[i] * repeatCount[i]) across all children.
- (mulle_relativetime_t) sequenceDuration;

// Add a pause (no-op) of given duration to the sequence.
- (void) addPause:(mulle_relativetime_t) duration;

// Convenience constructor: creates an auto-sizing sequence.
// Duration is computed from children when animation starts.
+ (instancetype) sequenceAnimation;

@end
