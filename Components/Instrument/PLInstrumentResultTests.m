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

#import "PLInstrument.h"

#import <SenTestingKit/SenTestingKit.h>

@interface PLInstrumentResultTests : SenTestCase @end

@implementation PLInstrumentResultTests

- (void) testIterationsPerInterval {
    PLInstrumentResult *result = [PLInstrumentResult resultWithRunTime: PLISecondsToTimeInterval(10) iterations: 10];

    STAssertEquals(1.0, [result iterationsPerInterval: PLISecondsToTimeInterval(1)], @"Should have executed once per second");
    STAssertEquals(20.0, [result iterationsPerInterval: PLISecondsToTimeInterval(20)], @"Should have scaled result to 20 executions per 20 seconds");

}

- (void) testTimePerIteration {
    PLInstrumentResult *result = [PLInstrumentResult resultWithRunTime: PLISecondsToTimeInterval(10) iterations: 20];

    STAssertEquals(UINT64_C(500000000), [result intervalPerIteration], @"Should record .5 seconds per iteration");
}

@end
