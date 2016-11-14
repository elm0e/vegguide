//
// VEGPlace.m
// VegGuide
//
// Model for an entry (or place) from the VegGuide API
//
// Created by Eric Sorensen on 8/15/16.
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

#import "VEGPlace.h"
#import <objc/runtime.h>

@interface VEGPlace() {
    dispatch_once_t imageToken;
    dispatch_once_t isOpenToken;
    NSMutableArray<VEGImage *> *vegImages;
    BOOL isOpen;
}

@end

@implementation VEGPlace

// Dynamic pass-through properties to access the backing dictionary
@dynamic website;
@dynamic distance;
@dynamic vegLevelDescription;
@dynamic longDescription;
@dynamic reviewsUri;
@dynamic sortableName;
@dynamic postalCode;
@dynamic isWheelchairAccessible;
@dynamic neighborhood;
@dynamic hours;
@dynamic name;
@dynamic region;
@dynamic cuisines;
@dynamic weightedRating;
@dynamic uri;
@dynamic shortDescription;
@dynamic vegLevel;
@dynamic creationDatetime;
@dynamic address1;
@dynamic allowsSmoking;
@dynamic paymentOptions;
@dynamic city;
@dynamic lastModifiedDatetime;
@dynamic priceRange;
@dynamic country;
@dynamic ratingCount;
@dynamic categories;
@dynamic isCashOnly;
@dynamic phone;
@dynamic tags;
@dynamic directions;
@dynamic acceptsReservations;

- (NSString *) getKeyForSelector:(SEL) selector {
    return [self convertCamelCaseToUnderscore:selector];
}

#pragma mark - Derived properties

- (NSArray<VEGImage *> *) images {
    dispatch_once(&imageToken, ^{
        vegImages = nil;
        NSArray *images = [self.backingData valueForKey:@"images"];
        if ((images != nil) && (images.count > 0)) {
            vegImages = [[NSMutableArray alloc] initWithCapacity:images.count];
            for (NSDictionary *image in images) {
                [vegImages addObject:[[VEGImage alloc] initWithData:image]];
            }
        }
    });
    return vegImages;
}

- (NSString *) thumbnailImagePath {
    NSArray *images = [self.backingData valueForKey:@"images"];
    if ((images != nil) && (images.count > 0)) {
        NSArray *files = [images[0] valueForKey:@"files"];
        if ((files != nil) && (files.count > 0)) {
            return [files[0] valueForKey:@"uri"];
        }
    }
    return nil;
}

- (BOOL) isOpen {
    dispatch_once(&isOpenToken, ^{
        isOpen = (self.hours.count == 0); // No times means open always for our purposes
        for (NSDictionary *days in self.hours) {
            NSString *dayRange= [days valueForKey:@"days"];
            NSArray<NSString *> *times = [days valueForKey:@"hours"];
            if (times && ![times isEqual:[NSNull null]]) {
                for (NSString *time in times) {
                    if ([self isOpenWithDate:dayRange andTime:time]) {
                        isOpen = YES;
                    }
                }
            }
        }
    });
  return isOpen;
}

//Note:Does not take timezone into account (because we do not know the TZ of the place)
- (BOOL) isOpenWithDate:(NSString *)dayRange  andTime:(NSString *)timeRange {
    if ([timeRange caseInsensitiveCompare:@"closed"] == NSOrderedSame) return NO;
    NSRange pos = [timeRange rangeOfString:@"-"];
    if (pos.location == NSNotFound) return NO;
    NSDate *now = [[NSDate alloc] init];
    const NSArray<NSString *> *days = [[NSArray alloc] initWithObjects: @"MON", @"TUE", @"WED", @"THU", @"FRI", @"SAT", @"SUN", nil];
    if ([dayRange caseInsensitiveCompare:@"daily"] != NSOrderedSame) {
        NSString *dayStart = nil;
        NSString *dayEnd = nil;
        if (dayRange.length == 3) {
            dayStart = dayRange;
            dayEnd = dayRange;
        } else {
            dayStart = [dayRange substringToIndex:3];
            dayEnd = [dayRange substringFromIndex:dayRange.length-3];
        }
        int startDayNum = (int)[days indexOfObject:[dayStart uppercaseString]];
        int endDayNum = (int)[days indexOfObject:[dayEnd uppercaseString]];
        
        NSDateFormatter *dowFormatter = [[NSDateFormatter alloc] init];
        [dowFormatter setDateFormat:@"EEE"];
        NSString *todayDay = [[dowFormatter stringFromDate:now] uppercaseString];
        int todayDayNum = (int)[days indexOfObject:todayDay];
        if (startDayNum > endDayNum) {
            // Range is flipped due to day numbers
            if ((todayDayNum > startDayNum) || (todayDayNum < endDayNum)) return NO;
        } else {
            if ((todayDayNum < startDayNum) || (todayDayNum > endDayNum)) return NO;
        }
    }
    // Day is in range - check time
    NSString *timeStart = [timeRange substringToIndex:pos.location];
    float startHour = [self hourOfDayFromTime:timeStart];
    NSString *timeEnd = [timeRange substringFromIndex:pos.location+1];
    float endHour = [self hourOfDayFromTime:timeEnd];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour) fromDate:now];
    NSInteger hour = [components hour];
    if (endHour < startHour) {  // 10am to 4am
        return ((startHour <= hour) || (hour <= endHour));
    } else {
        return (startHour <= hour) && (hour <= endHour);
    }
}

- (float) hourOfDayFromTime:(NSString *)timeValue {
    NSString *time = [timeValue stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (time.length < 3) return 0;
    time = [time stringByReplacingOccurrencesOfString:@":" withString:@"."];
    float hour = [[time substringToIndex:time.length - 2] floatValue];
    NSString *period = [time substringFromIndex:time.length - 2];
    return hour + ([period caseInsensitiveCompare:@"am"] == NSOrderedSame ? 0 : 12);
}

- (NSString *) longDescription {
    return [self.backingData valueForKeyPath:@"long_description.text/vnd.vegguide.org-wikitext"];
}

- (NSString *) description {
    return [self.backingData valueForKey:@"sortable_name"];
}

- (NSNumber *) distance {
    float distance = 0;
    NSString *dval = [self.backingData valueForKey:@"distance"];
    if (dval) {
        distance = dval.floatValue;
    }
    return [[NSNumber alloc] initWithFloat:distance];
}

- (BOOL) contains:(NSString *)searchTerm {
    if ([self.name localizedCaseInsensitiveContainsString:searchTerm]) {
        return YES;
    }
    if ([self.longDescription localizedCaseInsensitiveContainsString:searchTerm]) {
        return YES;
    }
    if ([self.address1 localizedCaseInsensitiveContainsString:searchTerm]) {
        return YES;
    }
    if ([self.city localizedCaseInsensitiveContainsString:searchTerm]) {
        return YES;
    }
    if ([self.region localizedCaseInsensitiveContainsString:searchTerm]) {
        return YES;
    }
    return NO;
}

@end
