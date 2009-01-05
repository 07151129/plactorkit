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

#import <err.h>

/**
 * @internal
 *
 * Simple pthread-based locking message queue.
 */
@implementation PLActorSimpleQueue

- (id) init {
    if ((self = [super init]) == nil)
        return nil;
    
    /* Create mailbox */
    _mbox = CFArrayCreateMutable(kCFAllocatorDefault, 5, &kCFTypeArrayCallBacks);
    
    /* Initialize locking primitives */
    pthread_mutex_init(&_mbox_lock, NULL);
    pthread_cond_init(&_mbox_cond, NULL);
    
    return self;
}


- (void) dealloc {
    /* Destroy lock/cond */
    pthread_mutex_destroy(&_mbox_lock);
    pthread_cond_destroy(&_mbox_cond);
    
    /* Destroy mailbox */
    CFRelease(_mbox);
    
    [super dealloc];
}


// from PLActorQueue protocol
- (void) send: (id) message {
    pthread_mutex_lock(&_mbox_lock);
    CFArrayAppendValue(_mbox, message);
    pthread_cond_signal(&_mbox_cond);
    pthread_mutex_unlock(&_mbox_lock);
}


// from PLActorQueue protocol
- (BOOL) receive: (id *) message 
     usingFilter: (plactor_receive_filter_t) filter 
   filterContext: (void *) filterContext 
     withTimeout: (PLActorTimeInterval) timeout {
    id obj = nil;
    
    /* Acquire our mbox lock */
    pthread_mutex_lock(&_mbox_lock);
    
    /* Loops on pthread_cond_wait() until a message is received
     * or the loop is explicitly broken. */
    while (obj == nil) {
        /* Any messages available? */
        CFIndex count = CFArrayGetCount(_mbox);
        
        if (count > 0) {
            BOOL found = YES;
            CFIndex idx = 0;
            
            /* If the filter function isn't nil, find the first object that matches.
             * If we find no match, idx will be equal to the array's length,
             * which we use to set the found flag.
             *
             * If the filter function *is* nil, then we'll just pull the object
             * at idx, which is set to 0 -- the first object in the FIFO queue.
             */
            if (filter != NULL) {
                while (idx < count) {
                    id obj = (id) CFArrayGetValueAtIndex(_mbox, idx);
                    if (filter(obj, filterContext))
                        break;
                    idx++;
                }

                if (idx == count)
                    found = NO;
            }
            
            /* If we didn't walk off the end of the array looking for the object,
             * pop the object at the given index and return it */
            if (found) {
                /* Pop the message and return */
                obj = (id) CFArrayGetValueAtIndex(_mbox, idx);
                [[obj retain] autorelease];
                CFArrayRemoveValueAtIndex(_mbox, idx);
                goto cleanup;
            }
        }
        
        if (timeout == PLActorTimeWaitNone) {
            /* No waiting, exit loop now */
            goto cleanup;
            
        } else if (timeout == PLActorTimeWaitForever) {
            /* Infinite wait */
            if (pthread_cond_wait(&_mbox_cond, &_mbox_lock) != 0)
                warn("pthread_cond_wait()");
            
        } else if (timeout > 0) {
            int waitret;

            /* Timed wait -- timeout is given in absolute time. */
            struct timespec timeout_spec;
            timeout_spec.tv_sec = time(NULL) + (timeout / 1000);
            timeout_spec.tv_nsec = (timeout % 1000) * 1000000;
            
            /* Wait */
            waitret = pthread_cond_timedwait(&_mbox_cond, &_mbox_lock, &timeout_spec);

            /* Check for timeout or error. If either happens, we don't
             * hold the lock and should finish immediately. */
            if (waitret == ETIMEDOUT) {
                goto finish;
            } else if (waitret != 0) {
                /* An error occured */
                warnc(waitret, "pthread_cond_timedwait()");
                goto finish;
            }
        }
    }
    
cleanup:
    pthread_mutex_unlock(&_mbox_lock);
    
finish:
    *message = obj;
    if (obj == nil)
        return NO;
    else
        return YES;
}

// from PLActorQueue protocol
- (void) flush {
    pthread_mutex_lock(&_mbox_lock);
    CFArrayRemoveAllValues(_mbox);
    pthread_mutex_unlock(&_mbox_lock);
}


@end
