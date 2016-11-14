//
// VEGFavoritesList.m
// VegGuide
//
// Singleton service to manage a list of favorites
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

#import "VEGFavoritesList.h"

@interface VEGFavoritesList() {
    NSMutableArray *favorites;
}

@end

@implementation VEGFavoritesList

+ (instancetype) sharedInstance {
    static VEGFavoritesList *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *storedFavorites = [defaults objectForKey:@"favorites"];
        if (storedFavorites) {
            favorites = [storedFavorites mutableCopy];
        } else {
            favorites = [NSMutableArray array];
        }
    }
    return self;
}

- (void) addFavorite:(id)item {
    [favorites insertObject:item atIndex:0];
}

- (void) removeFavorite:(id)item{
    [favorites removeObject:item];
    [self saveFavorites];
}

- (NSArray *) getFavorites {
    return [favorites copy];
}

- (void) saveFavorites {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:favorites forKey:@"favorites"];
    [defaults synchronize];
}

@end
