//
//  CAAnimationGroup.h
//  MulleCA
//
//  Copyright (c) 2019 Nat! - Mulle kybernetiK.
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

#import "CAAnimationSequence.h"

@class CAAnimation;

//
// During animation a CAAnimationGroup is owned by a CAAnimator.
//
//                        .------------.
//                    .---| CAAnimator |
//                    |   '------------'
//                    v
//            .------------------.
//        .---| CAAnimationGroup |
//        |   '------------------'
//        v           |
// .-------------.    |     .-------------.
// | CAAnimation |    '---->| CAAnimation |
// '-------------'          '-------------'
//
//
//
// The CAAnimationGroup is created by a CATransaction during -begin
// and is used to store the animations created during the transaction.
//
//             .---------------.
//             | CATransaction |
//             '---------------'
//                     |
//                     v
//           .------------------.
//         .-| CAAnimationGroup |
//         | '------------------'
//         v           |
//  .-------------.    |     .-------------.
//  | CAAnimation |    '---->| CAAnimation |
//  '-------------'          '-------------'
//
//
// Each animation in an animation group is separately animated, changing
// any animation values in a CAAnimationGroup post-creation will not
// accomplish anything.
//
// Animations are not clipped to the duration of the animation group.
// However, the group is removed from the animator when its own duration
// expires. Children are owned by the group, so they die with it.
// Ensure group duration >= longest child duration, or children will
// never finish.
//
// CAAnimationGroup inherits "animationObject". Currently it needs to be set
// though it is unused...
//
// CAAnimationGroup is a CAAnimationSequence that does NOT manage delays.
// All child animations run in parallel with their own timing.
//
// For completion notification, use the standard CAAnimation delegate:
//    [group setDelegate:self];
// and implement CAAnimationDelegate methods.
//

@class CAAnimationGroup;

@interface CAAnimationGroup : CAAnimationSequence

// Adds animation to run in parallel (no delay computation).
// Sets removedOnCompletion to NO (the group owns child lifecycle).
- (void) addAnimation:(id <CAAnimation>) animation;

// ...
@property( assign) mulle_relativetime_t    animationDelay;
@property( assign) mulle_relativetime_t    animationDuration;
@property( assign) mulle_relativetime_t    animationOffset;

//
// Properties that are used to setup the animations on their creation
// they are not used on the animation group as an object itself.
//
@property( assign) float                   animationRepeatCount;
@property( assign) NSUInteger              animationCurve; // this is an enum
@property( assign) CATweenFunction         *animationTweenFunction;
@property( assign) BOOL                    animationAutoreverses;
@property( assign) BOOL                    animationIsAdditive;

@end


struct CAAnimationOptions;

@interface CAAnimationGroup( CAAnimationOptions)

- (void) setupAnimationOptions:(struct CAAnimationOptions *) options;

@end

struct CABasicAnimationOptions;

@interface CAAnimationGroup( CABasicAnimationOptions)

- (void) setupBasicAnimationOptions:(struct CABasicAnimationOptions *) options;

@end
