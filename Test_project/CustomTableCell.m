//
//  CustomTableCell.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "CustomTableCell.h"

@interface CustomTableCell ()

@end

@implementation CustomTableCell
@synthesize nameLabel = _nameLabel;
@synthesize dateLabel = _dateLabel;
@synthesize textLabel = _textLabel;
@synthesize userAvatarImageView = _userAvatarImageView;
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
