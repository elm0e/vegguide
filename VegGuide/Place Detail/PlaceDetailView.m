//
// PlaceDetailView.m
// VegGuide
//
// View for the Place Detail UI
//
// Created by Eric Sorensen on 8/13/16.
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

#import "PlaceDetailView.h"
#import "VEGImageCache.h"

@implementation PlaceDetailView 

- (void) populate:(VEGPlace *) place {
    
    self.nameLabel.text = place.name;
    self.descriptionLabel.text = place.longDescription;
    self.shortDescriptionLabel.text = place.shortDescription;
    self.addressLabel.text = [self addressLabelForPlace:place];
    self.phoneLabel.text = place.phone;
    self.websiteLabel.text = place.website;
    self.vegLevelDescriptionLabel.text = place.vegLevelDescription;
    
    self.distanceLabel.text = nil;
    if (place.distance != nil) {
        NSNumber *d = place.distance;
        float distance = d.doubleValue;
        NSString *format = [@"%4.1f mile" stringByAppendingString:(distance != 1 ? @"s" : @"")];
        self.distanceLabel.text = [NSString stringWithFormat:format, distance];
    }
    
    self.priceRangeLabel.text = @"";
    NSString *price = place.priceRange;
    NSRange pos = [price rangeOfString:@"-"];
    if (pos.location != NSNotFound) {
        self.priceRangeLabel.text = [price substringToIndex:pos.location];
    }
    
    NSNumber *r = place.weightedRating;
    float rating = r.floatValue;
    self.ratingsImage.image = [self loadRatingsImage:rating];
    self.ratingCountLabel.text = @"No Ratings";
    if (place.ratingCount) {
        int ratingCount = place.ratingCount.intValue;
        if (ratingCount > 0) {
            NSString *format = [@"%d review" stringByAppendingString:(ratingCount > 1 ? @"s" : @"")];
            self.ratingCountLabel.text =[NSString stringWithFormat:format, ratingCount];
        }
    }
    
    NSMutableString *hoursLabel = [[NSMutableString alloc] init];
    if (place.hours) {
        int dayCnt = 1;
        for (NSDictionary *days in place.hours) {
            NSString *dayRange= [days valueForKey:@"days"];
            [hoursLabel appendString:[NSString stringWithFormat:@"%@: ", dayRange]];
            NSArray<NSString *> *times = [days valueForKey:@"hours"];
            int timeCnt = 1;
            if (times && ![times isEqual:[NSNull null]]) {
                for (NSString *time in times) {
                    [hoursLabel appendString:time];
                    if (timeCnt++ < times.count) {
                        [hoursLabel appendString:@", "];
                    }
                }
            }
            if (dayCnt++ < place.hours.count) {
                [hoursLabel appendString:@"\n"];
            }
        }
    }
    self.hoursLabel.text = hoursLabel;
}

- (UIImage *) loadRatingsImage:(float)rating {
    return [[VEGImageCache sharedInstance] loadRatingsImage:rating];
}

- (NSString *) addressLabelForPlace:(VEGPlace *)place {
    NSMutableString *label = [[NSMutableString alloc] init];
    if (place.address1) {
        [label appendFormat:@"%@, ", place.address1];
    }
    if (place.city) {
        [label appendFormat:@"%@, ", place.city];
    }
    if (place.region) {
        [label appendFormat:@"%@ ", place.region];
    }
    if (place.postalCode) {
        [label appendFormat:@"%@ ", place.postalCode];
    }
    return label;
}

@end
