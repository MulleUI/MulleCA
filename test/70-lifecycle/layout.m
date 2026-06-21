#import <MulleCA/MulleCA.h>

@interface CAAnimation( LayoutCheck)
- (struct mulle_relativetimerange *) relativeTimeRange;
@end

int   main( void)
{
   CAAnimationGroup      *group;
   CAAnimationSequence   *seq;
   struct mulle_relativetimerange  *tr;

   // Test plain sequence first
   seq = [[CAAnimationSequence alloc] initWithAnimationOptions:NULL];
   tr  = [seq relativeTimeRange];
   mulle_printf( "seq relative: delay=%.1f duration=%.1f\n", tr->delay, tr->duration);
   [seq autorelease];

   // Now test group
   group = [CAAnimationGroup new];
   if( ! group)
   {
      mulle_printf( "group is nil!\n");
      return( 1);
   }
   tr = [group relativeTimeRange];
   mulle_printf( "group relative: delay=%.1f duration=%.1f\n", tr->delay, tr->duration);
   [group autorelease];

   return( 0);
}
