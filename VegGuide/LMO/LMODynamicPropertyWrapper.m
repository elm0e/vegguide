//
// LMODynamicPropertyWrapper.h
//
// Wrapper class used to access JSON data in a Map via dynamic properties
//
// Created by Eric Sorensen on 8/16/16.
// Copyright © 2016 Ambient Software Services. All rights reserved.
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "LMODynamicPropertyWrapper.h"
#import <objc/runtime.h>

@interface LMODynamicPropertyWrapper()

- (NSString *) getKeyForSelector:(SEL) selector;
    
@end

@implementation LMODynamicPropertyWrapper


- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Must use initWithData to initialize"
                                 userInfo: nil];
}

- (id)initWithData:(NSDictionary *) data {
    if (self = [super init]) {
        // Dictionary is immutable so don't copy - this class is just a wrapper
        _backingData = data;
    }
    return self;
}

+ (BOOL) resolveInstanceMethod:(SEL)selector {
    class_addMethod(self, selector, (IMP)autoDictionaryGetter, "@@:");
    return YES;
}

/*
 * Create getter for the dynamic properites.  The getter will pull the value from the distionary with the entity data
 */
id autoDictionaryGetter(id self, SEL _cmd) {
    LMODynamicPropertyWrapper *wrapperSelf = (LMODynamicPropertyWrapper *)self;
    NSString *key = [wrapperSelf getKeyForSelector:_cmd];
    return [wrapperSelf.backingData valueForKey:key];
}

/*
 * Override this and use one of the conversion functions if the dictionary keys don't match the selectors
 */
- (NSString *) getKeyForSelector:(SEL) selector {
    return NSStringFromSelector(selector);
}

- (NSString *) convertCamelCaseToUnderscore:(SEL) selector {
    NSString *selectorName = NSStringFromSelector(selector);
    NSError *error = NULL;
    NSRegularExpression *camelCaseTo_ = [NSRegularExpression
                                         regularExpressionWithPattern:@"([A-Z])"
                                         options:0 error:&error];
    NSString *key = [[camelCaseTo_
                      stringByReplacingMatchesInString:selectorName
                      options:0 range:NSMakeRange(0, selectorName.length)
                      withTemplate:@"_$1"]
                     lowercaseString];
    return key;
}

- (NSString *) getSafeStringValueForKey:(NSString *) key {
    NSString *value = [self.backingData valueForKey:key];
    if (value && ![value isEqual:[NSNull null]]) {
        return value;
    }
    return @"";
}

- (NSString *) getSafeStringValueForKeyPath:(NSString *) path {
    NSString *value = [self.backingData valueForKeyPath:path];
    if (value && ![value isEqual:[NSNull null]]) {
        return value;
    }
    return @"";
}

- (NSString *) description {
    return [self.backingData description];
}

- (NSString *) debugDescription {
    return [self.backingData debugDescription];
}

@end
