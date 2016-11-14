//
// VEGImageFile.m
// VegGuide
//
// Model for an image file from the VegGuide API
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

#import "VegImageFile.h"

@implementation VEGImageFile

- (instancetype) initWithData:(NSDictionary *)fileData {
    if (self = [super init]) {
        _imagePath = [fileData valueForKey:@"uri"];
        _height = [[fileData valueForKey:@"height"] intValue];
        _width = [[fileData valueForKey:@"width"] intValue];
        _imageType = [self getImageType:_imagePath];
    }
    return self;
}

- (VEGImageType) getImageType:(NSString *)imageUri {
    if ([imageUri containsString:@"-mini"]) return VEGImageTypeMini;
    if ([imageUri containsString:@"-small"]) return VEGImageTypeSmall;
    if ([imageUri containsString:@"-large"]) return VEGImageTypeLarge;
    return VEGImageTypeOriginal;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@: %p %@>",
            [self class],
            self,
            @{ @"imageType" : @(_imageType),
               @"imagePath" : _imagePath,
               @"heigth" : @(_height),
               @"width" : @(_width) }
            ];
}


@end
