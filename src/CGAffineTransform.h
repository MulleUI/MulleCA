//******************************************************************************
//
// Copyright (c) Microsoft. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************
#include "CGGeometry.h"

typedef float   _NVGtransform[ 6];


// CGAffineTransform is structurally identical to the nanoVG xform
typedef struct {
    CGFloat a;
    CGFloat b;
    CGFloat c;
    CGFloat d;
    CGFloat tx;
    CGFloat ty;
} CGAffineTransform;

// MEMO: not sure this exists in CG
typedef CGAffineTransform   *CGAffineTransformRef;


extern const CGAffineTransform   CGAffineTransformIdentity;

static inline CGAffineTransform   CGAffineTransformMake( CGFloat a,
                                                         CGFloat b,
                                                         CGFloat c,
                                                         CGFloat d,
                                                         CGFloat tx,
                                                         CGFloat ty)
{
   return( (CGAffineTransform){ .a = a,
                                .b = b,
                                .c = c,
                                .d = d,
                                .tx = tx,
                                .ty = ty });
}


static inline CGAffineTransform   CGAffineTransformMakeIdentity( void)
{
   return( (CGAffineTransform){ .a = 1.0,
                                .b = 0.0,
                                .c = 0.0,
                                .d = 1.0,
                                .tx = 0.0,
                                .ty = 0.0 });
}



static inline CGAffineTransform   CGAffineTransformMakeTranslation(CGFloat tx, CGFloat ty)
{
   return( (CGAffineTransform){ .a = 1.0,
                                .b = 0.0,
                                .c = 0.0,
                                .d = 1.0,
                                .tx = tx,
                                .ty = ty });
}


static inline CGAffineTransform   CGAffineTransformMakeScale(CGFloat sx, CGFloat sy) {
   return( (CGAffineTransform){ .a = sx,
                                .b = 0.0,
                                .c = 0.0,
                                .d = sy,
                                .tx = 0.0,
                                .ty = 0.0 });
}


static inline CGAffineTransform   CGAffineTransformConcat(CGAffineTransform t2, CGAffineTransform t1) {
    CGAffineTransform ret;

    ret.a = t2.a * t1.a + t2.b * t1.c;
    ret.b = t2.a * t1.b + t2.b * t1.d;
    ret.c = t2.c * t1.a + t2.d * t1.c;
    ret.d = t2.c * t1.b + t2.d * t1.d;
    ret.tx = t2.tx * t1.a + t2.ty * t1.c + t1.tx;
    ret.ty = t2.tx * t1.b + t2.ty * t1.d + t1.ty;

    return ret;
}


CGAffineTransform   CGAffineTransformMakeRotation(CGFloat angle);

CGAffineTransform   CGAffineTransformConcat( CGAffineTransform xform, CGAffineTransform append);
CGAffineTransform   CGAffineTransformInvert( CGAffineTransform xform);

CGAffineTransform   CGAffineTransformRotate( CGAffineTransform xform, CGFloat radians);
CGAffineTransform   CGAffineTransformScale( CGAffineTransform xform, CGFloat scalex, CGFloat scaley);
CGAffineTransform   CGAffineTransformTranslate( CGAffineTransform xform, CGFloat tx, CGFloat ty);

int   CGAffineTransformIsIdentity( CGAffineTransform t);

int   CGAffineTransformEqualToTransform( CGAffineTransform t1, CGAffineTransform t2);


/**
 @Status Interoperable
*/
static inline CGSize CGSizeApplyAffineTransform(CGSize size, CGAffineTransform t) {
    return( (CGSize) {
        .width = (CGFloat)((double)t.a * size.width + (double)t.c * size.height),
        .height = (CGFloat)((double)t.b * size.width + (double)t.d * size.height)
    });
}


CGAffineTransform   MulleAffineTransformMakeProjection( CGRect frame, CGRect bounds);
CGAffineTransform   MulleAffineTransformMakeInverseProjection( CGRect frame, CGRect bounds);

//
// "conversion" or rather casting between CGAffineTransform and _NVGtransform
// which is float[ 6]
//
static inline float   *CGAffineTransformRefAs_NVGtransform( CGAffineTransform *xform)
{
   assert( sizeof( float) == sizeof( CGFloat));
   return( &xform->a);
}


static inline CGAffineTransform  *_NVGtransformAsCGAffineTransformRef( _NVGtransform xform)
{
   assert( sizeof( float) == sizeof( CGFloat));
   return( (CGAffineTransform *) xform);
}


/* Copyright (c) 2006-2007 Christopher J. W. Lloyd
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


static inline CGPoint CGPointApplyAffineTransform(CGPoint point,CGAffineTransform xform){
    CGPoint p;

    p.x=xform.a*point.x+xform.c*point.y+xform.tx;
    p.y=xform.b*point.x+xform.d*point.y+xform.ty;

    return p;
}


static inline CGRect   CGRectApplyAffineTransform( CGRect rect, CGAffineTransform t)
{
   CGRect   result;

   result.origin = CGPointApplyAffineTransform( rect.origin, t);
   result.size   = CGSizeApplyAffineTransform( rect.size, t);

   return( result);
}

