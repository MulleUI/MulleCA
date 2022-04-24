#import <MulleCA/MulleCA.h>


static void   print_animator( CAAnimator *animator)
{
   printf( "hasAnimations=%s\n",        [animator hasAnimations] ? "YES" : "NO");
   printf( "hasRunningAnimations=%s\n", [animator hasRunningAnimations] ? "YES" : "NO");
   printf( "numberOfAnimations=%td\n",  [animator numberOfAnimations]);
}

int   main( void)
{
   CAAnimator   *animator;
   CAAnimation  *animation;

   // create object, get property, create an animation for this property

   /*
    * animator now runs animation with our fake timestamps
    */
   animator = [CAAnimator object];

   print_animator( animator);

   animation = [CAAnimation animationWithAnimationOptions:NULL];
   [animator addAnimation:animation];

   print_animator( animator);

   [animator removeAnimation:animation];

   print_animator( animator);

   animation = [CAAnimation animationWithAnimationOptions:NULL];
   [animator addAnimation:animation];
   animation = [CAAnimation animationWithAnimationOptions:NULL];
   [animator addAnimation:animation];
   animation = [CAAnimation animationWithAnimationOptions:NULL];
   [animator addAnimation:animation];
   print_animator( animator);

   [animator removeAllAnimations];

   print_animator( animator);

   return( 0);
}
