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
#import "PLInstrumentRunner.h"

#import "PLInstrumentObjC.h"

/**
 * Implements runtime detection and execution of PLInstrumentCase instrumentation classes.
 */
@implementation PLInstrumentRunner

/**
 * Initialize the instrumentation runner with the provided result handler.
 */
- (id) initWithResultHandler: (id<PLInstrumentResultHandler>) resultHandler {
    if ((self = [super init]) == nil)
        return nil;

    _resultHandler = [resultHandler retain];

    return self;
}

- (void) dealloc {
    [_resultHandler release];

    [super dealloc];
}

/**
 * Locate all subclasses of PLInstrumentCase registed with the Objective-C runtime, and
 * execute all instrumentation methods.
 */
- (void) runAllCases {
    Class *classes;
    int numClasses;

    /* Get the count of classes */
    classes = NULL;
    numClasses = objc_getClassList(NULL, 0);

    /* If none, nothing to do */
    if (numClasses == 0)
        return;

    /* Fetch all classes */        
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        Class superClass = cls;
        BOOL isInstrument = NO;

        /* Determine if this is a subclass of PLInstrumentCase. By starting with the class
         * itself, we skip over the non-subclassed PLInstrumentCase class. */
        while ((superClass = class_getSuperclass(superClass)) != NULL) {
            if (superClass == [PLInstrumentCase class]) {
                isInstrument = YES;
                break;
            }
        }

        /* If it is an instrument instance, run the tests */
        if (isInstrument) {
            PLInstrumentCase *obj = [objc_msgSend(cls, @selector(alloc)) init];
            [self runCase: obj];
            [obj release];
        }
    }

    /* Clean up */
    free(classes);
}

/**
 * Execute all instrumentation methods for the given instrumentation test
 * case.
 */
- (void) runCase: (PLInstrumentCase *) instrumentCase {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    Method *methods;
    unsigned int methodCount;

    /* Inform the result handler of initialization */
    [_resultHandler willExecuteInstrumentationSuite: instrumentCase];
    
    /* Iterate over the available methods */
    methods = class_copyMethodList([instrumentCase class], &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        Method m;
        SEL methodSel;
        char retType[256];
        PLInstrumentResult *result;

        /* Fetch the method meta-data */
        m = methods[i];
        methodSel = method_getName(m);
        method_getReturnType(m, retType, sizeof(retType));

        /* Only invoke methods that start with the name "instrument" */
        if (strstr(sel_getName(methodSel), "instrument") == NULL)
            continue;

        /* Skip methods that do not return a PLInstrumentResult */
        if (strcmp(retType, @encode(PLInstrumentResult *)) != 0) {
            [_resultHandler didSkipInstrumentationCase: instrumentCase selector: methodSel reason: @"Instrumentation methods must be declared to return a PLInstrumentResult instance."];
            continue;
        }
    
        [instrumentCase setUp]; {        
            NSMethodSignature *sig = [instrumentCase methodSignatureForSelector: methodSel];
            NSInvocation *invoke = [NSInvocation invocationWithMethodSignature: sig];
            [invoke setSelector: methodSel];
            
            /* Invoke */
            [invoke invokeWithTarget: instrumentCase];
            
            /* Fetch result
             * Return value size is checked above */
            [invoke getReturnValue: &result];
            
        } [instrumentCase tearDown];

        /* Inform the result handler of method execution */
        [_resultHandler didExecuteInstrumentationCase: instrumentCase selector: methodSel withResult: result];
    }
    
    /* Inform the result handler of completion */
    [_resultHandler didExecuteInstrumentationSuite: instrumentCase];
    
    /* Clean up */
    if (methods != NULL)
        free(methods);
    
    [pool release];
}

@end
