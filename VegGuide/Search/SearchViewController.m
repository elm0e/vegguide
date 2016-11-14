//
// SearchViewController.m
// VegGuide
//
// View controller for the SearchView UI
//
// Created by Eric Sorensen on 8/17/16.
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

#import "SearchViewController.h"
#import "MasterViewController.h"
#import "SearchView.h"
#import "VEGLocationManager.h"
#import "VEGImageCache.h"
#import "LMONibView.h"
#import "MBProgressHUD.h"
#import "VEGPlace.h"
#import "VegGuideClient.h"
#import "WSCoachMarksView.h"
#import "LMOTablePopoverViewController.h"

@interface SearchViewController() {
    UIView *activeField;
}

@property (strong, nonatomic) CLLocation *currentLocation;

// Needed to set up segue to list controller
@property (strong, nonatomic) NSArray<VEGPlace *> *searchResults;
@property (strong, nonatomic) SearchCriteria *searchCriteria;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Search";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-header"]];
    self.navigationItem.titleView.userInteractionEnabled = YES;
    [self addTapRecognizer:self.navigationItem.titleView usingSelector:@selector(openVegGuideSite)];

    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc]
                                   initWithImage: [UIImage imageNamed:@"help"]
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(displayHelp)];
    self.navigationItem.rightBarButtonItem = helpButton;
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc]
                                   initWithImage: [UIImage imageNamed:@"info"]
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(displayInfo)];
    self.navigationItem.leftBarButtonItem = infoButton;
    
    SearchView *searchView = [[SearchView alloc] initFromClassNib];
    self.view = searchView;
    searchView.searchAddress.delegate = self;
    searchView.keyword.delegate = self;
    [searchView.searchButton addTarget:self action:@selector(displaySearchResults) forControlEvents:UIControlEventTouchUpInside];
    [searchView.radius addTarget:self action:@selector(showRadius:) forControlEvents:UIControlEventValueChanged];
    [self addTapRecognizer:searchView.resetButton usingSelector:@selector(resetLocation)];
    [self registerForKeyboardNotifications];
    [self restoreUserDefaults];
    
    [[VEGImageCache sharedInstance] clear];
    [[VEGLocationManager sharedInstance] addLocationObserver:self];
}

- (void) viewDidUnload {
    [super viewDidUnload];
    [[VEGLocationManager sharedInstance] removeLocationObserver:self];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[VEGLocationManager sharedInstance] requestCurrentLocation];
    [self enableSearchButton];
    [self checkCoachMarks];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[VEGImageCache sharedInstance] clear];    
}

- (void) addTapRecognizer:(UIView *)view usingSelector:(SEL)selector {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:singleTap];
}

- (void)displaySearchResults {
    SearchView *searchView = (SearchView *)self.view;
    if ((searchView.searchAddress.text.length != 0) || (self.currentLocation != nil)) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:searchView animated:YES];
        hud.graceTime = 1;
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = @"Searching";
        [self saveUserDefaults];
        SearchCriteria *criteria = [self searchCriteria];
        [[VegGuideClient sharedInstance] placesByCriteria:criteria
                                        completionHandler:^(NSArray<VEGPlace *> *places) {
                                            dispatch_async(dispatch_get_main_queue(), ^ { [hud hideAnimated:YES]; });
                                            if (places) {
                                                if (places.count > 0) {
                                                    self.searchCriteria = criteria;
                                                    self.searchResults = places;
                                                    [self performSegueWithIdentifier:@"showList" sender:self];
                                                } else {
                                                    NSString *message = @"No locations were found that matched your location and needs.";
                                                    [self showAlert:message withTitle:@"No Locations Found"];
                                                }
                                            } else {
                                                NSString *message = @"Unable to search for locations.  Please make sure that you have a data or wif-fi connction.";
                                                [self showAlert:message withTitle:@"Unable To Search"];
                                            }
                                            self.navigationItem.leftBarButtonItem.enabled = YES;
                                            self.navigationItem.rightBarButtonItem.enabled = YES;
                                        }];
    }
}

- (void) displayHelp {
    [self showCoachMarks];
}

- (void) displayInfo {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIView *infoView = [[[NSBundle mainBundle] loadNibNamed:@"VEGCredits" owner:self options:nil] objectAtIndex:0];
    infoView.frame = self.view.bounds;
    CGRect frame = CGRectMake(0, 0, infoView.bounds.size.width, infoView.bounds.size.height);
    infoView.bounds = frame;
    infoView.frame = frame;
    
    [self addTapRecognizer:[infoView viewWithTag:1] usingSelector:@selector(openVegGuideSite)];
    
    UILabel *labelView = [infoView viewWithTag:2];
    [self addTapRecognizer:labelView usingSelector:@selector(openVegGuideAbout)];
    NSMutableAttributedString *label = [[NSMutableAttributedString alloc]initWithString:labelView.text];
    NSRange range = [labelView.text rangeOfString:@"VegGuide.org"];
    [label addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
    labelView.attributedText = label;
    
    UIButton *closeButton = [infoView viewWithTag:4];
    [closeButton addTarget:self action:@selector(closeInfo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:infoView];
    
    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *versionBuildString = [NSString stringWithFormat:@"Version %@ (%@)", appVersionString, appBuildString];
    UILabel *versionLabel = [infoView viewWithTag:5];
    versionLabel.text = versionBuildString;

}

- (void) closeInfo {
    [[self.view.subviews lastObject] removeFromSuperview];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void) openVegGuideSite {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.vegguide.org"]];
}

- (void) openVegGuideAbout {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.vegguide.org/site/about"]];
}

- (void) saveUserDefaults {
    SearchView *searchView = (SearchView *)self.view;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:searchView.searchAddress.text forKey:@"searchAddress"];
    [userDefaults setInteger:searchView.vegLevel.selectedSegmentIndex forKey:@"vegLevel"];
    [userDefaults setInteger:searchView.radius.value forKey:@"radius"];
    [userDefaults setBool:searchView.openNow.on forKey:@"openNow"];
    [userDefaults setObject:searchView.keyword.text forKey:@"keyword"];
//    [userDefaults setInteger:searchView.sortBy.selectedSegmentIndex forKey:@"sortBy"];
    [userDefaults synchronize];
}

- (void) restoreUserDefaults {
    SearchView *searchView = (SearchView *)self.view;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    searchView.searchAddress.text = [userDefaults objectForKey:@"searchAddress"];
    searchView.vegLevel.selectedSegmentIndex = [userDefaults integerForKey:@"vegLevel"];
    NSInteger radius = [userDefaults integerForKey:@"radius"];
    if (radius) {
        searchView.radius.value = radius;
    }
    searchView.openNow.on = [userDefaults boolForKey:@"openNow"];
    searchView.keyword.text = [userDefaults objectForKey:@"keyword"];
//    searchView.sortBy.selectedSegmentIndex = [userDefaults integerForKey:@"sortBy"];
    [self showRadius:searchView.radius];
}

- (void) resetLocation {
    SearchView *searchView = (SearchView *)self.view;
    searchView.searchAddress.text = nil;
    [self enableSearchButton];
}

- (void)showRadius:(UISlider *)slider {
    float radius = roundf(slider.value);
    SearchView *searchView = (SearchView *)self.view;
    searchView.radiusUnitsLabel.text = [NSString stringWithFormat:@"%.0f miles", radius];
}

- (SearchCriteria *) searchCriteria {
    SearchView *searchView = (SearchView *)self.view;
    SearchCriteria *criteria = [[SearchCriteria alloc] init];
    criteria.searchAddress = searchView.searchAddress.text;
    criteria.vegLevel = searchView.vegLevel.selectedSegmentIndex;
    criteria.searchRadius = (int)searchView.radius.value;
    criteria.openNowOnly = searchView.openNow.on;
//    criteria.sortField = searchView.sortBy.selectedSegmentIndex;
    criteria.keyword = searchView.keyword.text;
    criteria.currentLocation = self.currentLocation;
    return criteria;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showList"]) {
        MasterViewController *controller = (MasterViewController *)[segue destinationViewController];
        controller.searchCriteria = self.searchCriteria;
        controller.places = self.searchResults;
    }
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    SearchView *searchView = (SearchView *)self.view;
    if (textField == searchView.searchAddress) {
        [self enableSearchButton];
        [self validateSearchAddress];
    }
    return false;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeField = nil;
}

- (void) enableSearchButton {
    if (self.isViewLoaded && self.view.window) {
        SearchView *searchView = (SearchView *)self.view;
        searchView.searchButton.enabled = ((searchView.searchAddress.text.length > 0) || self.currentLocation);
    }
}

- (void) validateSearchAddress {
    SearchView *searchView = (SearchView *)self.view;
    NSString *address = searchView.searchAddress.text;
    if (address && address.length > 0) {
        [[VEGLocationManager sharedInstance] validateAddress:address completionHandler:^(NSArray* placemarks, NSError* error) {
            if (error || (placemarks.count == 0)) {
                NSString *message = @"The address that you entered is not valid.  Please enter a full or partial address.  For example:  Minneapolis, MN or 55401 or Paris, France";
                [self showAlert:message withTitle:@"Location Problem"];
            } else if (placemarks.count == 1) {
                searchView.searchAddress.text = [self formatPlacemark:placemarks[0]];
            } else {
                NSMutableArray<NSString *> *choices = [[NSMutableArray alloc] init];
                for (CLPlacemark *placemark in placemarks) {
                    [choices addObject:[self formatPlacemark:placemark]];
                }
                [self chooseAddress:choices];
            }
        }];
    }
}

- (NSString *) formatPlacemark:(CLPlacemark *)placemark {
    NSString *placemarkText = NULL;
    NSArray<NSString *> *addressLines = placemark.addressDictionary[@"FormattedAddressLines"];
    if (addressLines && addressLines.count > 0) {
        NSMutableString *address = [[NSMutableString alloc] initWithCapacity:500];
        [addressLines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
            [address appendString:line];
            if (idx < addressLines.count - 1) {
                [address appendString:@", "];
            }
        }];
        placemarkText = address;
    } else {
        placemarkText = placemark.name;
    }
    return placemarkText;
}

- (void) chooseAddress:(NSArray<NSString *>*)addresses {
    SearchView *searchView = (SearchView *)self.view;
    LMOTablePopoverViewController *tablePopup = [[LMOTablePopoverViewController alloc]
                                                 initWithControl:searchView.searchAddress
                                                 choices:addresses
                                                 notify:^(NSString *choice, NSInteger row) {
                                                     searchView.searchAddress.text = choice;
                                                     [self dismissViewControllerAnimated:YES completion:nil];
                                                 }
                                                 ];
    [self presentViewController:tablePopup animated:YES completion:nil];
}

- (void) showAlert:(NSString *)message withTitle:(NSString *)title {
    if (self.isViewLoaded && self.view.window) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

#pragma mark - CoachMarks

// Show coach marks the first time the user runs the application
- (void) checkCoachMarks {
    BOOL coachMarksShown = [[NSUserDefaults standardUserDefaults] boolForKey:@"VEGCoachMarksSearchShown"];
    if (coachMarksShown == NO) {
        // Don't show again
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"VEGCoachMarksSearchShown"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // Show
        [self showCoachMarks];
    }
}

//TODO:ERIC:This does not work when part of the view is hidden (such as iPhone landscape)
- (void) showCoachMarks {
//    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//    BOOL isLandscape = ((orientation) == UIDeviceOrientationLandscapeLeft ||
//                        (orientation) == UIDeviceOrientationLandscapeRight);
    CGFloat offset = 65.f;
    CGFloat width = self.navigationController.view.frame.size.width;
    CGFloat center = width / 2.0;
    NSArray *coachMarks = @[
                            @{
                                @"rect": [NSValue valueWithCGRect:(CGRect){{0.0f, offset},{width, 75.0f}}],
                                @"caption": @"Enter the location to search, such as a postal code or a city and state.  Leave this blank to use your current location.",
                                @"shape": @"other"
                                },
                            @{
                                @"rect": [NSValue valueWithCGRect:(CGRect){{0.0f,offset+65.0f},{width,275.0f}}],
                                @"caption": @"Choose the types of places you are looking for to narrow the list of results",
                                @"shape": @"other"
                                },
                            @{
                                @"rect": [NSValue valueWithCGRect:(CGRect){{center-37,offset+332.0f},{75.0f,75.0f}}],
                                @"caption": @"Tap Search",
                                @"shape": @"circle"
                                },
                            
                            ];
    UIView *parent = self.navigationController.view;
    WSCoachMarksView *coachMarksView = [[WSCoachMarksView alloc] initWithFrame:parent.bounds coachMarks:coachMarks];
    [parent addSubview:coachMarksView];
    coachMarksView.maskColor = [UIColor darkGrayColor];
    coachMarksView.enableContinueLabel = true;
    coachMarksView.enableSkipButton = false;
    [coachMarksView start];
}

#pragma mark - VEGLocationManagerDelegate

- (void) didUpdateLocation:(CLLocation *)newLocation {
    self.currentLocation = newLocation;
    [self enableSearchButton];
}

- (void) didFailWithError:(NSError *)error {
    NSString *message = @"We are unable to determine your current location.  Please enter something in the Location address field and we will search from there instead.";
    [self showAlert:message withTitle:@"Location Problem"];
    self.currentLocation = nil;
    [self enableSearchButton];
}

#pragma mark - Keyboard Handling

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    UIScrollView *scrollView = [self.view.subviews firstObject];
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        [scrollView scrollRectToVisible:activeField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIScrollView *scrollView = [self.view.subviews firstObject];
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

@end
