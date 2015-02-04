//
//  CustomTableCell.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (nonatomic, weak) IBOutlet UIImageView *userAvatarImageView;
@end
