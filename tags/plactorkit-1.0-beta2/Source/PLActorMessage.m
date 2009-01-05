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
 * A reusable base class for messaging. While ActorKit supports messaging with
 * any object, the PLActorMessage class provides generally useful facilities
 * such as unique transaction Ids, automatically determining the message sender,
 * and including message payloads.
 */
@implementation PLActorMessage

/**
 * Create a new message with a nil object payload.
 *
 * The message sender will be set to the current process, and the transaction
 * ID will be set using ActorKit::createTransactionId.
 */
+ (id) message {
    return [[[self alloc] init] autorelease];
}


/**
 * Create a new message with the given object payload. The
 * message sender will be set to the current process, and the transaction
 * ID will be set using ActorKit::createTransactionId.
 *
 * @param object Message payload.
 */
+ (id) messageWithObject: (id) object {
    return [[[self alloc] initWithObject: object] autorelease];
}


/**
 * Create a new message with the given object payload and transaction id. The
 * message sender will be set to the current process
 *
 * @param object Message payload.
 * @param transactionId  Caller defined message transaction ID.
 */
+ (id) messageWithObject: (id) object transactionId: (PLActorTxId) transactionId {
    return [[[self alloc] initWithObject: object transactionId: transactionId] autorelease];
}


/**
 * Initialize with a nil object payload. The
 * message sender will be set to the current process, and the transaction
 * ID will be set using ActorKit::createTransactionId.
 */
- (id) init {
    return [self initWithObject: nil transactionId: [PLActorKit createTransactionId]];
}


/**
 * Initialize with the given object payload. The
 * message sender will be set to the current process, and the transaction
 * ID will be set using ActorKit::createTransactionId.
 *
 * @param object Message payload.
 */
- (id) initWithObject: (id) object {
    return [self initWithObject: object transactionId: [PLActorKit createTransactionId]];
}


/**
 * Initialize with the given object payload and transaction id. The
 * message sender will be set to the current process
 *
 * @param object Message payload.
 * @param transactionId  Caller defined message transaction ID.
 */
- (id) initWithObject: (id) object transactionId: (PLActorTxId) transactionId {
    if ((self = [super init]) == nil)
        return nil;
    
    _sender = [[PLActorKit process] retain];
    _payload = [object retain];
    _txid = transactionId;
    
    return self;
}

- (void) dealloc {
    [_sender release];
    [_payload release];
    
    [super dealloc];
}


/**
 * Return the message sender.
 */
- (id<PLActorProcess>) sender {
    return _sender;
}


/**
 * Return the message contents.
 */
- (id) object {
    return _payload;
}

/**
 * Return the message transaction ID.
 */
- (PLActorTxId) transactionId {
    return _txid;
}

@end
