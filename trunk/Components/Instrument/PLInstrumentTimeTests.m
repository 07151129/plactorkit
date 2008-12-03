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

#import <SenTestingKit/SenTestingKit.h>

#import "PLInstrument.h"

@interface PLInstrumentTimeTests : SenTestCase @end

@implementation PLInstrumentTimeTests

- (void) testTiming {
    PLIAbsoluteTime startTime;
    PLIAbsoluteTime endTime;
    PLITimeInterval interval;

    startTime = PLICurrentTime();
    endTime = PLICurrentTime();

    interval = PLIComputeTimeInterval(startTime, endTime);
    STAssertTrue(interval < (10 * 60 * 100000000UL), @"Interval should be less than 10 minutes.");
}

- (void) testSecondConversion {
    STAssertEquals(UINT64_C(1000000000), PLISecondsToTimeInterval(1), @"Invalid second to nanoseconds conversion.");
}

- (void) testMicrosecondConversion {
    STAssertEquals(1.0, PLITimeIntervalToMicroseconds(1000), @"Invalid nanoseconds to microseconds conversion.");
}

@end
