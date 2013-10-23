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


// cocos2d imports
#import "CCScheduler.h"
#import "ccMacros.h"
#import "CCDirector.h"
#import "Support/uthash.h"
#import "Support/utlist.h"
#import <objc/message.h>

static SEL UPDATE_SELECTOR, FIXED_UPDATE_SELECTOR;

@interface CCScheduledTarget : NSObject {
	@public
	void (*_update_IMP)(id, SEL, ccTime);
	void (*_fixedUpdate_IMP)(id, SEL, ccTime);
	__weak NSObject<CCSchedulerTarget> *_target;
}

@property(nonatomic, readonly) NSObject<CCSchedulerTarget> *target;

@property(nonatomic, strong) CCTimer *timers;
@property(nonatomic, readonly) BOOL empty;
@property(nonatomic, assign) BOOL paused;
@property(nonatomic, assign) BOOL enableUpdates;

@end


@interface CCTimer (Private)
@property(nonatomic, readwrite) ccTime invokeTime;
@property(nonatomic, readonly) CCTimerBlock block;
@property(nonatomic, readonly) CCScheduledTarget *scheduledTarget;
@property(nonatomic, strong) CCTimer *next;
@property(nonatomic, readwrite) ccTime deltaTime;
@end


@interface CCScheduler (Private) <CCSchedulerTarget>
@end


@implementation CCScheduledTarget {
	CCTimer *_timers;
}

+(void)initialize
{
	UPDATE_SELECTOR = @selector(update:);
	FIXED_UPDATE_SELECTOR = @selector(fixedUpdate:);
}

-(id)initWithTarget:(NSObject<CCSchedulerTarget> *)target
{
	if((self = [super init])){
		_target = target;
	}
	
	return self;
}

static CCTimer *
RemoveRecursive(CCTimer *timer, CCTimer *skip)
{
	if(timer == skip){
		return timer.next;
	} else {
		timer.next = RemoveRecursive(timer.next, skip);
		return timer;
	}
}

-(void)removeTimer:(CCTimer *)timer
{
	_timers = RemoveRecursive(_timers, timer);
}

-(void)invalidateTimers
{
	for(CCTimer *timer = _timers; timer; timer = timer.next) [timer invalidate];
}


-(BOOL)empty
{
	return (_timers == nil && !_enableUpdates);
}

-(void)setPaused:(BOOL)paused
{
	#warning needs to disable things
}

-(void)setEnableUpdates:(BOOL)enableUpdates
{
	_enableUpdates = enableUpdates;
	
	if([_target respondsToSelector:UPDATE_SELECTOR]){
		_update_IMP = (__typeof(_update_IMP))[_target methodForSelector:UPDATE_SELECTOR];
	}
	
	if([_target respondsToSelector:FIXED_UPDATE_SELECTOR]){
		_fixedUpdate_IMP = (__typeof(_update_IMP))[_target methodForSelector:FIXED_UPDATE_SELECTOR];
	}
}

@end


@interface NSNull(CCSchedulerTarget)<CCSchedulerTarget>
@end


@implementation NSNull(CCSchedulerTarget)
-(NSInteger)priority {return NSIntegerMax;}
@end


@implementation CCTimer {
	CCTimerBlock _block;
	CCTimer *_next;
	
	__weak CCScheduler *_scheduler;
	__weak CCScheduledTarget *_scheduledTarget;
}

// A valid block that does nothing.
static CCTimerBlock INVALIDATED_BLOCK = ^(CCTimer *timer){};

-(void)repeatOnceWithInterval:(ccTime)interval
{
	self.repeatCount = 1;
	self.repeatInterval = interval;
}

-(void)invalidate
{
	_block = INVALIDATED_BLOCK;
	_scheduledTarget = nil;
	_repeatCount = 0;
}

@end


@implementation CCTimer(Private)

-(id)initWithDelay:(ccTime)delay scheduler:(CCScheduler *)scheduler scheduledTarget:(CCScheduledTarget *)scheduledTarget block:(CCTimerBlock)block;
{
	if((self = [super init])){
		_deltaTime = delay;
		_invokeTime = scheduler.currentTime + delay;
		_repeatInterval = delay;
		_scheduler = scheduler;
		_scheduledTarget = scheduledTarget;
		_block = [block copy];
	}
	
	return self;
}

-(void)setInvokeTime:(ccTime)invokeTime {_invokeTime = invokeTime;}

-(CCTimerBlock)block {return _block;}
-(CCScheduledTarget *)scheduledTarget {return _scheduledTarget;}

-(CCTimer *)next {return _next;}
-(void)setNext:(CCTimer *)next {_next = next;}

-(void)setDeltaTime:(ccTime)deltaTime {_deltaTime = deltaTime;}

@end


@implementation CCScheduler {
//	NSMutableArray *_heap;
	CFBinaryHeapRef _heap;
	CFMutableDictionaryRef _scheduledTargets;
	
	NSMutableArray *_updates;
	NSMutableArray *_fixedUpdates;
	
	CCTimer *_fixedUpdateTimer;
}

static CFComparisonResult
ComparePriorities(const void *a, const void *b)
{
	NSInteger priority_a = [(__bridge CCTimer *)a scheduledTarget].target.priority;
	NSInteger priority_b = [(__bridge CCTimer *)b scheduledTarget].target.priority;
	
	if(priority_a < priority_b){
		return kCFCompareLessThan;
	} else if(priority_b < priority_a){
		return kCFCompareGreaterThan;
	} else {
		return kCFCompareEqualTo;
	}
}

static CFComparisonResult
CompareTimers(const void *a, const void *b, void *context)
{
	ccTime time_a = [(__bridge CCTimer *)a invokeTime];
	ccTime time_b = [(__bridge CCTimer *)b invokeTime];
	
	if(time_a < time_b){
		return kCFCompareLessThan;
	} else if(time_b < time_a){
		return kCFCompareGreaterThan;
	} else {
		return ComparePriorities(a, b);
	}
}

-(id)init
{
	if((self = [super init])){
		_maxTimeStep = 1.0/10.0;
		
		CFBinaryHeapCallBacks callbacks = {
			.version = 0,
			.retain = NULL,
			.release = NULL,
			.copyDescription = NULL,
			.compare = CompareTimers,
		};
		
		_heap = CFBinaryHeapCreate(NULL, 0, &callbacks, NULL);
		
		_scheduledTargets = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		
		_updates = [NSMutableArray array];
		NSArray *fixedUpdates = _fixedUpdates = [NSMutableArray array];
		
		// Schedule a timer to run the fixedUpdate: methods.
		_fixedUpdateTimer = [self scheduleBlock:^(CCTimer *timer){
			for(int i=0, count=fixedUpdates.count; i<count; i++){
				CCScheduledTarget *scheduledTarget = fixedUpdates[i];
				scheduledTarget->_fixedUpdate_IMP(scheduledTarget->_target, FIXED_UPDATE_SELECTOR, timer.repeatInterval);
			}
		 } forTarget:self withDelay:0];
		 
		 _fixedUpdateTimer.repeatCount = CCTimerRepeatForever;
		 _fixedUpdateTimer.repeatInterval = 1.0/60.0;
	}
	
	return self;
}

-(void)dealloc
{
	CFRelease(_heap);
	CFRelease(_scheduledTargets);
}

-(NSInteger)priority
{
	return NSIntegerMax;
}

-(ccTime)fixedTimeStep {return _fixedUpdateTimer.repeatInterval;}
-(void)setFixedTimeStep:(ccTime)fixedTimeStep {_fixedUpdateTimer.repeatInterval = fixedTimeStep;}

-(CCScheduledTarget *)scheduledTargetForTarget:(NSObject<CCSchedulerTarget> *)target
{
	// Need to transform nil -> NSNulls.
	target = (target == nil ? [NSNull null] : target);
	
	CCScheduledTarget *scheduledTarget = CFDictionaryGetValue(_scheduledTargets, (__bridge CFTypeRef)target);
	if(scheduledTarget == nil){
		scheduledTarget = [[CCScheduledTarget alloc] initWithTarget:target];
		CFDictionarySetValue(_scheduledTargets, (__bridge CFTypeRef)target, (__bridge CFTypeRef)scheduledTarget);
	}
	
	return scheduledTarget;
}

-(CCTimer *)scheduleBlock:(CCTimerBlock)block forTarget:(NSObject<CCSchedulerTarget> *)target withDelay:(ccTime)delay
{
	CCScheduledTarget *scheduledTarget = [self scheduledTargetForTarget:target];
	
	CCTimer *timer = [[CCTimer alloc] initWithDelay:delay scheduler:self scheduledTarget:scheduledTarget block:block];
	CFBinaryHeapAddValue(_heap, CFRetain((__bridge CFTypeRef)timer));
	
	timer.next = scheduledTarget.timers;
	scheduledTarget.timers = timer;
	
	return timer;
}

-(void)updateTo:(ccTime)targetTime
{
	NSAssert(targetTime >= _currentTime, @"Cannot step to a time in the past.");
	
	while(CFBinaryHeapGetCount(_heap) > 0){
		CCTimer *timer = CFBinaryHeapGetMinimum(_heap);
		ccTime invokeTime = timer.invokeTime;
		
		if(invokeTime > targetTime){
			break;
		} else {
			CFBinaryHeapRemoveMinimumValue(_heap);
		}
		
		_currentTime = invokeTime;
		timer.block(timer);
		
		if(timer.repeatCount > 0){
			if(timer.repeatCount < CCTimerRepeatForever) timer.repeatCount--;
			
			ccTime delay = timer.deltaTime = timer.repeatInterval;
			timer.invokeTime += delay;
			
			CFBinaryHeapAddValue(_heap, (__bridge CFTypeRef)timer);
		} else {
			CFRelease((__bridge CFTypeRef)timer);
			
			CCScheduledTarget *scheduledTarget = timer.scheduledTarget;
			[scheduledTarget removeTimer:timer];
			if(scheduledTarget.empty){
				CFDictionaryRemoveValue(_scheduledTargets, (__bridge CFTypeRef)scheduledTarget.target);
			}
		}
	}
	
	_currentTime = targetTime;
}

static NSUInteger
PrioritySearch(NSArray *array, NSInteger priority)
{
	#warning TODO binary search.
	for(int i=0, count=array.count; i<count; i++){
		CCScheduledTarget *scheduledTarget = array[i];
		if(scheduledTarget.target.priority > priority) return i;
	}
	
	return array.count;
}

-(void)scheduleTarget:(NSObject<CCSchedulerTarget> *)target
{
	CCScheduledTarget *scheduledTarget = [self scheduledTargetForTarget:target];
	
	scheduledTarget.enableUpdates = YES;
	NSInteger priority = target.priority;
	
	if(scheduledTarget->_update_IMP){
		[_updates insertObject:scheduledTarget atIndex:PrioritySearch(_updates, priority)];
	}
	
	if(scheduledTarget->_fixedUpdate_IMP){
		[_fixedUpdates insertObject:scheduledTarget atIndex:PrioritySearch(_fixedUpdates, priority)];
	}
}

-(void)unscheduleTarget:(NSObject<CCSchedulerTarget> *)target
{
	CCScheduledTarget *scheduledTarget = [self scheduledTargetForTarget:target];
	
	// Remove the update methods if they are scheduled
	if(scheduledTarget.enableUpdates){
		[_fixedUpdates removeObject:scheduledTarget];
		[_updates removeObject:scheduledTarget];
	}
	
	[scheduledTarget invalidateTimers];
}

-(void)pauseTarget:(NSObject<CCSchedulerTarget> *)target
{
	CCScheduledTarget *scheduledTarget = [self scheduledTargetForTarget:target];
	scheduledTarget.paused = YES;
}

-(BOOL)isTargetPaused:(NSObject<CCSchedulerTarget> *)target
{
	CCScheduledTarget *scheduledTarget = [self scheduledTargetForTarget:target];
	return scheduledTarget.paused;
}

-(void)update:(ccTime)dt
{
	ccTime clampedDelta = MIN(dt, _maxTimeStep);
	[self updateTo:_currentTime + clampedDelta];
	
	// Run the update: methods
	for(int i=0, count=_updates.count; i<count; i++){
		CCScheduledTarget *scheduledTarget = _updates[i];
		scheduledTarget->_update_IMP(scheduledTarget->_target, UPDATE_SELECTOR, clampedDelta);
	}
}

@end
