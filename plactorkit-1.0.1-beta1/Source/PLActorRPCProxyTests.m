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

#import <SenTestingKit/SenTestingKit.h>
#import "ActorKit.h"

@interface PLActorProxyTests : SenTestCase @end

@implementation PLActorProxyTests

// simple echo method to test the actor
- (NSString *) echo: (NSString *) text {
    return text;
}

// A non-synchronous echo method, sends reply directly with a simple string value
- (oneway void) onewayEcho: (NSString *) text sender: (id<PLActorProcess>) sender {
    [sender send: text];
}


- (void) testLeak {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PLActorProxyTests *testActor = (PLActorProxyTests *) [[PLActorRPCProxy alloc] initWithTarget: self];
    
    NSString *result = [testActor echo: @"test"];
    STAssertTrue([@"test" isEqual: result], @"Actor did not echo request, returned %@", result);
    
    [pool release];
    // Uses subtraction to avoid STAssertEquals type mismatch warnings from SenTest.
    // On 10.4 retainCount returns unsigned int, on 10.5 it returns NSUInteger.
    STAssertTrue(1 - [testActor retainCount] == 0, @"Retain count should be 1");
    
    [testActor release];
}

- (void) testSynchronousMessaging {
    PLActorProxyTests *testActor = (PLActorProxyTests *) [[PLActorRPCProxy alloc] initWithTarget: self];

    NSString *result = [testActor echo: @"test"];
    STAssertTrue([@"test" isEqual: result], @"Actor did not echo request, returned %@", result);

    [testActor release];
}


- (void) testAsynchronousMessaging {
    PLActorProxyTests *testActor = (PLActorProxyTests *) [[PLActorRPCProxy alloc] initWithTarget: self];
    
    /* Send the async message */
    [testActor onewayEcho: @"test" sender: [PLActorKit process]];

    /* Wait for and test the response */
    NSString *text = [PLActorKit receive];
    STAssertTrue([@"test" isEqual: text], @"Actor did not echo request, returned %@", text);
    
    [testActor release];
}

@end
