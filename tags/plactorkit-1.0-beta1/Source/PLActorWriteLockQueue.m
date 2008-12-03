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

/* The critical section is entered before a reader tests if it should sleep waiting for an enqueue, and
 * exited when the reader exits sleep. Inside of the critical section, the mach semaphore must be signaled by
 * any writers. This encurs syscall overhead, but remains wholly non-blocking */
#define CRITICAL(c) OSAtomicIncrement32(&c)
#define CRITICAL_EXIT(c) OSAtomicDecrement32(&c)
#define TEST_CRITICAL(c) (c == 1)

/**
 * @internal
 *
 * Provides a write-locked concurrent queue based on the two-lock algorithm by Maged M. Michael and Michael L. Scott.
 * This implementation differs in that no read lock is used, as only one actor thread will read from the queue at any time.
 * Thread sleep/wake is implemented via Mach kernel semaphores.
 *
 * The semaphore syscalls are only made from the writer threads during critical sections where the reader
 * has tested for new queue items, any may be blocking waiting for a new message.
 *
 * http://www.cs.rochester.edu/research/synchronization/pseudocode/queues.html
 */
@implementation PLActorWriteLockQueue

- (id) init {
    if ((self = [super init]) == nil)
        return nil;

    _head = _tail = calloc(1, sizeof(PLActorReadWriteLockQueueNode));
    semaphore_create(mach_task_self(), &_sem, SYNC_POLICY_FIFO, 0);

    return self;
}

- (void) dealloc {
    /* Flush queue */
    [self flush];
    
    /* Free dummy node */
    free(_head);
    semaphore_destroy(mach_task_self(), _sem);

    [super dealloc];
}

/*
 * Scan the previously dequeued list for messages matching the provided filter, or any message
 * if the filter is NULL.
 *
 * Must only be called from the single receive thread.
 */
static inline BOOL filterDequeued (PLActorWriteLockQueue *self, id *message, plactor_receive_filter_t filter, void *filterContext) {
    /* If no elements are dequeued, nothing to do */
    if (self->_dequeued == NULL)
        return NO;

    id dequeuedVal = nil;
    if (filter == NULL) {
        /* No filter, simply pop the first value off the list */
        PLActorReadWriteLockQueueNode *cur = self->_dequeued;
        dequeuedVal = [cur->value autorelease];
        assert(cur->value != nil);
        
        self->_dequeued = cur->next;
        
        /* If the tail is the top list element, then there's no tail left */
        if (self->_dequeuedTail == cur)
            self->_dequeuedTail = NULL;
        
        /* Node is no longer used */
        free(cur);
    } else {
        /* Filter, go looking for a matching value */
        PLActorReadWriteLockQueueNode *prev = NULL;
        PLActorReadWriteLockQueueNode *cur = self->_dequeued;
        while (cur != NULL) {
            /* If no match, continue */
            if (!filter(cur->value, filterContext)) {
                prev = cur;
                cur = cur->next;
                continue;
            }
            
            /* Match, remove the current element from the list */
            if (cur == self->_dequeued) {
                self->_dequeued = cur->next;
            } else {
                prev->next = cur->next;
            }
            
            /* Update the tail element if necessary */
            if (cur == self->_dequeuedTail) {
                self->_dequeuedTail = prev;
            }
            
            dequeuedVal = [cur->value autorelease];
            
            /* Node is no longer used */
            free(cur);
        }
    }
    
    /* If we have a previously dequeued value that is usable, return it now */
    if (dequeuedVal != nil) {
        *message = dequeuedVal;
        return YES;
    }
    
    return NO;
}

/*
 * Append the provided element to the current dequeued list.
 *
 * Must only be called from the single receive thread.
 */
static inline void appendDequeued (PLActorWriteLockQueue *self, PLActorReadWriteLockQueueNode *node) {
    assert(node->value != nil);

    if (self->_dequeued == NULL) {
        self->_dequeued = node;
        self->_dequeuedTail = node;
    } else {
        self->_dequeuedTail->next = node;
        self->_dequeuedTail = node;
    }
}

// from PLActorQueue protocol
- (BOOL) receive: (id *) message  usingFilter: (plactor_receive_filter_t) filter filterContext: (void *) filterContext withTimeout: (PLActorTimeInterval) timeout {
    PLActorReadWriteLockQueueNode *node, *new_head;
    mach_timespec_t wait;
    id value = nil;
        
    /* Try internal list of dequeued elements first */
    if (filterDequeued(self, message, filter, filterContext))
        return YES;
    
    /* Compute the timeout */
    if (timeout > 0) {
        wait.tv_sec = 0;
        wait.tv_nsec = timeout * 1000;
    }
    
    while (value == nil) {
        CRITICAL(_crit);
        assert(_crit == 1);

        /* Read head and the next value */
        node = _head;
        new_head = node->next;
        
        /* Is queue empty? */
        if (new_head == NULL) {
            if (timeout == PLActorTimeWaitNone) {
                CRITICAL_EXIT(_crit);
                goto cleanup;
            } else if (timeout == PLActorTimeWaitForever) {
                semaphore_wait(_sem);
            } else {
                // TODO Check for spurious wakeup and reduce the wait time
                // accordingly?
                if (semaphore_timedwait(_sem, wait) == KERN_OPERATION_TIMED_OUT) {
                    CRITICAL_EXIT(_crit);
                    goto cleanup;
                }
            }

            /* Loop and retry */
            CRITICAL_EXIT(_crit);
            continue;
        } else {
            /* Successful dequeue, no longer in critical section */
            CRITICAL_EXIT(_crit);

            /* Check filter */
            if (filter == NULL || filter(new_head->value, filterContext)) {
                /* No filter, or filter matches. All done */
                value = [new_head->value autorelease];
            } else {
                /* Filter doesn't match -- add the object to the dequeued list and loop */
                PLActorReadWriteLockQueueNode *dequeued = malloc(sizeof(PLActorReadWriteLockQueueNode));
                dequeued->value = new_head->value;
                dequeued->next = NULL;
            
                appendDequeued(self, dequeued);
            }

            free(node);
            _head = new_head;
        }
    }

cleanup:
    *message = value;
    if (value == nil)
        return NO;
    else
        return YES;
}


// from PLActorQueue protocol
- (void) send: (id) message {
    PLActorReadWriteLockQueueNode *node;

    /* Create new node */
    node = malloc(sizeof(PLActorReadWriteLockQueueNode));
    node->value = [message retain];
    node->next = NULL;

    /* Acquire the tail lock and append the new element */
    OSSpinLockLock(&_t_lock); {
        _tail->next = node;
        _tail = node;
    }
    OSSpinLockUnlock(&_t_lock);

    /* Wake up any sleeping thread */
    OSMemoryBarrier();
    if (TEST_CRITICAL(_crit))
        semaphore_signal(_sem);
}


// from PLActorQueue protocol
- (void) flush {
    /* Pop all available messages off the queue */
    PLActorMessage *msg;
    while ([self receive: &msg usingFilter: NULL filterContext: NULL withTimeout: PLActorTimeWaitNone]) {
    }
}

@end
