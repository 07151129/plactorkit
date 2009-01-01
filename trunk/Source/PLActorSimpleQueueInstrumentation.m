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

#import <PLInstrument/PLInstrument.h>
#import "PLActorQueueInstruments.h"

@interface PLActorSimpleQueueInstrumentation : PLInstrumentCase {
@private
    id<PLActorQueue> _queue;
    PLActorQueueInstruments *_instruments;
}
@end

@implementation PLActorSimpleQueueInstrumentation

- (void) setUp {
    _queue = [[PLActorSimpleQueue alloc] init];
    _instruments = [[PLActorQueueInstruments alloc] init];
}

- (void) tearDown {
    [_queue release];
    [_instruments release];
}

/**
 * Measure send performance with one concurrent sender and receiver.
 */
- (PLInstrumentResult *) instrumentOneSender {
    return [_instruments runWithQueue: _queue threadCount: 1];
}

/**
 * Measure send performance with two concurrent senders and one receiver.
 */
- (PLInstrumentResult *) instrumentTwoSenders {
    return [_instruments runWithQueue: _queue threadCount: 2];
}

/**
 * Measure send performance with four concurrent senders and one receiver.
 */
- (PLInstrumentResult *) instrumentFourSenders {
    return [_instruments runWithQueue: _queue threadCount: 4];
}

/**
 * Measure send performance with eight concurrent senders and one receiver.
 */
- (PLInstrumentResult *) instrumentEightSenders {
    return [_instruments runWithQueue: _queue threadCount: 8];
}


@end
