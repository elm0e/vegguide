//
// VegGuideClient.m
// VegGuide
//
// REST client to access the services provided by VegGuide.org
//
// Created by Eric Sorensen on 8/9/16.
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
#import "VegGuideClient.h"

@interface VegGuideClient()

@end


@implementation VegGuideClient

+ (instancetype) sharedInstance {
    static VegGuideClient *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (VegGuideClient *) init {
    if (self = [super init]) {
    }
    return self;
}

- (void) placesByCriteria:(SearchCriteria *)criteria completionHandler:(PlaceNotifyBlock)completionBlock {
    NSString *queryString = nil;
    if (criteria.isLocationSearch) {
        static NSString *urlString = @"https://www.vegguide.org/search/by-lat-long/%f,%f";
        queryString = [NSString stringWithFormat:urlString, criteria.currentLocation.coordinate.latitude, criteria.currentLocation.coordinate.longitude];
        
    } else {
        static NSString *urlString = @"https://www.vegguide.org/search/by-address/%@";
        queryString = [NSString stringWithFormat:urlString, criteria.searchAddress, criteria.searchRadius];
    }
    if (criteria.vegLevel > 0) {
        int vegLevel = [[VegGuideClient sharedInstance] vegLevelForCriteria:criteria];
        queryString = [queryString stringByAppendingFormat:@"/filter/veg_level=%d", vegLevel];
    }
    queryString = [queryString stringByAppendingFormat:@"?distance=%ld&unit=mile", (long)criteria.searchRadius];
    NSMutableArray<VEGPlace *> *places = [[NSMutableArray alloc] init];
    __block BOOL hadFailure = NO;
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        int pageCount = (criteria.keyword && criteria.keyword.length > 0) ? [self pageCountFor:queryString] : 1;
        for (int page = 1; page <= pageCount; page++) {
            dispatch_group_async(group, queue, ^{
                NSString *pageQueryString = [queryString stringByAppendingFormat:@"&page=%d&limit=100", page];
                NSDictionary *json = (NSDictionary *)[self submitSyncRequest:pageQueryString];
                hadFailure |= (!json);
                NSArray *entries = [json objectForKey:@"entries"];
                for (id entry in entries) {
                    VEGPlace *place = [[VEGPlace alloc] initWithData:entry];
                    if ((!criteria.openNowOnly || place.isOpen) &&
                        ((criteria.keyword == nil) || (criteria.keyword.length == 0) || [place contains:criteria.keyword])) {
                        @synchronized (places) {
                            [places addObject:place];
                        }
                    }
                }
            });
        }
        dispatch_group_notify(group, queue, ^{
            if (hadFailure) completionBlock(nil);
            NSRange range = NSMakeRange(0, (places.count > 100 ? 100 : places.count));
            NSArray<VEGPlace *> *sorted = [self sortPlaceResults:[places subarrayWithRange:range] by:VEGSearchSortDistance];
            completionBlock(sorted);
        });
    });
}

- (int) pageCountFor:(NSString *)queryString {
    int pageCount = 1;
    NSString *pageQueryString = [queryString stringByAppendingString:@"&page=1&limit=1"];
    NSDictionary *json = (NSDictionary *)[self submitSyncRequest:pageQueryString];
    if (json) {
        NSNumber *entryCount = [json objectForKey:@"entry_count"];
        if (entryCount) {
            pageCount = entryCount.intValue / 100 + 1;
        }
    }
    return pageCount;
}

- (int) vegLevelForCriteria:(SearchCriteria *)criteria {
    int vegLevelMapping[4] = {0, 1, 4, 5};
    return (criteria.vegLevel > 4 ?  5 : vegLevelMapping[criteria.vegLevel]);
}

- (NSArray<VEGPlace *> *) sortPlaceResults:(NSArray<VEGPlace *> *)places by:(VEGSearchSort) sort {
    switch (sort) {
        case VEGSearchSortName:
            return [places sortedArrayUsingComparator:^NSComparisonResult(VEGPlace *a, VEGPlace *b) {
                return [a.sortableName caseInsensitiveCompare:b.sortableName];
            }];
        case VEGSearchSortPrice:
            return [places sortedArrayUsingComparator:^NSComparisonResult(VEGPlace *a, VEGPlace *b) {
                return [a.priceRange caseInsensitiveCompare:b.priceRange];
            }];
        case VEGSearchSortRating:
            return [places sortedArrayUsingComparator:^NSComparisonResult(VEGPlace *a, VEGPlace *b) {
                return [b.weightedRating compare:a.weightedRating];
            }];
        case VEGSearchSortDistance:
        default:
            return [places sortedArrayUsingComparator:^NSComparisonResult(VEGPlace *a, VEGPlace *b) {
                return [a.distance compare:b.distance];
            }];
    }
}

- (void) reviewsForLocation:(NSString *)uri completionHandler:(ReviewNotifyBlock)completionBlock{
    [self submitRestRequest:uri completionHandler:^(NSObject *data) {
        NSArray<NSDictionary *> *json = (NSArray<NSDictionary *> *)data;
        NSMutableArray<VEGReview *> *reviews = [[NSMutableArray alloc] initWithCapacity:100];
        for (NSDictionary *review in json) {
            NSString *reviewText = [review valueForKeyPath:@"body.text/vnd.vegguide.org-wikitext"];
            if (reviewText && ![reviewText isEqual:[NSNull null]] && reviewText.length > 0) {
                [reviews addObject:[[VEGReview alloc] initWithData:review]];
            }
        }
        completionBlock(reviews);
    }];
}

- (void) submitRestRequest:(NSString *)requestUrl completionHandler:(RestNotifyBlock)completionBlock {
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    NSMutableURLRequest *request = [self createRequestFromURL:requestUrl];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id json  = nil;
        if (error == nil) {
            if (data) {
                NSError *jsonError;
                json  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                if (jsonError) NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
            }
        }
        else {
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
        completionBlock(json);
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (id) submitSyncRequest:(NSString *)requestUrl {
    NSMutableURLRequest *request = [self createRequestFromURL:requestUrl];
    NSURLResponse * response = nil;
    NSError *error = nil;;
    NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    id json  = nil;
    if (error == nil) {
        if (data) {
            NSError *jsonError;
            json  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
        }
    }
    else {
        NSLog(@"Request Failed: %@", [error localizedDescription]);
    }
    return json;
}

- (NSMutableURLRequest *) createRequestFromURL:(NSString *)requestUrl {
    NSURL *url = [NSURL URLWithString:[requestUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    // VegGuide Headers
    [request addValue:@"application/json;version=0.0.8" forHTTPHeaderField:@"Accept"];
    [request addValue:@"VegGuideIOS/v1.0" forHTTPHeaderField:@"User-Agent"];
    // Create task
    NSLog(@"Request = %@", request);
    return request;
}
@end
