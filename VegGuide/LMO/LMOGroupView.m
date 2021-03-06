//
// LMOGroupView.m
//
// A UIView that can be used to group controls with a rounded border
// Use a UIView in the UI builder and then set the class to LMOGroupView.
// This should add the 3 properties in the UI builder (see names below)
//
// Based on an idea from spencery2 and marczking on Stack Overflow
//
// Created by Eric Sorensen on 8/18/16.
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

#import "LMOGroupView.h"

@implementation LMOGroupView

-(void)setBorderColor:(UIColor *)color {
    self.layer.borderColor = color.CGColor;
}

-(void)setBorderWidth:(CGFloat)width {
    self.layer.borderWidth = width;
}

-(void)setCornerRadius:(CGFloat)radius {
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = radius > 0;
}

@end
