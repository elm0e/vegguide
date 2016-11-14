//
// VEGReview.m
// VegGuide
//
// Model for a review from the VegGuide API
//
// Created by Eric Sorensen on 9/1/16.
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

#import "VEGReview.h"

@implementation VEGReview {
    dispatch_once_t ageToken;
    NSString *age;
}

@dynamic rating;
@dynamic age;
@dynamic userName;

- (NSString *) getKeyForSelector:(SEL) selector {
    return [self convertCamelCaseToUnderscore:selector];
}

#pragma mark - Derived properties

- (NSString *) age {
    dispatch_once(&ageToken, ^{
        age = @"";
        NSString *lastUpdate = [self.backingData valueForKey:@"last_modified_datetime"];
        if (lastUpdate && ![lastUpdate isEqual:[NSNull null]]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            NSDate *date;
            NSError *error;
            [formatter getObjectValue:&date forString:lastUpdate range:nil error:&error];
            if (!error) {
                NSDate *now = [NSDate date];
                NSTimeInterval interval = [now timeIntervalSinceDate:date];
                NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
                if (interval < 60 * 60 * 24 * 31) {
                    formatter.allowedUnits = NSCalendarUnitDay;
                } else {
                    formatter.allowedUnits = NSCalendarUnitYear | NSCalendarUnitMonth;
                }
                formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorDropAll;
                formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
                NSString *intervalDescription = [formatter stringFromTimeInterval:interval];
                age = [[NSString alloc] initWithFormat:@"%@ ago", intervalDescription];
            }
        }
    });
    return age;
}

- (NSString *) review {
    return [self getSafeStringValueForKeyPath:@"body.text/vnd.vegguide.org-wikitext"];
}

- (NSString *) userName {
    return [self getSafeStringValueForKeyPath:@"user.name"];
}

@end
