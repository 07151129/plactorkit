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

#import <Foundation/Foundation.h>

#import <stdint.h>

#import <mach/mach.h>
#import <mach/mach_time.h>

/** An opaque implementation-defined time measurement. This measurement may not remain valid across invocations
 * and must not be stored. */
typedef uint64_t PLIAbsoluteTime;

/** A time interval, in nanoseconds. */
typedef uint64_t PLITimeInterval;

/**
 * Convert seconds to nanosecond time interval.
 */
#define PLISecondsToTimeInterval(seconds) ((PLITimeInterval) (UINT64_C(seconds) * UINT64_C(1000000000)))

/**
 * Convert nanosecond time interval to microseconds, returning a floating point (double) value.
 */
#define PLITimeIntervalToMicroseconds(interval) ((double) interval / 1000.0)

/**
 * Return the current time as an opaque absolute
 * time value.
 */
static inline PLIAbsoluteTime PLICurrentTime () {
    return mach_absolute_time();
}

PLITimeInterval PLIComputeTimeInterval (PLIAbsoluteTime startTime, PLIAbsoluteTime endTime);
