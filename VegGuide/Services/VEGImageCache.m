//
// VEGImageCache.m
// VegGuide
//
// Singleton service to manage and cache images loaded remotely
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

#import "VEGImageCache.h"

@interface VEGImageCache() {
    NSCache<NSString *, UIImage *> * imageCache;
}

@end

@implementation VEGImageCache

+ (instancetype) sharedInstance {
    static VEGImageCache *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (instancetype) init {
    if ( self = [super init] ) {
        imageCache = [[NSCache alloc] init];
        imageCache.countLimit = 100;
    }
    return self;
}

- (UIImage *) imageForPath:(NSString *)imagePath {
    UIImage *image = [imageCache objectForKey:imagePath];
    return image;
}

- (BOOL) loadImage:(VEGImageFile *)image notify:(ImageNotifyBlock)notifyBlock {
    return [self loadImageForPath:image.imagePath notify:notifyBlock];
}

- (BOOL) loadImageForPath:(NSString *)imagePath notify:(ImageNotifyBlock)notifyBlock {
    UIImage *image = [imageCache objectForKey:imagePath];
    if (image == nil) {
        [self _loadImage:imagePath notify:notifyBlock];
    } else {
        notifyBlock(image);
    }
    return (image != nil);
}

- (void) setImageForPath:(NSString *)imagePath forView:(UIImageView *)imageView placeHolder:(UIImage *)placeHolder {
    UIImage *image = [imageCache objectForKey:imagePath];
    if (image == nil) {
        imageView.image = placeHolder;
        [self _loadImage:imagePath notify:^void(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        }];
    } else {
        imageView.image = image;
    }
}

- (void) setImage:(UIImage *) image forPath:(NSString *)imagePath {
    [imageCache setObject:image forKey:imagePath];
}

- (void) _loadImage:(NSString *)imagePath notify:(ImageNotifyBlock)notifyBlock {
    NSURL *url = [NSURL URLWithString:imagePath];
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                [imageCache setObject:image forKey:imagePath];
                notifyBlock(image);
            }
        }
    }];
    [task resume];
}

- (void) clear {
    // The cache will prune itself on low-memory but for this app there are times when we know we can clear everything
    [imageCache removeAllObjects];
}

// Get the star image for a rating
// These are not async because they are used all over and need to be preloaded
- (UIImage *) loadRatingsImage:(float)rating {
    int full = rating;
    int partial = (rating - full) * 100;
    partial = (partial < 25 ? 0 : (partial < 50 ? 25 : (partial < 75 ? 50 : 75)));
    NSString *imageName = [NSString stringWithFormat:@"green-%d-%d", full, partial];
    return [UIImage imageNamed:imageName];
}


@end
