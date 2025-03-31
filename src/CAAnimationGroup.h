//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "import.h"

#import "CAAnimationStorage.h"

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
//
// CAAnimationGroup inherits "animationObject". Currently it needs to be set
// though it is unused...
//
@interface CAAnimationGroup : CAAnimation < CAAnimationStorageObject>
{
   struct CAAnimationStorage   _animationStorage;
   char                        *_animationID;
   BOOL                        _hasStarted;
}

// properties of the group
@property( assign) id                      animationDelegate;
@property( assign) SEL                     animationWillStartSelector;
@property( assign) SEL                     animationDidStopSelector;

@property( assign) void                    *animationContext;

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

// will be strcpy
- (void) setAnimationID:(char *) s;
- (char *) animationID;

@end


struct CAAnimationOptions;

@interface CAAnimationGroup( CAAnimationOptions)

- (void) setupAnimationOptions:(struct CAAnimationOptions *) options;

@end

struct CABasicAnimationOptions;

@interface CAAnimationGroup( CABasicAnimationOptions)

- (void) setupBasicAnimationOptions:(struct CABasicAnimationOptions *) options;

@end
