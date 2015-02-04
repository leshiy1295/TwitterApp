//
//  CustomUILabel.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "CustomUIImage.h"

@implementation CustomUIImage

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(CGSize)intrinsicContentSize {
    if () {
        return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
    } else {
        return [super intrinsicContentSize];
    }
}

-(void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
}
@end
