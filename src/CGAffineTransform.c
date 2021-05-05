//******************************************************************************
//
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
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

#include "CGAffineTransform.h"

#include "CGGeometry.h"

#include <math.h>
#include <string.h>

#define kPi    3.14159265358979323846f
#define kPi_d  3.14159265358979323846

#define IS_NEAR( val, comp, amt) (fabs((val) - (comp)) <= (amt))


const CGAffineTransform CGAffineTransformIdentity = { 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f };



CGAffineTransform CGAffineTransformMakeRotation(CGFloat angle) {
    CGAffineTransform ret;

   // TODO: is this desirable ?
   // TODO: use nvg PI definition here if code is to be kept
    if (IS_NEAR(angle, ((CGFloat) kPi / 2.0f), 0.0001f)) {
        ret.a = 0;
        ret.b = 1.0f;
        ret.c = -1.0f;
        ret.d = 0.0f;
        ret.tx = 0.0f;
        ret.ty = 0.0f;

        return ret;
    }

    ret.a = cosf(angle);
    ret.b = sinf(angle);
    ret.c = -ret.b;
    ret.d = ret.a;
    ret.tx = 0.0f;
    ret.ty = 0.0f;

    return ret;
}




CGAffineTransform CGAffineTransformRotate(CGAffineTransform curTransform, float angle) {
    CGAffineTransform ret;

    ret = CGAffineTransformMakeRotation(angle);
    ret = CGAffineTransformConcat(ret, curTransform);

    return ret;
}


CGAffineTransform CGAffineTransformTranslate(CGAffineTransform curTransform, float x, float y) {
    CGAffineTransform trans;

    trans = CGAffineTransformMakeTranslation(x, y);
    trans = CGAffineTransformConcat(trans, curTransform);

    return trans;
}


CGAffineTransform CGAffineTransformScale(CGAffineTransform curTransform, float x, float y) {
    CGAffineTransform scale;

    scale = CGAffineTransformMakeScale(x, y);
    return CGAffineTransformConcat(scale, curTransform);
}


CGAffineTransform CGAffineTransformInvert(CGAffineTransform curTransform) {
    float determinant = (curTransform.a * curTransform.d - curTransform.c * curTransform.b);

    if (determinant == 0) {
        return curTransform;
    }

    CGAffineTransform ret;
    ret.a = curTransform.d / determinant;
    ret.b = -curTransform.b / determinant;
    ret.c = -curTransform.c / determinant;
    ret.d = curTransform.a / determinant;
    ret.tx = (-curTransform.d * curTransform.tx + curTransform.c * curTransform.ty) / determinant;
    ret.ty = (curTransform.b * curTransform.tx - curTransform.a * curTransform.ty) / determinant;

    return ret;
}


int CGAffineTransformIsIdentity(CGAffineTransform curTransform) {
    if (memcmp(&curTransform, &CGAffineTransformIdentity, sizeof(curTransform)) == 0) {
        return 1;
    } else {
        return 0;
    }
}


int CGAffineTransformEqualToTransform(CGAffineTransform t2, CGAffineTransform t1) {
    if (memcmp(&t1, &t2, sizeof(CGAffineTransform)) == 0) {
        return 1;
    } else {
        return 0;
    }

    return 0;
}

//
// MEMO: the ifs probably preclude too much compiler optimization where
//       steps can be computed and combined with other steps
//
CGAffineTransform   MulleAffineTransformMakeProjection( CGRect frame, CGRect bounds)
{
   CGAffineTransform   xform;
   CGPoint             scale;

   xform = CGAffineTransformMakeTranslation( -bounds.origin.x, -bounds.origin.y);

   //
   // now translate bounds for context
   //
   //if( ! CGSizeEqualToSize( frame.size, bounds.size))
   {
      scale.x = frame.size.width  / bounds.size.width;
      scale.y = frame.size.height / bounds.size.height;
      xform   = CGAffineTransformConcat( xform,
                                         CGAffineTransformMakeScale( scale.x, scale.y));
   }

   //if( ! CGPointEqualToPoint( frame.origin, CGPointMake( 0, 0)))
      xform = CGAffineTransformConcat( xform,
                                       CGAffineTransformMakeTranslation( frame.origin.x,
                                                                         frame.origin.y));
   return( xform);
}


// could also do
CGAffineTransform   MulleAffineTransformMakeInverseProjection( CGRect frame, CGRect bounds)
{
   CGPoint             scale;
   CGAffineTransform   xform;

   xform = CGAffineTransformMakeTranslation( bounds.origin.x, bounds.origin.y);
   //if( ! CGSizeEqualToSize( frame.size, bounds.size))
   {
      scale.x = bounds.size.width / frame.size.width;
      scale.y = bounds.size.height / frame.size.height;

      xform   = CGAffineTransformConcat( CGAffineTransformMakeScale( scale.x, scale.y),
                                         xform);
   }

   //if( ! CGPointEqualToPoint( bounds.origin, CGPointMake( 0, 0)))
      xform = CGAffineTransformConcat( CGAffineTransformMakeTranslation( -frame.origin.x,
                                                                         -frame.origin.y),
                                       xform);
   return( xform);
}


// -original-

