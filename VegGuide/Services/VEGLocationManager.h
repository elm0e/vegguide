//
// VEGLocationManager.h
// VegGuide
//
// Singleton service to handle location updates using CoreLocation
// Clients should add themselves as observers using addLocationObserver
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
#import <CoreLocation/CoreLocation.h>
#import "VEGPlace.h"

@protocol VEGLocationManagerDelegate <NSObject>
@required
-(void)didUpdateLocation:(CLLocation *)newLocation;
@optional
- (void)didFailWithError:(NSError *)error;
@end

@interface VEGLocationManager : NSObject

@property (nonatomic, strong, readonly) CLLocation *currentLocation;

+ (instancetype) sharedInstance;
- (instancetype) init __attribute__((unavailable("Use sharedInstance instead of init")));

- (void) addLocationObserver:(id<VEGLocationManagerDelegate>)listener;
- (void) removeLocationObserver:(id<VEGLocationManagerDelegate>)listener;
- (void) requestCurrentLocation;
- (void) requestPlaceLocation:(VEGPlace *)place completionHandler:(CLGeocodeCompletionHandler)handler;
- (void) validateAddress:(NSString *)address completionHandler:(CLGeocodeCompletionHandler)handler;

@end
