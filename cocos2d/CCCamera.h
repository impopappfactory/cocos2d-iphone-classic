/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */



#import "CCNode.h"
#import "kazmath/mat4.h"

/**
    A CCCamera is used in every CCNode.
    Useful to look at the object from different views.
    The OpenGL gluLookAt() function is used to locate the
    camera.

    If the object is transformed by any of the scale, rotation or
    position attributes, then they will override the camera.

	IMPORTANT: Either your use the camera or the rotation/scale/position properties. You can't use both.
    World coordinates won't work if you use the camera.

    Limitations:

     - Some nodes, like CCParallaxNode, CCParticle uses world node coordinates, and they won't work properly if you move them (or any of their ancestors)
       using the camera.

     - It doesn't work on batched nodes like CCSprite objects when they are parented to a CCSpriteBatchNode object.

	 - It is recommended to use it ONLY if you are going to create 3D effects. For 2D effects, use the action CCFollow or position/scale/rotate.

*/

@interface CCCamera : NSObject
{
    CGFloat _eyeX;
    CGFloat _eyeY;
    CGFloat _eyeZ;

    CGFloat _centerX;
    CGFloat _centerY;
    CGFloat _centerZ;

    CGFloat _upX;
    CGFloat _upY;
    CGFloat _upZ;

	BOOL _dirty;

	kmMat4	_lookupMatrix;
}

/** whether of not the camera is dirty */
@property (nonatomic,readwrite) BOOL dirty;

/** returns the Z eye */
+(CGFloat) getZEye;

/** sets the camera in the defaul position */
-(void) restore;
/** Sets the camera using gluLookAt using its eye, center and up_vector */
-(void) locate;
/** sets the eye values in points */
-(void) setEyeX: (CGFloat)x eyeY:(CGFloat)y eyeZ:(CGFloat)z;
/** sets the center values in points */
-(void) setCenterX: (CGFloat)x centerY:(CGFloat)y centerZ:(CGFloat)z;
/** sets the up values */
-(void) setUpX: (CGFloat)x upY:(CGFloat)y upZ:(CGFloat)z;

/** get the eye vector values in points */
-(void) eyeX:(CGFloat*)x eyeY:(CGFloat*)y eyeZ:(CGFloat*)z;
/** get the center vector values in points */
-(void) centerX:(CGFloat*)x centerY:(CGFloat*)y centerZ:(CGFloat*)z;
/** get the up vector values */
-(void) upX:(CGFloat*)x upY:(CGFloat*)y upZ:(CGFloat*)z;


@end
