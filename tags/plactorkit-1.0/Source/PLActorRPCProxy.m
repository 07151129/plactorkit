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
 * @internal
 * Defined actor commands.
 */
typedef enum {
    /** Shut down the actor */
    PROXY_COMMAND_SHUTDOWN,
    
    /** Invocation request */
    PROXY_COMMAND_INVOKE
} proxy_command_t;

@interface PLActorRPCProxyMessage : PLActorMessage {
@public
    /** Actor command */
    proxy_command_t command;

    /** YES if the message is oneway asynchronous, NO otherwise */
    BOOL oneway;
}
@end


@interface PLActorRPCProxyWorker : NSObject {
@private
    /** Invocation target */
    NSObject *_target;
    
    /** Cached target class */
    Class _targetClass;

    /** Actor process */
    id<PLActorProcess> _process;
}

- (id) initWithTarget: (NSObject *) target;
- (void) invoke: (NSInvocation *) invocation;
- (void) stop;

@end


/**
 * The PLActorProxy provides transparent invocation of Objective-C messages
 * on a local object, using ActorKit mailboxes to ensure synchronous message
 * delivery.
 */
@implementation PLActorRPCProxy

/**
 * Create an RPC proxy with the provided target object. A new actor thread will be
 * automatically spawned, and all messages to the proxy will be delivered to the actor.
 */
+ (id) proxyWithTarget: (NSObject *) target {
    return [[[self alloc] initWithTarget: target] autorelease];
}

/**
 * Initialize the RPC proxy with the provided target object. A new actor thread will be
 * automatically spawned, and all messages to the proxy will be delivered to the actor.
 */
- (id) initWithTarget: (NSObject *) target {
    _target = [target retain];
    _actor = [[PLActorRPCProxyWorker alloc] initWithTarget: target];

    return self;
}

- (void) dealloc {
    [_target release];

    [_actor stop];
    [_actor release];

    [super dealloc];
}

// abstract NSProxy method
- (NSMethodSignature *) methodSignatureForSelector: (SEL) aSelector {
    return [_target methodSignatureForSelector: aSelector];
}

// abstract NSProxy method
- (void) forwardInvocation: (NSInvocation *) anInvocation {
    [_actor invoke: anInvocation];
}

@end

@implementation PLActorRPCProxyMessage @end

/**
 * @internal
 *
 * Receives invocation messages from the PLActorRPCProxy and dispatches the
 * invocation on the actor thread.
 */
@implementation PLActorRPCProxyWorker

/**
 * Initialize a new invocation proxy worker. All methods are invoked
 * on the provided target
 */
- (id) initWithTarget: (NSObject *) target {
    if ((self = [super init]) == nil)
        return nil;

    _target = [target retain];
    _targetClass = [[target class] retain];
    _process = [[PLActorKit spawnWithTarget: self selector: @selector(receive)] retain];
    return self;
}

- (void) dealloc {
    [_target release];
    [_targetClass release];
    [_process release];
    
    [super dealloc];
}


/**
 * Stop the running actor. Once stopped, no further methods should be called.
 */
- (void) stop {
    /* Request termination */
    PLActorRPCProxyMessage *msg = [PLActorRPCProxyMessage message];
    msg->command = PROXY_COMMAND_SHUTDOWN;
    
    [_process send: msg];
    [_process release];
    _process = nil;
}

/**
 * Run an invocation on the actor thread.
 */
- (void) invoke: (NSInvocation *) invocation {
    /* Set the target. MUST be called prior to retainArguments, or the invocation
     * will retain the proxy object! */
    [invocation setTarget: _target];

    /* Need to retain the arguments, since we're passing to another async thread */
    [invocation retainArguments];

    /* Create the message */
    PLActorRPCProxyMessage *msg = [[PLActorRPCProxyMessage alloc] initWithObject: invocation];
    msg->command = PROXY_COMMAND_INVOKE;
    
    /* Test if we should block and send the message accordingly */
    char methodBuf[1];
    Method m = class_getInstanceMethod(_targetClass, [invocation selector]);
    method_getReturnType(m, methodBuf, sizeof(methodBuf));

    if (methodBuf[0] == _PL_C_ONEWAY) {
        /* Oneway, non-blocking */
        msg->oneway = YES;
        [_process send: msg];
    } else {
        /* Synchronous, blocking */
        msg->oneway = NO;
        [PLActorRPC sendRPC: msg toProcess: _process];
    }

    /* Can now release the message */
    [msg release];
}

- (void) receive {
    /* To ensure that received messages are not leaked, the whole loop must be wrapped in an
     * autorelease pool.
     *
     * We create one here, and then drop and reinitialize
     * the pool through every receive loop */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    /* Receive loop */
    PLActorRPCProxyMessage *msg;
    while ((msg = [PLActorKit receive]) != nil) {        
        /* Handle the command */
        switch (msg->command) {                
            /* Handle shutdown requests */
            case PROXY_COMMAND_SHUTDOWN:

                /* Simply exit the receive loop */
                goto finished;

            case PROXY_COMMAND_INVOKE:
                /* Run the invocation */
                [[msg object] invoke];

                /* ACK the message if necessary. We can just re-use the original message */
                if (!msg->oneway) {
                    [[msg sender] send: msg];
                }
                break;
            default:
                NSLog(@"Unhandled message received: %@, obj: %@", msg, [msg object]);
                break;
        }
        
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
    }

finished:
    [pool release];

    return;
}


@end