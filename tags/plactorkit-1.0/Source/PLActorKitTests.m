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

@interface PLActorKitTests : SenTestCase
@end


@interface PLActorKitMessageTests : SenTestCase @end

@implementation PLActorKitTests

/* Simple echo actor */
- (void) threadedEcho {
    PLActorMessage *msg = [PLActorKit receive];
    PLActorMessage *resp = [PLActorMessage messageWithObject: [msg object]];

    [[msg sender] send: resp];
}

- (void) testSpawn {
    id<PLActorProcess> proc = [PLActorKit spawnWithTarget: self selector: @selector(threadedEcho)];

    /* Send a message */
    [proc send: [[[PLActorMessage alloc] initWithObject: @"Hello"] autorelease]];

    /* Wait for it to come back to us */
    STAssertEquals([[PLActorKit receive] object], @"Hello", @"Message was not returned");
}

/* Simple echo actor */
- (void) threadedEchoWithArg: (id) arg {
    PLActorMessage *msg = [PLActorKit receive];
    
    NSString* argString = arg;
    NSString* msgString = [msg object];
    NSString* respString = [msgString stringByAppendingString: argString];
    PLActorMessage *resp = [PLActorMessage messageWithObject: respString];
    
    [[msg sender] send: resp];
}

- (void) testSpawnWithArg {
    id<PLActorProcess> proc = [PLActorKit spawnWithTarget: self selector: @selector(threadedEchoWithArg:) object: @"-Suffix"];
    
    /* Send a message */
    [proc send: [PLActorMessage messageWithObject: @"Hello"]];
    
    /* Wait for it to come back to us */
    STAssertEqualObjects([[PLActorKit receive] object], @"Hello-Suffix", @"Message was not returned");
}

@end


@implementation PLActorKitMessageTests

- (void) testTransactionId {
    PLActorMessage *msg1 = [PLActorMessage message];
    PLActorMessage *msg2 = [PLActorMessage message];

    STAssertTrue([msg1 transactionId] != [msg2 transactionId], @"Transaction IDs were equal");
}

@end
