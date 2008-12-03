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

@interface PLInstrumentRunnerTests : SenTestCase @end

@interface PLInstrumentRunnerTestsMockHandler : SenTestCase <PLInstrumentResultHandler> {
@public
    BOOL ranStart;

    BOOL ranFinish;
    
    BOOL skippedMethod;
    
    BOOL ranTestMethod;
}

@end

@interface PLInstrumentRunnerTestsMockCase : PLInstrumentCase {
@public
    BOOL ranSetup;

    BOOL ranTearDown;

    BOOL ranTestMethod;
}

- (void) setUp;

@end

/*
 * Simple implementation that flags methods that have
 * been called
 */
@implementation PLInstrumentRunnerTestsMockCase

- (void) setUp {
    self->ranSetup = YES;
}

- (void) tearDown {
    self->ranTearDown = YES;
}

- (PLInstrumentResult *) instrumentSomething {
    self->ranTestMethod = YES;

    return [PLInstrumentResult resultWithRunTime: PLISecondsToTimeInterval(1) iterations: 1];
}

- (void) instrumentBadInstrument {
}

@end

/*
 * Simple implementation that flags methods that have been called.
 */
@implementation PLInstrumentRunnerTestsMockHandler

// from PLInstrumentResultHandler protocol
- (void) willExecuteInstrumentationSuite: (PLInstrumentCase *) instrumentation {
    STAssertTrue([instrumentation isKindOfClass: [PLInstrumentRunnerTestsMockCase class]], @"Unexpected suite");
    self->ranStart = YES;
}


// from PLInstrumentResultHandler protocol
- (void) didExecuteInstrumentationSuite: (PLInstrumentCase *) instrumentation {
    STAssertTrue([instrumentation isKindOfClass: [PLInstrumentRunnerTestsMockCase class]], @"Unexpected suite");
    self->ranFinish = YES;
}

- (void) didSkipInstrumentationCase: (PLInstrumentCase *) instrumentation selector: (SEL) selector reason: (NSString *) reason {
    self->skippedMethod = YES;
}

// from PLInstrumentResultHandler protocol
- (void) didExecuteInstrumentationCase: (PLInstrumentCase *) instrumentation selector: (SEL) selector withResult: (PLInstrumentResult *) result {
    STAssertTrue([instrumentation isKindOfClass: [PLInstrumentRunnerTestsMockCase class]], @"Unexpected suite");
    STAssertTrue(strcmp((char *) selector, (char *) @selector(instrumentSomething)) == 0, @"Unexpected selector");
    STAssertNotNil(result, @"Result was nil");

    self->ranTestMethod = YES;
}

@end



@implementation PLInstrumentRunnerTests

- (void) testRunCase {
    PLInstrumentRunnerTestsMockHandler *handler = [[[PLInstrumentRunnerTestsMockHandler alloc] init] autorelease];
    PLInstrumentRunner *runner = [[[PLInstrumentRunner alloc] initWithResultHandler: handler] autorelease];
    PLInstrumentRunnerTestsMockCase *mock = [[[PLInstrumentRunnerTestsMockCase alloc] init] autorelease];

    [runner runCase: mock];
    /* Verify that our instrumentation was run */
    STAssertTrue(mock->ranSetup, @"Didn't run setup");
    STAssertTrue(mock->ranTearDown, @"Didn't run tear down");
    STAssertTrue(mock->ranTestMethod, @"Didn't run instrument method");

    /* Verify that the handler was called */
    STAssertTrue(handler->ranStart, @"Didn't run start notification");
    STAssertTrue(handler->ranFinish, @"Didn't run finish notification");
    STAssertTrue(handler->ranTestMethod, @"Didn't run instrument notification");
    STAssertTrue(handler->skippedMethod, @"Didn't trigger skipped notification");

}

@end
