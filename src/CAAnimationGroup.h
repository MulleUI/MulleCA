//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
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
