//
// PlaceViewController.m
// VegGuide
//
// View controller for the Place Detail UI
//
// Created by Eric Sorensen on 8/4/16.
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

#import "PlaceViewController.h"
#import "PlaceDetailView.h"
#import "WebsiteViewController.h"
#import "ImageCollectionViewController.h"
#import "PlaceAnnotation.h"
#import "MapViewController.h"
#import "VEGImageCache.h"
#import "VEGImage.h"
#import "VEGImageFile.h"
#import "ImageCollectionViewCell.h"
#import "ReviewTableViewController.h"
#import "VegGuideClient.h"
#import "LMONibView.h"
#import "MBProgressHUD.h"
#import "VEGLocationManager.h"

static NSString *kPlaceImageCellId = @"placeImageCell";

@interface PlaceViewController ()

@end

@implementation PlaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)configureView {
    // Add the detail view and size it according to the frame
    PlaceDetailView *detailView = [[PlaceDetailView alloc] initFromClassNib];
    if (detailView) {
        self.view = detailView;
        // Populate detail view
        if (self.place) {
            self.title = self.place.name;
            [detailView populate:_place];
        }
        // Make the scroll view large enough to hold the dynamic description
        UIScrollView *scrollView = [[detailView subviews] firstObject];
        CGSize contentSize = detailView.bounds.size;
        contentSize.height = 1000;
        scrollView.contentSize = contentSize;
        // Add event listeners
        if (self.place.phone.length > 0) {
            UITapGestureRecognizer *phoneCallTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(placePhoneCall)];
            phoneCallTap.numberOfTapsRequired = 1;
            phoneCallTap.numberOfTouchesRequired = 1;
            [detailView.phoneLabel.superview addGestureRecognizer:phoneCallTap];
        }
        if (self.place.website.length > 0) {
            UITapGestureRecognizer *webSiteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showWebSite)];
            webSiteTap.numberOfTapsRequired = 1;
            webSiteTap.numberOfTouchesRequired = 1;
            [detailView.websiteLabel.superview addGestureRecognizer:webSiteTap];
        }
        if (self.place.ratingCount.intValue) {
            UITapGestureRecognizer *reviewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showReviews)];
            reviewTap.numberOfTapsRequired = 1;
            reviewTap.numberOfTouchesRequired = 1;
            [detailView.ratingCountLabel addGestureRecognizer:reviewTap];
        }
        // Set up Map for this place
        [self configurePlaceMap];
        // Manage image collection
        UICollectionView *imageList = [self findCollectionViewInView:scrollView];
        if (imageList) {
            if (self.place.images.count) {
                [imageList setDataSource:self];
                [imageList setDelegate:self];
                UINib *cellNib = [UINib nibWithNibName:kImageCollectionViewCellNib bundle:nil];
                [imageList registerNib:cellNib forCellWithReuseIdentifier:kPlaceImageCellId];
                [imageList setBackgroundColor:[UIColor whiteColor]];
                [imageList setPagingEnabled:YES];
                // Configure flow
                UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)imageList.collectionViewLayout;
                [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
                [flowLayout setMinimumInteritemSpacing:2.0f];
                [flowLayout setMinimumLineSpacing:2.0f];
                // Set segue for displaying images in their own screen
                UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showImages)];
                imageTap.numberOfTapsRequired = 1;
                imageTap.numberOfTouchesRequired = 1;
                [detailView.images addGestureRecognizer:imageTap];
            } else {
                // Remove empty image list from layout so description moves up
                CGRect imageFrame = imageList.frame;
                imageFrame.size.height = 0;
                [imageList setFrame:imageFrame];
                [[imageList constraints] enumerateObjectsUsingBlock:
                 ^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
                     NSLog(@"%@", constraint.description);
                     constraint.constant = 0;
                 }];
            }
        }
    }
}

- (UICollectionView *) findCollectionViewInView:(UIView *)view {
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)subView;
        }
    }
    return nil;
}

- (UILabel *) labelIn:(UIView *)view withText:(NSString *)text {
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subView;
            if ([label.text isEqualToString:text]) {
                return label;
            }
        }
    }
    return nil;
}

- (void)configurePlaceMap {
    VEGPlace *place = self.place;
    if (place.location) {
        [self addPlaceAnnotation];
    } else {
        VEGLocationManager *locationManager = [VEGLocationManager sharedInstance];
        [locationManager requestPlaceLocation:place completionHandler:^(NSArray* placemarks, NSError* error){
            [self addPlaceAnnotation];
        }];
    }
    // Setup transition to full map when the in-place map is clicked
    PlaceDetailView *detailView = (PlaceDetailView *)self.view;
    MKMapView *mapView = detailView.map;
    UITapGestureRecognizer *mapSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMap)];
    mapSingleTap.numberOfTapsRequired = 1;
    mapSingleTap.numberOfTouchesRequired = 1;
    [mapView addGestureRecognizer:mapSingleTap];
}

- (void) addPlaceAnnotation {
    VEGPlace *place = self.place;
    if (place.location) {
        PlaceDetailView *detailView = (PlaceDetailView *)self.view;
        MKMapView *mapView = detailView.map;
        int mapSize = 1600;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(place.location.coordinate, mapSize, mapSize);
        [mapView setRegion:region animated:NO];
        PlaceAnnotation *point = [[PlaceAnnotation alloc] init];
        point.coordinate = place.location.coordinate;
        point.title = place.name;
        point.place = place;
        [mapView addAnnotation:point];
    }
}

#pragma mark - Segues

- (void)showImages {
    [self performSegueWithIdentifier:@"showImages" sender:self];
}

- (void)showWebSite {
    [self performSegueWithIdentifier:@"showWebsite" sender:self];
}

- (void)showMap {
    [self performSegueWithIdentifier:@"showPlaceMap" sender:self];
}

- (void)showReviews {
    [self performSegueWithIdentifier:@"showReviews" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showWebsite"]) {
        WebsiteViewController *controller = (WebsiteViewController *)[segue destinationViewController];
        controller.title = @"Website";
        controller.url = self.place.website;
    }
    if ([[segue identifier] isEqualToString:@"showPlaceMap"]) {
        MapViewController *mapController = (MapViewController *)[segue destinationViewController];
        //mapController.title = @"Location";
        mapController.places = [[NSArray alloc] initWithObjects:self.place, nil];
        mapController.mapSize = 1600;
        mapController.mapCenter = self.place.location.coordinate;
    }
    if ([[segue identifier] isEqualToString:@"showImages"]) {
        ImageCollectionViewController *imageController = (ImageCollectionViewController *)[segue destinationViewController];
        imageController.title = @"Images";
        imageController.place = self.place;
    }
    if ([[segue identifier] isEqualToString:@"showReviews"]) {
        ReviewTableViewController *controller = (ReviewTableViewController *)[segue destinationViewController];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = @"Loading";
        [[VegGuideClient sharedInstance] reviewsForLocation:self.place.reviewsUri completionHandler:^(NSArray<VEGReview *> *reviews) {
            dispatch_async(dispatch_get_main_queue(), ^{
                controller.reviews = reviews;
                [controller.tableView reloadData];
                [hud hideAnimated:YES];
            });
        }];
    }
}

- (void) placePhoneCall {
    if (self.place.phone && (self.place.phone.length > 0)) {
        NSURL *phoneUrl = [NSURL URLWithString:[@"telprompt://" stringByAppendingString:self.place.phone]];
        NSURL *phoneFallbackUrl = [NSURL URLWithString:[@"tel://" stringByAppendingString:self.place.phone]];
        if ([UIApplication.sharedApplication canOpenURL:phoneUrl]) {
            [UIApplication.sharedApplication openURL:phoneUrl];
        } else if ([UIApplication.sharedApplication canOpenURL:phoneFallbackUrl]) {
            [UIApplication.sharedApplication openURL:phoneFallbackUrl];
        } else {
            NSString *message = @"Unable to make phone calls on this device";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Phone Unavailable" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.place.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPlaceImageCellId forIndexPath:indexPath];
    if (self.place.images.count > indexPath.row) {
        VEGImage *image = self.place.images[indexPath.row];
        if (image.files.count > 0) {
            VEGImageFile *file = image.files[VEGImageTypeMini];
            [[VEGImageCache sharedInstance] loadImage:file
                                               notify:^void(UIImage *image) {
                                                   [self setCellImage:collectionView cellForItemAtIndexPath:indexPath withImage:image];
                                               }];
        }
    }
    return cell;
}

- (void) setCellImage:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath withImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.imageView.image = image;
    }
    });
}

#pragma mark <UICollectionViewFlowDelegate>

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.frame.size.height,collectionView.frame.size.height);
}


@end
