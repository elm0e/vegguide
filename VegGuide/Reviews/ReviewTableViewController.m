//
// ReviewTableViewController.m
// VegGuide
//
// View controller for the VEGPlace Review UI
//
// Created by Eric Sorensen on 8/31/16.
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

#import <Foundation/NSNull.h>
#import "ReviewTableViewController.h"
#import "ReviewTableViewCell.h"
#import "VEGImageCache.h"

static NSString *kReviewTableCellReuseId = @"ReviewTableCell";

@interface ReviewTableViewController () <UITableViewDataSource>

@end

@implementation ReviewTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Reviews";
    UINib *reviewNib = [UINib nibWithNibName:kReviewTableCellReuseId bundle:nil];
    [self.tableView registerNib:reviewNib forCellReuseIdentifier:kReviewTableCellReuseId];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 150;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reviews.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReviewTableViewCell *cell = (ReviewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kReviewTableCellReuseId forIndexPath:indexPath];
    VEGReview *review = self.reviews[indexPath.row];
    cell.review.text = review.review;
    cell.age.text = review.age;
    cell.userName.text = review.userName;
    cell.ratingsImage.image = nil;
    NSObject *rating = review.rating;
    if ((rating != nil) && (rating != [NSNull null])) {
        cell.ratingsImage.image = [[VEGImageCache sharedInstance] loadRatingsImage:review.rating.intValue];
    }
    return cell;
}

@end
