//
// PlaceListCell.m
// VegGuide
//
// Table cell view for the Place List table
//
// Created by Eric Sorensen on 8/10/16.
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

#import "PlaceListCell.h"
#import "VEGImageCache.h"

@interface PlaceListCell()

@end

@implementation PlaceListCell

- (void) populate:(VEGPlace *) place {
    
    self.nameLabel.text = place.name;
    self.descriptionLabel.text = place.shortDescription;
    self.directionsLabel.text = place.directions;
    self.addressLabel.text = place.address1;
    self.cityLabel.text = [NSString stringWithFormat:@"%@, %@ %@", place.city, place.region, place.postalCode];
    
    NSNumber *vegLevel = place.vegLevel;
    switch (vegLevel.intValue) {
        case 0:
            self.vegLevelDescriptionLabel.text = @"No-Options";
            break;
        case 1:
        case 2:
        case 3:
            self.vegLevelDescriptionLabel.text = @"Veg-Options";
            break;
        case 4:
            self.vegLevelDescriptionLabel.text = @"Vegetarian";
            break;
        case 5:
            self.vegLevelDescriptionLabel.text = @"Vegan";
            break;
        default:
            self.vegLevelDescriptionLabel.text = place.vegLevelDescription;
            break;
    }
    self.vegLevelDescriptionLabel.text = [self.vegLevelDescriptionLabel.text uppercaseString];
    
    self.distanceLabel.text = nil;
    if (place.distance != nil) {
        NSNumber *d = place.distance;
        float distance = d.doubleValue;
        NSString *format = [@"%4.2f mile" stringByAppendingString:(distance != 1 ? @"s" : @"")];
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

    NSNumber *rc = [place valueForKey:@"rating_count"];
    if (rc && ![rc isEqual:[NSNull null]]) {
        int ratingCount = rc.intValue;
        if (ratingCount == 0) {
            self.ratingCountLabel.text = @"No Ratings";
        } else {
            NSString *format = [@"%d rating" stringByAppendingString:(ratingCount > 1 ? @"s" : @"")];
            self.ratingCountLabel.text =[NSString stringWithFormat:format, ratingCount];
        }
    } else {
        //        cell.ratingLabel.text = @"";
        self.ratingCountLabel.text = @"No Ratings";
    }
    
    self.openLabel.text = (place.isOpen ? @"Open" : @"Closed");

}

- (UIImage *) loadRatingsImage:(float)rating {
    return [[VEGImageCache sharedInstance] loadRatingsImage:rating];
}

@end
