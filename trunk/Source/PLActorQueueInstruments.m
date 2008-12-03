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

#import "PLActorQueueInstruments.h"

#if TARGET_OS_EMBEDDED && defined(__arm__)
/* Tone down the iterations on the light-weight device */
#define ITERATIONS 10000
#else
#define ITERATIONS 500000
#endif

/**
 * @internal
 *
 * Re-usable threadable queue instrumentation implementation.
 */
@implementation PLActorQueueInstruments

/**
 * Looping ITERATIONS, deliver a message to the given queue.
 */
static void *sendMesgWithQueue (void *arg) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id<PLActorQueue> queue = arg;    
    PLActorMessage *msg;
    
    msg = [PLActorMessage message];
    for (unsigned long i = 0; i < ITERATIONS; i++) {
        [queue send: msg];
    }
    
    [pool release];
    return NULL;
}

struct ReceiverArgs {
    id<PLActorQueue> queue;
    unsigned long messageCount;
};

static void *recvMesgWithQueue (void *arg) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    struct ReceiverArgs *args = arg;
    id<PLActorQueue> queue = args->queue;
    unsigned long messageCount = args->messageCount;
    
    for (unsigned long i = 0; i < messageCount; i++) {
        PLActorMessage *msg;
        [queue receive: &msg usingFilter: NULL filterContext: NULL withTimeout: PLActorTimeWaitForever];
    }

    [pool release];
    return NULL;
}

/**
 * Run the send/receive test, with threadCount threads sending messages to a single receiver.
 * Only send time is included in the iteration timing.
 */
- (PLInstrumentResult *) runWithQueue: (id<PLActorQueue>) queue threadCount: (unsigned long) threadCount {
    pthread_t threads[threadCount];
    pthread_t recvThread;

    PLIAbsoluteTime start, finish;

    /* Spawn the threads */
    start = PLICurrentTime();
    for (unsigned long i = 0; i < threadCount; i++)
        pthread_create(&threads[i], NULL, &sendMesgWithQueue, queue);
    
    /* Pop all messages off the queue as they're written */
    struct ReceiverArgs recvArgs = { queue, threadCount * ITERATIONS };
    pthread_create(&recvThread, NULL, &recvMesgWithQueue, &recvArgs);
    
    /* Wait for all threads to complete */
    for (unsigned long i = 0; i < threadCount; i++) {
        pthread_join(threads[i], NULL);
    }
    
    /* Finished, log the time */
    finish = PLICurrentTime();

    /* Wait for reception to complete */
    pthread_join(recvThread, NULL);
    
    return [PLInstrumentResult resultWithRunTime: PLIComputeTimeInterval(start, finish) iterations: threadCount * ITERATIONS];
}

@end
