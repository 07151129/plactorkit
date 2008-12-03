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

#import "PLActorQueueTests.h"

#define CHECK_SUPERCLASS() { \
    if ([self class] == [PLActorQueueTests class]) \
        return; \
    }

/**
 * @internal
 *
 * Re-usable queue tests.
 */
@implementation PLActorQueueTests

/**
 * Set the message queue. Must be set in the test setUp.
 */
- (void) setQueue: (id<PLActorQueue>) queue {
    if (_q != nil)
        [_q release];

    _q = [queue retain];
}

- (void) dealloc {
    [_q release];

    [super dealloc];
}

/**
 * Test deliver & receive.
 */
- (void) testDeliver {
    CHECK_SUPERCLASS();

    PLActorMessage *receivedMsg;

    [_q send: [PLActorMessage messageWithObject: @"Hello"]];
    STAssertTrue([_q receive: &receivedMsg usingFilter: NULL filterContext: NULL withTimeout: -1], @"Receive failed");
    STAssertEquals([receivedMsg object], @"Hello", @"Received message invalid");
}

/* Simple equality filter */
static BOOL equality_filter (id obj, void *context) {
    return [[obj object] isEqual: context];
}

/**
 * Test receive timeout
 */
- (void) testReceiveTimout {
    CHECK_SUPERCLASS();

    /* Will block forever if timeout is not implemented */
    PLActorMessage *msg;
    STAssertFalse([_q receive: &msg usingFilter: NULL filterContext: NULL withTimeout: 5], @"Timeout should return NO");
}

/**
 * Verify message ordering.
 */
- (void) testOrdering {
    CHECK_SUPERCLASS();

    PLActorMessage *msg;
    
    /* Send the messages */
    [_q send: [PLActorMessage messageWithObject: @"Hello"]];
    [_q send: [PLActorMessage messageWithObject: @"Goodbye"]];
    
    STAssertTrue([_q receive: &msg usingFilter: NULL filterContext: NULL withTimeout: PLActorTimeWaitForever], @"Receive failed");
    STAssertTrue([[msg object] isEqual: @"Hello"], @"Received incorrect first message: %@", [msg object]);
    
    STAssertTrue([_q receive: &msg usingFilter: NULL filterContext: NULL withTimeout: PLActorTimeWaitForever], @"Receive failed");
    STAssertTrue([[msg object] isEqual: @"Goodbye"], @"Received incorrect last message: %@", [msg object]);
}

/**
 * Verify selective reception.
 */
- (void) testSelectiveReceive {
    CHECK_SUPERCLASS();

    PLActorMessage *receivedMsg;
    
    /* Send the message */
    [_q send: [PLActorMessage messageWithObject: @"Hello"]];
    [_q send: [PLActorMessage messageWithObject: @"Goodbye"]];
    
    /* Now wait for the echo */
    BOOL result = [_q receive: &receivedMsg 
                 usingFilter: &equality_filter 
               filterContext: @"Goodbye"
                 withTimeout: PLActorTimeWaitForever];
    STAssertTrue(result, @"Received failed");
    
    STAssertTrue([[receivedMsg object] isEqual: @"Goodbye"], @"Invalid message returned, selective receive incorrect");

    /* Now fetch the Hello */
    STAssertTrue([_q receive: &receivedMsg usingFilter: NULL filterContext: NULL withTimeout: PLActorTimeWaitForever], @"Receive failed");
    STAssertTrue([[receivedMsg object] isEqual: @"Hello"], @"Invalid message returned, selective receive incorrect");
}



@end
