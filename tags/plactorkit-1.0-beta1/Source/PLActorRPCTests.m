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

@interface PLActorRPCTests : SenTestCase @end


@implementation PLActorRPCTests

/* RPC echo actor, sends a response with a bad TXID, and then a good TXID. */
- (void) threadedEcho {
    PLActorMessage *msg = [PLActorKit receive];
    PLActorMessage *badResp = [PLActorMessage messageWithObject: [msg object] transactionId: [msg transactionId] + 1];
    PLActorMessage *goodResp = [PLActorMessage messageWithObject: [msg object] transactionId: [msg transactionId]];

    [[msg sender] send: badResp];
    [[msg sender] send: goodResp];
}

- (void) testRpcSend {
    id<PLActorProcess> proc = [PLActorKit spawnWithTarget: self selector: @selector(threadedEcho)];
    
    /* Send a message */
    PLActorMessage *resp = [PLActorRPC sendRPC: [PLActorMessage messageWithObject: @"Hello" transactionId: [PLActorKit createTransactionId]] toProcess: proc];
    
    /* Was the correct response acquired? */
    STAssertTrue([[resp object] isEqual: @"Hello"], @"Expected response was not returned.");
}

@end
