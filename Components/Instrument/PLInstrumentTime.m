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

#import "PLInstrumentTime.h"

static mach_timebase_info_data_t TIMEBASE_INFO;

static __attribute__((constructor)) void init_timebase () {
    mach_timebase_info(&TIMEBASE_INFO);
}

/**
 * Return the time interval, in nanoseconds, between the start and end time.
 *
 * @param startTime The start time.
 * @param endTime The end time.
 *
 * @warning
 * This function is intended to be used for instrumentation timing. Sufficiently large time
 * intervals (eg, weeks, months) may result in an internal overflow.
 */
PLITimeInterval PLIComputeTimeInterval (PLIAbsoluteTime startTime, PLIAbsoluteTime endTime) {
    PLIAbsoluteTime elapsed;

    /* Compute the absolute time difference */
    elapsed = endTime - startTime;

    /* Convert to nanoseconds. May overflow */
    return (elapsed * TIMEBASE_INFO.numer / TIMEBASE_INFO.denom);
}