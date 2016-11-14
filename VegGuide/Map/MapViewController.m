//
// MapViewController.m
// VegGuide
//
// View controller for the Map UI
//
// Created by Eric Sorensen on 8/23/16.
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

#import <MapKit/MapKit.h>
#import <UIKit/UIBarButtonItem.h>
#import "MapViewController.h"
#import "PlaceViewController.h"
#import "PlaceAnnotation.h"
#import "VEGLocationManager.h"
#import "VEGImageCache.h"
#import "LMOTablePopoverViewController.h"

@interface MapViewController ()

@property (nonatomic, strong) UIPopoverPresentationController *mapActionPopover;
//@property (nonatomic, strong) MapActionViewController *mapActionContoller;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"";
    // Add a button in the navbar to open external map apps
    [self addMapButton];
    // Set up the map
    [self configureMap];
}

- (void) addMapButton {
    if (_places.count == 1) {
        SEL action = nil;
        BOOL isPresenting = [self presentedViewController] != nil; // Can't present action popover if search bar is active
        if (isPresenting) {
            // Don't use popover - go directly to Apple maps
            action = @selector(openInAppleMaps);
        } else {
            // Add nav button to open in Google/Apple maps if there is only 1 place i.e. from details page
            action = @selector(openMapActionPopover);
        }
        UIBarButtonItem *mapButton = [[UIBarButtonItem alloc]
                                      //initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                      //initWithImage: [UIImage imageNamed:@"info"]
                                      initWithTitle:@"Directions"
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:action];
        self.navigationItem.rightBarButtonItem = mapButton;
    }
}

- (void) openMapActionPopover {
    NSArray<NSString *> *actions = @[@"Open in Apple Maps", @"Open in Google Maps"];
    LMOTablePopoverViewController *tablePopup = [[LMOTablePopoverViewController alloc]
                                                 initWithButton:self.navigationItem.rightBarButtonItem
                                                 choices:actions
                                                 notify:^(NSString *choice, NSInteger row) {
                                                     [self openInMapsApp:row];
                                                     [self dismissViewControllerAnimated:YES completion:nil];
                                                 }
                                                 ];
    [self presentViewController:tablePopup animated:YES completion:nil];
}

- (void) openInMapsApp:(NSInteger)mapType {
    if (mapType == 0) {
        [self openInAppleMaps];
    } else {
        [self openInGoogleMaps];
    }
}

- (void) openInAppleMaps {
    VEGPlace *place = _places[0];
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:place.location.coordinate addressDictionary:nil];
    MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:placemark];
    item.name = place.name;
    [item openInMapsWithLaunchOptions:nil];
}

- (void) openInGoogleMaps {
    VEGPlace *place = _places[0];
    CLLocationCoordinate2D location = place.location.coordinate;
    NSString *urlString = [NSString stringWithFormat:@"comgooglemaps://?center=%f,%f&q=%@,%@,%@",location.latitude,location.longitude, place.name, place.city, place.postalCode];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        NSString *message = @"Unable to open the Google Maps application.  Use Apple Maps instead?";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Google Maps Unavailable" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self openInAppleMaps];
            });
            
        }];
        [alert addAction:okAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)configureMap {
    MKMapView *view = (MKMapView *)self.view;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapCenter, self.mapSize, self.mapSize);
    [view setRegion:region animated:NO];
    // Remove existing annotations
    for (id annotation in view.annotations) {
        [view removeAnnotation:annotation];
    }
    // Create pins for all of the locations
    for (VEGPlace *place in self.places) {
        [self addPlace:place];
    }
}

- (void) addPlace:(VEGPlace *)place {
    if (place.location) {
        [self addPlaceAnnotation:place];
    } else {
        VEGLocationManager *locationManager = [VEGLocationManager sharedInstance];
        [locationManager requestPlaceLocation:place completionHandler:^(NSArray* placemarks, NSError* error) {
            [self addPlaceAnnotation:place];
        }];
    }
}

- (void) addPlaceAnnotation:(VEGPlace *)place {
    if (place.location) {
        MKMapView *view = (MKMapView *)self.view;
        PlaceAnnotation *point = [[PlaceAnnotation alloc] init];
        point.coordinate = place.location.coordinate;
        point.title = place.name;
        point.place = place;
        [view addAnnotation:point];
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    static NSString *pinID = @"com.ambient.client.VegGuide.pin";
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pinID];
    if (annotationView == nil)
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinID];
    //annotationView.pinTintColor = [MKPinAnnotationView greenPinColor]; //iOS 9
    annotationView.pinColor = MKPinAnnotationColorGreen;
    annotationView.animatesDrop = NO;
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return annotationView;
}

// Pin Image
//static NSString *defaultPinID = @"org.elmoe.VegGuide.pin";
//MKPinAnnotationView *annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
//if (annotationView == nil)
//annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
////    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"loc"];
//annotationView.canShowCallout = YES;
//annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//annotationView.image = [UIImage imageNamed:@"thumbnail"];
//

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"showMapDetail" sender:view];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showMapDetail"]) {
        PlaceViewController *controller = (PlaceViewController *)[segue destinationViewController];
        MKAnnotationView *view = (MKAnnotationView *)sender;
        PlaceAnnotation *annotation = (PlaceAnnotation *)view.annotation;
        controller.place = annotation.place;
    }
}

@end
