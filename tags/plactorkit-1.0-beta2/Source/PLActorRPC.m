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

/**
 * Provides remote procedure call services. Utilizes the PLActorMessage TransactionID to provide
 * synchronous message passing support.
 */
@implementation PLActorRPC

/**
 * @internal
 * Filter messages based on their transactionId.
 */
static BOOL receive_txid_filter (id message, void *context) {
    PLActorTxId txid = *((PLActorTxId *) context);
    return ([message transactionId] == txid);
}

/**
 * Send the @a rpcMessage to the given @a process, and synchronously wait for a response
 * with a matching transaction ID.
 *
 * @param rpcMessage Message to send. The messages transactionId will be used to
 * perform a selective receive for the response.
 * @param process Process to which the message will be sent.
 */
+ (id) sendRPC: (PLActorMessage *) rpcMessage toProcess: (id<PLActorProcess>) process {
    PLActorTxId txid;
    id resp;

    /* Messaging yourself is not supported. */
    if (process == [PLActorKit process])
        [NSException raise: PLActorException format: @"Attempted to send an RPC request to the currently running actor process."];

    /* Send the request */
    [process send: rpcMessage];

    /* Wait for a response with a matching txid*/
    txid = [rpcMessage transactionId];

    [PLActorKit receive: &resp usingFilter: &receive_txid_filter filterContext: &txid withTimeout: PLActorTimeWaitForever];

    return resp;
}

@end
