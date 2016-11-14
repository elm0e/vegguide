//
// ImageCollectionViewController.m
// VegGuide
//
// View controller for the Place Image Collection view
//
// Created by Eric Sorensen on 8/26/16.
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

#import "ImageCollectionViewController.h"
#import "VEGImageCache.h"
#import "ImageCollectionViewCell.h"

@interface ImageCollectionViewController () {
    BOOL isInTransition;
    int currentIndex;
}

@end

@implementation ImageCollectionViewController

static NSString * const kCollectionCellReuseId = @"ImageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Gallery";
    [self setupCollectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)setupCollectionView {
    UINib *cellNib = [UINib nibWithNibName:kImageCollectionViewCellNib bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:kCollectionCellReuseId];
    [self.collectionView setContentInset:UIEdgeInsetsZero];
    isInTransition = NO;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.place.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kCollectionCellReuseId forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"thumbnail"];
    [cell.imageView invalidateIntrinsicContentSize];
    if (self.place.images.count > indexPath.row) {
        VEGImage *image = self.place.images[indexPath.row];
        if (image.files.count > 0) {
            VEGImageType imageType = (image.files.count > VEGImageTypeOriginal ? VEGImageTypeOriginal : image.files.count - 1);
            VEGImageFile *file = image.files[imageType];
            [[VEGImageCache sharedInstance] loadImage:file
                                               notify:^void(UIImage *image) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       cell.imageView.image = image;
                                                   });
                                               }];
        }
    }
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (isInTransition) {
        // During the transition the collection view cell sizes need to shrink in case they are too big for the new layout
        return CGSizeMake(0, 0);
    }
    return collectionView.frame.size;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.collectionView setAlpha:0.0f];
    CGPoint currentOffset = [self.collectionView contentOffset];
    currentIndex = currentOffset.x / self.collectionView.frame.size.width;
    
    isInTransition = YES;
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        isInTransition = NO;
        [self.collectionView.collectionViewLayout invalidateLayout];
        float offset = currentIndex * size.width;
        [self.collectionView setContentOffset:CGPointMake(offset, 0)];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
        [UIView animateWithDuration:0.125f animations:^{
            [self.collectionView setAlpha:1.0f];
        }];
    }];
}

@end
