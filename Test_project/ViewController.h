//
//  ViewController.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 22.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface ViewController : UIViewController<UINavigationControllerDelegate> {
    NSTimer *timer;
    IBOutlet UILabel *timerLabel;
    IBOutlet UIButton *signInOutButton;
}
@end