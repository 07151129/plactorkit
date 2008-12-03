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

#import "PLInstrumentResult.h"

/**
 * Result returns from all instrumentation methods. Records the instrumentation
 * start time, end time, and total number of iterations.
 */
@implementation PLInstrumentResult


/**
 * Allocate and initialize an instrumentation result.
 *
 * @param startTime The absolute time at which iterations were started.
 * @param endTime The absolute time at which all iterations were completed.
 * @param iterations The number of iterations performed between startTime and endTime.
 */
+ (id) resultWithStartTime: (PLIAbsoluteTime) startTime endTime: (PLIAbsoluteTime) endTime iterations: (unsigned long) iterations {
    return [[[self alloc] initWithStartTime: startTime endTime: endTime iterations: iterations] autorelease];
}


/**
 * Allocate and initialize an instrumentation result.
 *
 * @param runTime The total instrumentation runtime.
 * @param iterations The number of iterations performed during runTime.
 */
+ (id) resultWithRunTime: (PLITimeInterval) runTime iterations: (unsigned long) iterations {
    return [[[self alloc] initWithRunTime: runTime iterations: iterations] autorelease];
}


/**
 * Initialize the instrumentation result.
 *
 * @param startTime The absolute time at which iterations were started.
 * @param endTime The absolute time at which all iterations were completed.
 * @param iterations The number of iterations performed between startTime and endTime.
 */
- (id) initWithStartTime: (PLIAbsoluteTime) startTime endTime: (PLIAbsoluteTime) endTime iterations: (unsigned long) iterations {
    return [self initWithRunTime: PLIComputeTimeInterval(startTime, endTime) iterations: iterations];
}


/**
 * Initialize the instrumentation result.
 *
 * @param runTime The total instrumentation runtime.
 * @param iterations The number of iterations performed during runTime.
 */
- (id) initWithRunTime: (PLITimeInterval) runTime iterations: (unsigned long) iterations {
    if ((self = [super init]) == nil)
        return nil;

    _totalTime = runTime;
    _iterations = iterations;

    if (_totalTime == 0)
        [NSException raise: NSInvalidArgumentException format: @"Instrumentation run time is 0"];

    if (_iterations == 0)
        [NSException raise: NSInvalidArgumentException format: @"Instrumentation iteration count is 0"];

    return self;
}


/**
 * Return the average number of iterations completed per given time interval.
 */
- (double) iterationsPerInterval: (PLITimeInterval) timeInterval {
    double scale = ((double) timeInterval) / ((double) _totalTime);

    return ((double) _iterations) * scale;
}

/**
 * Return the average number of nanoseconds elapsed per iteration.
 */
- (PLITimeInterval) intervalPerIteration {
    return _totalTime / _iterations;
}

@end
