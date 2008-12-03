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


#import "PLInstrumentConsoleResultHandler.h"

#import "PLInstrumentObjC.h"

/**
 * Console instrument result handler. All results are output to standard error.
 */
@implementation PLInstrumentConsoleResultHandler


// from PLInstrumentResultHandler protocol
- (void) willExecuteInstrumentationSuite: (PLInstrumentCase *) instrumentation {
    NSString *output = [NSString stringWithFormat: @"Instrumentation suite '%s' started at %@\n", 
                        class_getName([instrumentation class]), [NSDate date]];
    fprintf(stderr, [output UTF8String]);
}


// from PLInstrumentResultHandler protocol
- (void) didExecuteInstrumentationSuite: (PLInstrumentCase *) instrumentation {
    NSString *output = [NSString stringWithFormat: @"Instrumentation suite '%s' finished at %@\n", 
                        class_getName([instrumentation class]), [NSDate date]];
    fprintf(stderr, [output UTF8String]);
}


// from PLInstrumentResultHandler protocol
- (void) didExecuteInstrumentationCase: (PLInstrumentCase *) instrumentation selector: (SEL) selector withResult: (PLInstrumentResult *) result {
    NSString *output = [NSString stringWithFormat: @"Instrumentation case -[%s %s] completed (%lf μs/iteration) at %@\n", 
                        class_getName([instrumentation class]), selector, PLITimeIntervalToMicroseconds([result intervalPerIteration]), [NSDate date]];

    fprintf(stderr, [output UTF8String]);
}

// from PLInstrumentResultHandler protocol
- (void) didSkipInstrumentationCase: (PLInstrumentCase *) instrumentation selector: (SEL) selector reason: (NSString *) reason {
    NSString *output = [NSString stringWithFormat: @"Instrumentation case -[%s %s] failed (%@) at %@\n", 
                        class_getName([instrumentation class]), selector, reason, [NSDate date]];
    
    fprintf(stderr, [output UTF8String]);
}



@end
