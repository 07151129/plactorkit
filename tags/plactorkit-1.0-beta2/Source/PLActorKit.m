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

/** @internal
 * Mailbox for the current thread */
pthread_key_t _thread_process;


/** @internal Release thread mailbox on thread exit */
static void thread_process_destructor (void *value) {
    id proc = value;
    [proc release];
}


/**
 * Provides support for spawning new actors and receiving
 * actor messages.
 */
@implementation PLActorKit

+ (void) initialize {
    [super initialize];

    pthread_key_create(&_thread_process, &thread_process_destructor);
}


/**
 * Return your process id. Every actor in the system,
 * including your main thread's run loop, maintains a
 * unique process instance.
 */
+ (id<PLActorProcess>) process {
    return [self threadProcess];
}


/**
 * @internal
 * Set the current thread's mailbox
 */
+ (void) setThreadProcess: (id<PLActorLocalProcess>) mailbox {
    assert(pthread_getspecific(_thread_process) == nil);

    pthread_setspecific(_thread_process, [mailbox retain]);
}

/**
 * @internal
 * Get the current thread's mailbox.
 */
+ (id<PLActorLocalProcess>) threadProcess {
    id<PLActorLocalProcess> proc = pthread_getspecific(_thread_process);

    /* Simple case (registered mailbox) */
    if (proc != nil)
        return proc;

    /* No process registered, create one */
    proc = [[PLSimpleActorProcess alloc] init];
    [self setThreadProcess: proc];

    return proc;
}

/**
 * Spawn a new actor process.
 *
 * @param target The object to which the message specified by selector is sent.
 * @param selector The message to send to target. This selector must accept no arguments.
 */
+ (id<PLActorProcess>) spawnWithTarget: (id) target selector: (SEL) selector {
    PLThreadedActorProcess *proc;
    
    proc = [[[PLThreadedActorProcess alloc] initWithTarget: target selector: selector] autorelease];
    [proc run];

    return proc;
}

/**
 * Spawn a new actor process with the provided method argument.
 *
 * @param target The object to which the message specified by selector is sent.
 * @param selector The message to send to target. This selector must accept exactly one argument.
 * @param object The object to pass as an argument.
 */
+ (id<PLActorProcess>) spawnWithTarget: (id) target selector: (SEL) selector object: (id) object {
    PLThreadedActorProcess *proc;
    
    proc = [[[PLThreadedActorProcess alloc] initWithTarget: target selector: selector object: object] autorelease];
    [proc run];
    
    return proc;
}



/**
 * Receive a message.
 */
+ (id) receive {
    id msg;
    [self receive: &msg usingFilter: NULL filterContext: NULL withTimeout: PLActorTimeWaitForever];
    return msg;
}


/**
 * Receive a message with the given timeout.
 *
 * @param message Received message will be stored in the provided pointer, or set to nil if timeout is was reached.
 * @param timeout Number of milliseconds to wait. If 0, will return immediately. If -1, will wait forever.
 * @return Returns YES if a message was received, NO if timeout was reached and no message was received.
 */
+ (BOOL) receive: (id *) message withTimeout: (PLActorTimeInterval) timeout {
    return [self receive: message usingFilter: NULL filterContext: NULL withTimeout: timeout];
}


#ifdef HAVE_NSPREDICATE

/**
 * Perform a selective receive, using predicate to select the first matching queued message.
 *
 * @param predicate Message filter predicate
 * @return Returns the matching message
 */
+ (id) receiveUsingPredicate: (NSPredicate *) predicate {
    id msg;
    [self receive: &msg usingPredicate: predicate withTimeout: PLActorTimeWaitForever];
    return msg;
}

/**
 * @internal
 * A receive filter that implements NSPredicate matching.
 */
static BOOL predicate_receive_filter (id obj, void *context) {
    NSPredicate *predicate = (NSPredicate *) context;
    return [predicate evaluateWithObject: obj];
}

/**
 * Perform a selective receive, using predicate to select the first matching queued message.
 *
 * @param message Received message will be stored in the provided pointer, or set to nil if timeout is was reached.
 * @param predicate Message filter predicate
 * @param timeout Number of milliseconds to wait. If 0, will return immediately. If -1, will wait forever.
 * @return Returns YES if a message was received, NO if timeout was reached and no message was received.
 */
+ (BOOL) receive: (id *) message usingPredicate: (NSPredicate *) predicate withTimeout: (PLActorTimeInterval) timeout {
    return [self receive: message usingFilter: &predicate_receive_filter filterContext: predicate withTimeout: timeout];
}

#endif /* HAVE_NSPREDICATE */

/**
 * Perform a selective receive, using the provided filter function to select the first matching queued message.
 *
 * @param message Received message will be stored in the provided pointer, or set to nil if timeout is was reached.
 * @param filter Message filter function.
 * @param filterContext Message filter context.
 * @param timeout Number of milliseconds to wait. If 0, will return immediately. If -1, will wait forever.
 * @return Returns YES if a message was received, NO if timeout was reached and no message was received.
 */
+ (BOOL) receive: (id *) message usingFilter: (plactor_receive_filter_t) filter filterContext: (void *) filterContext withTimeout: (PLActorTimeInterval) timeout {
    return [[self threadProcess] receive: message 
                             usingFilter: filter
                           filterContext: filterContext
                             withTimeout: timeout];
}

/**
 * Generate a unique transaction ID; the ID will be unique within the current actor process.
 *
 * The TXID may be used to differentiate messages, such as RPC requests.
 *
 * @note The generator will roll-over after 2^32-1 IDs are generated.
 */
+ (PLActorTxId) createTransactionId {
    return [[self threadProcess] createTransactionId];
}

@end
