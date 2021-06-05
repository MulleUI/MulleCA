#ifndef CA_TIME_H__
#define CA_TIME_H__

#include "include.h"


// It's simple. CAAbsoluteTime is a FP number containing seconds as a timestamp
// relative to a reference date which is defined in mulle-time.h. But still an
// absolute time. CARelativeTime is a time duration, also in FP seconds. So
// 0.25 is a quarter second.
//
// struct CAAbsoluteTimeRange is a... range of time with a start and and end.
// The end is thought of as being inclusive.
//
// Arithmetic on CAAbsoluteTime and CARelativeTime has six useful operations
//
// 1. CAAbsoluteTime + CAAbsoluteTime = invalid
// 2. CAAbsoluteTime + CARelativeTime = CAAbsoluteTime
// 3. CARelativeTime + CAAbsoluteTime = CAAbsoluteTime
// 4. CARelativeTime + CARelativeTime = CARelativeTime
//
// 5. CAAbsoluteTime - CAAbsoluteTime = CARelativeTime
// 6. CAAbsoluteTime - CARelativeTime = CAAbsoluteTime
// 7. CARelativeTime - CAAbsoluteTime = invalid
// 8. CARelativeTime - CARelativeTime = CARelativeTime
//
typedef mulle_timeinterval_t   CAAbsoluteTime;
typedef double                 CARelativeTime;


static inline void   _CARelativeTimeInit( CARelativeTime *p, double value)
{
   *p = value;
}


static inline void   CARelativeTimeInit( CARelativeTime *p, double value)
{
   if( p)
      _CARelativeTimeInit( p, value);
}


static inline CARelativeTime   CARelativeTimeWithSecondsAndNanoseconds( int tv_sec, long tv_nsec)
{
   return( tv_sec + tv_nsec / (double) (1000L*1000*1000));
}



struct CARelativeTimeRange
{
   CARelativeTime   delay;
   CARelativeTime   duration;
};


static inline struct CARelativeTimeRange
   CARelativeTimeRangeMake( CARelativeTime delay, CARelativeTime duration)
{
    struct CARelativeTimeRange result = { delay, duration };
    return result;
}


static inline void   CARelativeTimeRangeInit( struct CARelativeTimeRange *p,
                                              CARelativeTime delay,
                                              CARelativeTime duration)
{
   if( p)
   {
      p->delay    = delay;
      p->duration = duration;
   }
}




static inline CAAbsoluteTime   CAAbsoluteTimeNow( void)
{
   return( (CAAbsoluteTime) mulle_timeinterval_now());
}


static inline void   _CAAbsoluteTimeInit( CAAbsoluteTime *p, double value)
{
   *p = value;
}


static inline void   CAAbsoluteTimeInit( CAAbsoluteTime *p, double value)
{
   if( p)
      _CAAbsoluteTimeInit( p, value);
}



struct CAAbsoluteTimeRange
{
   CAAbsoluteTime   start;
   CAAbsoluteTime   end;
};


static inline struct CAAbsoluteTimeRange
   CAAbsoluteTimeRangeMake( CAAbsoluteTime start, CAAbsoluteTime end)
{
    struct CAAbsoluteTimeRange result = { start, end };
    return result;
}


static inline void   _CAAbsoluteTimeRangeInit( struct CAAbsoluteTimeRange *p,
                                               CAAbsoluteTime start,
                                               CAAbsoluteTime end)
{
   p->start = start;
   p->end   = end;
}


static inline void   CAAbsoluteTimeRangeInit( struct CAAbsoluteTimeRange *p,
                                              CAAbsoluteTime start,
                                              CAAbsoluteTime end)
{
   if( p)
      _CAAbsoluteTimeRangeInit( p, start, end);
}


static inline CAAbsoluteTime   CAAbsoluteTimeWithTimespec( struct timespec a)
{
   return( a.tv_sec + a.tv_nsec / (double) (1000L*1000*1000));
}


static inline CAAbsoluteTime   CAAbsoluteTimeWithSecondsAndNanoseconds( int tv_sec, long tv_nsec)
{
   return( tv_sec + tv_nsec / (double) (1000L*1000*1000));
}


// can produce absolute time or relative
static inline double   CATimeAdd( double a, double b)
{
   return( a + b);
}


// can produce absolute time or relative
static inline double   CATimeSubtract( double a, double b)
{
   return( a - b);
}


#endif
