//
//  MasterViewController.m
//  VegGuide
//
//  Created by Eric Sorensen on 8/4/16.
//  Copyright © 2016 Ambient Software Services. All rights reserved.
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
#import <UIKit/UISearchBar.h>
#import "MasterViewController.h"
#import "PlaceViewController.h"
#import "MBProgressHUD.h"
#import "VegGuideClient.h"
#import "PlaceListCell.h"
#import "VEGPlace.h"
#import "VEGImageCache.h"
#import "PlaceAnnotation.h"
#import "MapViewController.h"

static NSString *kPlaceInfoCellId = @"PlaceListInfoCell";

@interface MasterViewController () <UITableViewDataSource>

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray<VEGPlace *> *filteredPlaces;
@property (assign, nonatomic) int rowOffset;
@property (strong, nonatomic) UITableViewCell *infoCell;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Results";
    // Configure search bar and use this controller
    self.filteredPlaces = [[NSMutableArray alloc] init];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = false;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = false;
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.placeholder = @"Enter a search term";
    searchBar.searchBarStyle = UISearchBarStyleDefault;
    [searchBar sizeToFit];
    self.tableView.tableHeaderView = searchBar;
    // Set up table view cell from nib
    UINib *placeNib = [UINib nibWithNibName:kPlaceCellIdentifier bundle:nil];
    [self.tableView registerNib:placeNib forCellReuseIdentifier:kPlaceCellIdentifier];
    // Update search criteria with a location is this is an address search
    [self setCurrentLocation];
    // Special handling for informational first row
    self.rowOffset = [self specialFirstCell] ? 1 : 0;
    self.infoCell = [self searchSummaryCell];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Restore the search bar
    self.searchController.searchBar.hidden = NO;
}

-(void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    if (!parent){
        // If moving back to the search screen via the back button we need to manually disable
        // the search controller for some reason or it shows on the parent screen
        self.searchController.active = false;
    }
}

#pragma mark - Segues

- (void)configureMap:(UIStoryboardSegue *)segue {
    MapViewController *controller = [segue destinationViewController];
    controller.places = self.places;
    // Size the map based on the search
    controller.mapSize = self.searchCriteria.searchRadius * 2 * 1.6 * 1000; // Radius to diameter to meters
    // Center map on current location if available
    if (self.searchCriteria.currentLocation != nil) {
        controller.mapCenter = self.searchCriteria.currentLocation.coordinate;
    }
}

- (void) setCurrentLocation {
    if (!self.searchCriteria.isLocationSearch ) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:self.searchCriteria.searchAddress completionHandler:^(NSArray* placemarks, NSError* error){
            if (placemarks.count > 0) {
                CLPlacemark *placemark = (CLPlacemark *) placemarks[0];
                self.searchCriteria.currentLocation = placemark.location;
            }
        }];
    }
}

- (void)configureDetail:(UIStoryboardSegue *)segue {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath) {
        VEGPlace *place = [self placeAtIndex:indexPath];
        PlaceViewController *controller = (PlaceViewController *)[segue destinationViewController];
        controller.place = place;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        [self configureDetail:segue];
    }
    if ([[segue identifier] isEqualToString:@"showMap"]) {
        [self configureMap:segue];
    }
    // Hide the search bar on child views
    [self.searchController.searchBar resignFirstResponder];
    self.searchController.searchBar.hidden = YES;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.searchBar.text.length > 0) {
        return _filteredPlaces.count;
    }
    return (_places == nil ? 0 : _places.count + _rowOffset);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self specialFirstCell] && (indexPath.row == 0) && (self.searchController.searchBar.text.length == 0)) {
        return self.infoCell;
    }
    VEGPlace *place = [self placeAtIndex:indexPath];
    PlaceListCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlaceCellIdentifier forIndexPath:indexPath];
    cell.thumbnail.image = [UIImage imageNamed:@"thumbnail"];
    NSString *imagePath = place.thumbnailImagePath;
    if (imagePath) {
        [[VEGImageCache sharedInstance] loadImageForPath:imagePath
                                                  notify:^void(UIImage *image) {
                                                      [self setCellImage:image tableView:tableView cellForRowAtIndexPath:indexPath];
                                                  }];
    }
    [cell populate:place];
    return cell;
}

- (VEGPlace *) placeAtIndex:(NSIndexPath *)indexPath {
    if (self.searchController.searchBar.text.length > 0) {
        return [_filteredPlaces objectAtIndex:indexPath.row];
    }
    return [_places objectAtIndex:indexPath.row - _rowOffset];
}

- (BOOL) specialFirstCell {
    return (_places == nil ? NO : (_places.count == 100 ? YES : NO));
}

- (void) setCellImage:(UIImage *)image tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        PlaceListCell *updateCell = (id)[tableView cellForRowAtIndexPath:indexPath];
        if (updateCell) {
            updateCell.thumbnail.image = image;
        }
    });
}

- (UITableViewCell *) searchSummaryCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kPlaceInfoCellId];
    cell.textLabel.text = @"First 100 Locations by Distance";
    cell.detailTextLabel.text = @"Use a keyword or smaller area to limit results.";
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.row >= _rowOffset) || (self.searchController.searchBar.text.length > 0)) {
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
}

#pragma mark - UISearchResultsUpdating

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController {
    [_filteredPlaces removeAllObjects];
    NSString *searchString = searchController.searchBar.text;
    if (searchString.length > 0) {
        [_places enumerateObjectsUsingBlock:^(VEGPlace *place, NSUInteger idx, BOOL *stop) {
            if ([place contains:searchString]) {
                [_filteredPlaces addObject:place];
            }
        }];
    }
    [self.tableView reloadData];
}


@end
