//
// VEGPlace.h
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "LMODynamicPropertyWrapper.h"
#import "VEGImage.h"

@interface VEGPlace : LMODynamicPropertyWrapper

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *sortableName;
@property (nonatomic, copy, readonly) NSString *shortDescription;
@property (nonatomic, copy, readonly) NSString *longDescription;
@property (nonatomic, copy, readonly) NSString *website;

@property (nonatomic, copy, readonly) NSNumber *weightedRating;
@property (nonatomic, copy, readonly) NSNumber *ratingCount;
@property (nonatomic, copy, readonly) NSString *reviewsUri;

@property (nonatomic, copy, readonly) NSNumber *distance;
@property (nonatomic, copy, readonly) NSString *neighborhood;
@property (nonatomic, copy, readonly) NSString *directions;
@property (nonatomic, copy, readonly) NSString *address1;
@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy, readonly) NSString *region;
@property (nonatomic, copy, readonly) NSString *postalCode;
@property (nonatomic, copy, readonly) NSString *country;
@property (nonatomic, copy, readonly) NSString *phone;

@property (nonatomic, copy, readonly) NSString *vegLevelDescription;
@property (nonatomic, copy, readonly) NSNumber *vegLevel;
@property (nonatomic, copy, readonly) NSString *priceRange;
@property (nonatomic, assign, readonly) Boolean isWheelchairAccessible;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *hours;
@property (nonatomic, copy, readonly) NSArray<NSString *> *cuisines;
@property (nonatomic, assign, readonly) Boolean allowsSmoking;
@property (nonatomic, copy, readonly) NSArray<NSString *> *paymentOptions;
@property (nonatomic, copy, readonly) NSArray<NSString *> *categories;
@property (nonatomic, assign, readonly) Boolean isCashOnly;
@property (nonatomic, copy, readonly) NSArray<NSString *> *tags;
@property (nonatomic, assign, readonly) Boolean acceptsReservations;

@property (nonatomic, copy, readonly) NSString *uri;
@property (nonatomic, copy, readonly) NSDate *creationDatetime;
@property (nonatomic, copy, readonly) NSDate *lastModifiedDatetime;

// Derived properties
@property (nonatomic, copy, readonly) NSString *thumbnailImagePath;
@property (nonatomic, copy, readonly) NSString *headerImagePath;
@property (nonatomic, copy, readwrite) CLLocation *location;
@property (nonatomic, assign, readonly) BOOL isOpen;
@property (nonatomic, copy, readonly) NSArray<VEGImage *> *images;

- (BOOL) contains:(NSString *)searchTerm;

@end
