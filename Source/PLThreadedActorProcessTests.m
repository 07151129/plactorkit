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

@interface PLThreadedActorProcessTests : SenTestCase @end

@implementation PLThreadedActorProcessTests

- (void) actor {
    /* Simple echo actor. Receive one message, send a reply, exit */
    PLActorMessage *msg = [PLActorKit receive];
    [[msg sender] send: [PLActorMessage messageWithObject: [msg object]]];
}

- (void) testInit {
    PLThreadedActorProcess *proc = [[PLThreadedActorProcess alloc] initWithTarget: self selector: @selector(actor)];

    /* Try running it */
    [proc run];

    /* Verify that it is running */
    [proc send: [PLActorMessage messageWithObject: @"Hello"]];
    PLActorMessage *msg = [PLActorKit receive];
    STAssertEquals([msg object], @"Hello", @"Did not receive expected message contents");

    /* And release it */
    [proc release];
}

@end
