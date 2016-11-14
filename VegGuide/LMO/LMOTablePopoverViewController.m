//
// LMOTablePopoverViewController.m
//
// Create a table based popover
//
// Created by Eric Sorensen on 11/7/16.
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

#import "LMOTablePopoverViewController.h"

static NSString *kCellReuseId = @"LMOPopoverCellResuseId";

@interface LMOTablePopoverViewController()

@property (nonatomic, strong) NSArray *choices;
@property (nonatomic, strong) PopoverChoiceNotifyBlock notify;
@property (nonatomic, assign) CGFloat fontSize;

@end

@implementation LMOTablePopoverViewController

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Must use initWithControl or initWithButton to initialize"
                                 userInfo: nil];
}

- (id)initWithStyle:(UITableViewStyle)style {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Must use initWithControl or initWithButton to initialize"
                                 userInfo: nil];
}

-(id)initWithButton:(UIBarButtonItem *)button choices:(NSArray *)choices notify:(PopoverChoiceNotifyBlock)notifyBlock {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.fontSize = [UIFont systemFontSize];
        self.choices = choices;
        self.notify = notifyBlock;
        CGFloat width = [self calcPopupWidth:choices] + 40;
        UIPopoverPresentationController *popover = [self createPopoverWithWidth:width];
        popover.barButtonItem = button;
    }
    return self;
}

-(id)initWithControl:(UIView *)control choices:(NSArray *)choices notify:(PopoverChoiceNotifyBlock)notifyBlock {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.fontSize = 12.0;
        self.choices = choices;
        self.notify = notifyBlock;
        CGFloat width = [self calcPopupWidth:choices] + 40;
        if (width > control.frame.size.width) width = control.frame.size.width;
        UIPopoverPresentationController *popover = [self createPopoverWithWidth:width];
        popover.sourceView = control.superview;
        popover.sourceRect = control.frame;
    }
    return self;
}

- (UIPopoverPresentationController *) createPopoverWithWidth:(CGFloat)width {
    self.clearsSelectionOnViewWillAppear = NO;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellReuseId];
    self.preferredContentSize = CGSizeMake(width, _choices.count * 44);
    self.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popover = self.popoverPresentationController;
    popover.delegate = self;
    return popover;
}

// Calculate how wide the view should be based on the choices
- (CGFloat) calcPopupWidth:(NSArray *)choices {
    CGFloat largestLabelWidth = 0;
    for (NSString *choice in choices) {
        CGSize labelSize = [choice sizeWithAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:_fontSize] }];
        if (labelSize.width > largestLabelWidth) {
            largestLabelWidth = labelSize.width;
        }
    }
    return largestLabelWidth;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _choices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseId forIndexPath:indexPath];
    cell.textLabel.text = _choices[indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:_fontSize];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_notify != nil) {
        _notify(_choices[indexPath.row], indexPath.row);
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
