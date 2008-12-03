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

#import <AvailabilityMacros.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <objc/runtime.h>
#else
#import <objc/objc-runtime.h>
#endif

/**
 * @internal
 * @defgroup functions_objc Objective-C Compatibility Functions
 *
 * Objective-C 2.0 backwards compatibility functions and macros for
 * for Mac OS X 10.4 (and in the future, cocotron)
 */

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

/* Return the class' superclass. */
#define class_getSuperclass(cls) (cls->super_class)

/* Fetch the method name */
#define method_getName(meth) (meth->method_name)

/* Fetch the class name */
#define class_getName(cls) (cls->name)

/* Fetch the method return type encoding. */
static inline void method_getReturnType(Method method, char *dest, unsigned int len) {
    char *p = method->method_types;
    // At least 1 for the terminating NULL
    unsigned int retLen = 1;

    /* Scan forward until either the end of the string is hit,
     * or a ASCII character between 0 and 9 is hit. */
    while (*p != '\0' && (*p < '0' || *p > '9')) {
        retLen++;
        p++;
    }

    /* Use strlcpy to ensure that a terminating NULL is added */
    strlcpy(dest, method->method_types, MIN(len, retLen));
}

/* Copy the whole class method list */
static inline Method *class_copyMethodList (Class cls, unsigned int *outCount) {
    struct objc_method_list *mlist;
    void *iterator = NULL;
    int methodCount = 0;
    Method *result = NULL;

    /* Iterate over the method list(s) */
    mlist = class_nextMethodList(cls, &iterator);
    while (mlist != NULL) {
        /* Ensure sufficient space is allocated */
        void *tmp = realloc(result, (methodCount + mlist->method_count) * sizeof(Method));
        if (tmp == NULL ) {
            /* realloc failed */
            free(result);
            return NULL;
        } else {
            result = tmp;
        }

        /* Output the method pointers */
        for (int i = 0; i < mlist->method_count; i++) {
            result[methodCount] = &mlist->method_list[i];
            methodCount++;
        }

        /* Advance the list pointer */
        mlist = class_nextMethodList(cls, &iterator);
    }

    /* Set the caller's outCount */
    if (outCount != NULL)
        *outCount = methodCount;

    return result;
}

#endif /* MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5 */
