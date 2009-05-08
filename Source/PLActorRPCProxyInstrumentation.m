/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 * Copyright (c) 2008-2009 Plausible Labs Cooperative, Inc.
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

@interface PLActorRPCProxyInstrumentation : PLInstrumentCase
@end

#define ITERATIONS 1000000

@implementation PLActorRPCProxyInstrumentation

- (void) echo {
    // Do nothing
}

/**
 * Run ITERATIONS of synchonous Objective-C -[PLActorRPCProxyInstrumentation echo] method calls
 * with the given destination instance.
 */
- (PLInstrumentResult *) runWithDestination: (PLActorRPCProxyInstrumentation *) dest {
    PLIAbsoluteTime start, finish;
    
    start = PLICurrentTime();
    for (int i = 0 ; i < ITERATIONS; i++) {
        [dest echo];
    }
    finish = PLICurrentTime();
    
    return [PLInstrumentResult resultWithStartTime: start endTime: finish iterations: ITERATIONS];
}

/**
 * Instrument raw (non-proxy) Objective-C send/receive, for comparison purposes.
 */
- (PLInstrumentResult *) instrumentRawMessaging {
    return [self runWithDestination: self];
}

/**
 * Instrument proxy-based Objective-C send/receive.
 */
- (PLInstrumentResult *) instrumentActorRPCProxyMessaging {
    return [self runWithDestination: [PLActorRPCProxy proxyWithTarget: self]];
}

@end
