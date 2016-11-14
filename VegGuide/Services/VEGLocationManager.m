//
// VEGLocationManager.m
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

#import "VEGLocationManager.h"

@interface VEGLocationManager () <CLLocationManagerDelegate> {
    NSHashTable<id<VEGLocationManagerDelegate>> *observers;
}

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation VEGLocationManager

+ (instancetype) sharedInstance {
    static VEGLocationManager *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (VEGLocationManager *) init {
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationManager.distanceFilter =  kCLDistanceFilterNone;
        [self.locationManager requestWhenInUseAuthorization];
        _currentLocation = nil;
        observers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    return self;
}

- (void) addLocationObserver:(id<VEGLocationManagerDelegate>)listener {
    [observers addObject:listener];
}

- (void) removeLocationObserver:(id<VEGLocationManagerDelegate>)listener {
    [observers removeObject:listener];
}

- (void) requestCurrentLocation {
    if ([self.locationManager respondsToSelector:@selector(requestLocation)]) {
        [self.locationManager requestLocation];
    } else {
        // Workaround for iOS 8.0-8.3
        [self.locationManager startUpdatingLocation];
    }
}

- (void) requestPlaceLocation:(VEGPlace *)place completionHandler:(CLGeocodeCompletionHandler)handler {
    NSString *address = [NSString stringWithFormat:@"%@, %@, %@, %@", place.address1, place.city, place.postalCode, place.country];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:address completionHandler:^(NSArray* placemarks, NSError* error){
        if (placemarks.count > 0) place.location = ((CLPlacemark *)placemarks[0]).location;
        handler(placemarks, error);
    }];
}

- (void) validateAddress:(NSString *)address completionHandler:(CLGeocodeCompletionHandler)handler {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:address completionHandler:^(NSArray* placemarks, NSError* error) {
        handler(placemarks, error);
    }];
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //NSLog(@"Authorization status changed to %d", status);
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self requestCurrentLocation];
            break;
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location Request Failed: %ld", (long)error.code);
    if (![self.locationManager respondsToSelector:@selector(requestLocation)]) {
        [self.locationManager stopUpdatingLocation];
    }
    _currentLocation = nil;
    [[observers allObjects] enumerateObjectsUsingBlock:^(id<VEGLocationManagerDelegate>listener, NSUInteger idx, BOOL *stop) {
        [listener didFailWithError:error];
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = [locations lastObject];
    if (![self.locationManager respondsToSelector:@selector(requestLocation)]) {
        [self.locationManager stopUpdatingLocation];
    }
    //NSLog(@"Current Location: %f, %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    if (newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > 500 || newLocation.verticalAccuracy > 100) {
        // invalid accuracy
        NSString *domain = @"Location provided was not accruate enough";
        NSError *error = [[NSError alloc] initWithDomain:domain code:99 userInfo:nil];
        [self locationManager:manager didFailWithError:error];
        return;
    }
    _currentLocation = newLocation;
    [[observers allObjects] enumerateObjectsUsingBlock:^(id<VEGLocationManagerDelegate>listener, NSUInteger idx, BOOL *stop) {
        if (listener) {
            [listener didUpdateLocation:newLocation];
        }
    }];
}


@end
