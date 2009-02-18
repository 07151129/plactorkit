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


#import <SenTestingKit/SenTestingKit.h>
#import "ActorKit.h"

@interface PLRunloopRPCProxyTests : SenTestCase {
@private
    /** Running runloop */
    NSRunLoop *_loop;

    /** Cancellation flag for background thread */
    BOOL _cancelled;

    /** Lock for cancellation flag */
    pthread_mutex_t _lock;

    /** Finish condition */
    pthread_cond_t _cond;
}
@end

@implementation PLRunloopRPCProxyTests

- (void) setUp {
    pthread_mutex_init(&_lock, NULL);
    pthread_cond_init(&_cond, NULL);
    
    /* Make sure no messages are pending */
    [[PLActorKit threadProcess] flush];

    /* Kick off the runloop thread, and wait for it to signal operation */
    pthread_mutex_lock(&_lock);
    [NSThread detachNewThreadSelector: @selector(runLoop) toTarget: self withObject: nil];
    pthread_cond_wait(&_cond, &_lock);
    pthread_mutex_unlock(&_lock);
}

- (void) tearDown {
    /* Request that the runloop stop */
    pthread_mutex_lock(&_lock);
    _cancelled = YES;

    /* Wait for thread termination */
    pthread_cond_wait(&_cond, &_lock);

    /* Abandon the lock */
    pthread_mutex_unlock(&_lock);

    [_loop release];
    
    pthread_mutex_destroy(&_lock);
    pthread_cond_destroy(&_cond);
}

- (void) runLoop {
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    /* Record the thread and signal any waiting threads to inform them
     * that we've started successfully */
    pthread_mutex_lock(&_lock);
    _loop = [runLoop retain];
    pthread_cond_signal(&_cond);
    pthread_mutex_unlock(&_lock);

    /* Spin the runloop (quickly) */
    while (YES) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [runLoop runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01f]];
        [pool release];

        pthread_mutex_lock(&_lock);
        if (_cancelled) {
            /* Inform all threads waiting, and exit the loop */
            pthread_cond_broadcast(&_cond);
            pthread_mutex_unlock(&_lock);
            break;
        }
        pthread_mutex_unlock(&_lock);
    }
}

// simple echo method to test the actor
- (NSString *) echo: (NSString *) text {
    return text;
}

// A non-synchronous echo method, sends reply directly using actorkit
- (oneway void) onewayEcho: (NSString *) text sender: (id<PLActorProcess>) sender {
    [sender send: text];
}


- (void) testSynchronousMessaging {
    PLRunloopRPCProxyTests *proxy = [PLRunloopRPCProxy proxyWithTarget: self runLoop: _loop];
    
    NSString *result = [proxy echo: @"test"];
    STAssertTrue([@"test" isEqual: result], @"Actor did not echo request, returned %@", result);
}


- (void) testAsynchronousMessaging {
    PLRunloopRPCProxyTests *proxy = [PLRunloopRPCProxy proxyWithTarget: self runLoop: _loop];
    [proxy onewayEcho: @"Text" sender: [PLActorKit process]];

    /* Wait for and test the response */
    NSString *text = [PLActorKit receive];
    STAssertTrue([@"Text" isEqual: text], @"Actor did not echo request, returned %@", text);
}

@end
