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

#import "PLInstrumentCase.h"
#import "PLInstrumentResult.h"

/**
 * Provides handling of instrumentation results. The results may be printed
 * to stderr, output as XML, etc.
 */
@protocol PLInstrumentResultHandler <NSObject>

/**
 * Called when preparing to execute an instrumentation suite.
 */
- (void) willExecuteInstrumentationSuite: (PLInstrumentCase *) instrumentation;

/**
 * Called when finished to executing an instrumentation suite.
 */
- (void) didExecuteInstrumentationSuite: (PLInstrumentCase *) instrumentation;

/**
 * Called upon execution of an instrumentation case's instrumentation method.
 *
 * @param instrumentation The executed instrumentation instance.
 * @param selector The selector executed.
 * @param result The result provided by the instrumentation method.
 */
- (void) didExecuteInstrumentationCase: (PLInstrumentCase *) instrumentation selector: (SEL) selector withResult: (PLInstrumentResult *) result; 

/**
 * If an instrumentation method can not be run, this method will be called.
 *
 * @param instrumentation The executed instrumentation instance.
 * @param selector The selector executed.
 * @param reason Non-localized human readable reason that the instrumentation method was skipped.
 */
- (void) didSkipInstrumentationCase: (PLInstrumentCase *) instrumentation selector: (SEL) selector reason: (NSString *) reason;

@end
