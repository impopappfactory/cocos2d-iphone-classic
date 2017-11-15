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
 *
 */

#import "CCActionInterval.h"

@class CCCamera;

/** Base class for CCCamera actions
 */
@interface CCActionCamera : CCActionInterval <NSCopying>
{
	CGFloat _centerXOrig;
	CGFloat _centerYOrig;
	CGFloat _centerZOrig;

	CGFloat _eyeXOrig;
	CGFloat _eyeYOrig;
	CGFloat _eyeZOrig;

	CGFloat _upXOrig;
	CGFloat _upYOrig;
	CGFloat _upZOrig;
}
// XXX Needed for BridgeSupport
-(void) startWithTarget:(id)aTarget;
@end

/** CCOrbitCamera action
 Orbits the camera around the center of the screen using spherical coordinates
 */
@interface CCOrbitCamera : CCActionCamera <NSCopying>
{
	CGFloat _radius;
	CGFloat _deltaRadius;
	CGFloat _angleZ;
	CGFloat _deltaAngleZ;
	CGFloat _angleX;
	CGFloat _deltaAngleX;

	CGFloat _radZ;
	CGFloat _radDeltaZ;
	CGFloat _radX;
	CGFloat _radDeltaX;

}
/** creates a CCOrbitCamera action with radius, delta-radius,  z, deltaZ, x, deltaX */
+(id) actionWithDuration:(CGFloat) t radius:(CGFloat)r deltaRadius:(CGFloat) dr angleZ:(CGFloat)z deltaAngleZ:(CGFloat)dz angleX:(CGFloat)x deltaAngleX:(CGFloat)dx;
/** initializes a CCOrbitCamera action with radius, delta-radius,  z, deltaZ, x, deltaX */
-(id) initWithDuration:(CGFloat) t radius:(CGFloat)r deltaRadius:(CGFloat) dr angleZ:(CGFloat)z deltaAngleZ:(CGFloat)dz angleX:(CGFloat)x deltaAngleX:(CGFloat)dx;
/** positions the camera according to spherical coordinates */
-(void) sphericalRadius:(CGFloat*) r zenith:(CGFloat*) zenith azimuth:(CGFloat*) azimuth;
@end
