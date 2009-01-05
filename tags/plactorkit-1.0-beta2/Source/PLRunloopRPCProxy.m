/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ActorKit.h"
#import "PLActorObjC.h"

/**
 * The PLRunloopRPCProxy provides transparent invocation of Objective-C messages
 * on a given runloop. This allows concurrent threads to safely call methods on
 * runloop-driven receivers.
 *
 * This is primarily useful in bridging the gap between thread-based actors and Cocoa's main runloop.
 * By using the PLRunloopRPCProxy as an adapter, you may pass the proxy directly to other threads.
 * Any methods called directly on those threads will be transparently proxied to the Cocoa
 * runloop (the main run loop, or otherwise).
 */
@implementation PLRunloopRPCProxy

/**
 * Create an RPC proxy with the provided target object. All messages to the proxy will be
 * delivered on the current runloop, as returned by +[NSRunLoop currentRunLoop]
 */
+ (id) proxyWithTarget: (NSObject *) target {
    return [[[self alloc] initWithTarget: target runLoop: [NSRunLoop currentRunLoop]] autorelease];
}


/**
 * Create an RPC proxy with the given target object. All messages to the proxy will be
 * delivered on the provided runloop.
 */
+ (id) proxyWithTarget: (NSObject *) target runLoop: (NSRunLoop *) runLoop {
    return [[[self alloc] initWithTarget: target runLoop: runLoop] autorelease];
}

/**
 * Create an RPC proxy with the provided target and runloop objects. All messages to the proxy will be
 * delivered on the provided runloop.
 *
 * @param target Message target.
 * @param runLoop Run loop on which RPC invocations will occur.
 */
- (id) initWithTarget: (NSObject *) target runLoop: (NSRunLoop *) runLoop {
    /* Retain arguments */
    _target = [target retain];
    _targetClass = [[target class] retain];
    _runLoop = [runLoop retain];

    return self;
}

- (void) dealloc {
    [_target release];
    [_targetClass release];
    [_runLoop release];

    [super dealloc];
}


// abstract NSProxy method
- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector {
    return [_target methodSignatureForSelector: aSelector];
}

/**
 * @internal
 * Invoker, simply runs the invocation on the current thread.
 */
- (void) _invoke: (NSInvocation *) invocation {
    [invocation invoke];
}

/**
 * @internal
 * Non-blocking invoker, simply runs the invocation on the current thread.
 */
static void perform_invocation (void *info) {
    NSInvocation *invocation = info;
    [invocation invoke];
}

/**
 * @internal
 * Blocking invoker, runs the invocation on the current thread and then signals
 * any waiting thread
 */
static void perform_blocking_invocation (void *info) {
    PLActorMessage *msg = info;

    /* The message contains the invocation object as its payload */
    [[msg object] invoke];

    /* Signal completion to the sender (just reply with the same message) */
    [[msg sender] send: msg];
}

/**
 * @internal
 * Filter return messages looking for a matching invocation id.
 *
 * @param msg Incoming PLActorMessage
 * @param filterContext Original PLActorMessage
 */
static BOOL blocking_invocation_reply_filter (id msg, void *filterContext) {
    PLActorMessage *origMsg = filterContext;
    
    if ([msg transactionId] == [origMsg transactionId])
        return YES;

    return NO;
}

// abstract NSProxy method
- (void) forwardInvocation: (NSInvocation *) invocation {
    BOOL isBlocking;

    /* Set the target. MUST be called prior to retainArguments, or the invocation
     * will retain the proxy object! */
    [invocation setTarget: _target];
    
    /* Need to retain the arguments, since we're passing to another async thread */
    [invocation retainArguments];

    /* Test if we should block */
    char methodBuf[1];
    Method m = class_getInstanceMethod(_targetClass, [invocation selector]);
    method_getReturnType(m, methodBuf, sizeof(methodBuf));
    
    if (methodBuf[0] == _PL_C_ONEWAY) {
        /* Oneway, non-blocking */
        isBlocking = NO;
    } else {
        /* Synchronous, blocking */
        isBlocking = YES;
    }

    /* Set up the runloop source context */
    CFRunLoopSourceContext ctx;
    ctx.version = 0;
    ctx.retain = &CFRetain;
    ctx.release = &CFRelease;
    ctx.copyDescription = CFCopyDescription;
    ctx.equal = CFEqual;
    ctx.hash = CFHash;
    ctx.schedule = NULL;
    ctx.cancel = NULL;

    if (isBlocking) {
        /* If blocking, use Actor RPC to await a reply */
        ctx.perform = perform_blocking_invocation;
        ctx.info = [PLActorMessage messageWithObject: invocation];
    } else {
        /* If non-blocking, simple direct invocation is sufficient */
        ctx.perform = perform_invocation;
        ctx.info = invocation;
    }

    /* Create, add, and signal the new source */
    CFRunLoopSourceRef runSrc = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &ctx);
    CFRunLoopAddSource([_runLoop getCFRunLoop], runSrc, kCFRunLoopCommonModes);
    CFRunLoopSourceSignal(runSrc);
    CFRelease(runSrc);

    /* If blocking, await a message reply using a matching transaction id. This signals
     * that invocation has completed */
    if (isBlocking) {
        PLActorMessage *msg;
        [PLActorKit receive: &msg usingFilter: blocking_invocation_reply_filter filterContext: ctx.info withTimeout: PLActorTimeWaitForever];
    }
}


@end
