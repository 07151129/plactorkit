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
#import "PLActorObjC.h"

/**
 * @internal
 *
 * PThread-based actor process.
 */
@implementation PLThreadedActorProcess


/**
 * Initialize the actor.
 */
- (id) initWithTarget: (id) target selector: (SEL) selector {
    return [self initWithTarget:target selector:selector object: nil];
}

/**
 * Initialize the actor.
 */
- (id) initWithTarget: (id) target selector: (SEL) selector object: (id) object {
    if ((self = [super init]) == nil)
        return nil;

    /* Save the target reference */
    _target_obj = [target retain];
    _target_sel = selector;
    _target_arg = [object retain];

    return self;
}

- (void) dealloc {
    [_target_obj release];
    [_target_arg release];

    [super dealloc];
}


/* Actor thread entry point. */
static void *run_actor (void *arg) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PLThreadedActorProcess *proc = arg;

    /* Register our actor process */
    [PLActorKit setThreadProcess: proc];
    
    /* Start the user's code */
    ((void (*)(id, SEL, id)) &objc_msgSend)(proc->_target_obj, proc->_target_sel, proc->_target_arg);
    
    /* We retained ourself when spawning this thread.
     * Now that the actor has returned, release ourself. */
    [proc release];

    [pool release];
    return NULL;
}


/**
 * Spawn the actor thread
 */
- (void) run {
    pthread_t thr;
    
    /* We must retain our own reference */
    [self retain];
    
    /* Spawn the thread */
    pthread_create(&thr, NULL, &run_actor, self);
    pthread_detach(thr);
}


@end
