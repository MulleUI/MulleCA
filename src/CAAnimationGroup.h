//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "import.h"

#import "CATime.h"
#import "CAQuadratic.h"

@class CAAnimation;


//
//  .---------.          .-------------.    .------------------.
//  | CALayer |--------->| CAAnimation |--->| CAAnimationGroup |
//  '---------'          '-------------'    '------------------'
//       |               .-------------.              ^
//       '-------------->| CAAnimation |--------------'
//                       '-------------'
//
//
// The CAAnimationGroup is created by a CATransaction during -begin
// and is used to store some common information for all the animations.
// The name is not so good,as the CAAnimationGroup doesn't know about its
// members. Info would be better. As a MulleCA user, you don't create a
// CAAnimationGroup yourself and you don't have to interact with it.
//
// Each animation in an animation group is separately animated, changing
// any animation values here post-animation creation will not accomplish
// anything.
//
@interface CAAnimationGroup : NSObject
{
   NSUInteger   _startedCount;
   NSUInteger   _endedCount;
   char         *_animationID;
}

// properties of the group
@property( assign) id     animationDelegate;
@property( assign) SEL    animationWillStartSelector;
@property( assign) SEL    animationDidStopSelector;

// will be strcpy
- (void) setAnimationID:(char *) s;
- (char *) animationID;
@property( assign) void   *context;

// properties that are used to setup the animations on their creation
@property( assign) CARelativeTime    animationDelay;
@property( assign) CARelativeTime    animationDuration;
@property( assign) float             animationRepeatCount;
@property( assign) NSUInteger        animationCurve; // this is an enum
@property( assign) CATweenFunction   *animationTweenFunction;
@property( assign) BOOL              animationAutoreverses;
@property( assign) BOOL              animationIsAdditive;

@end


struct CAAnimationOptions;

@interface CAAnimationGroup( CAAnimationOptions)

- (void) setAnimationOptions:(struct CAAnimationOptions *) options;

@end

struct CABasicAnimationOptions;

@interface CAAnimationGroup( CABasicAnimationOptions)

- (void) setBasicAnimationOptions:(struct CABasicAnimationOptions *) options;

@end
