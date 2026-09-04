//
//  CAAnimationSequence.h
//  MulleCA
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
