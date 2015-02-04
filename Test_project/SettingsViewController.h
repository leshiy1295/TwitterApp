//
//  SettingsViewController.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 26.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UIViewController {
    IBOutlet UISwitch *shouldSaveKeychainSwitch;
    IBOutlet UISwitch *shouldShowAvatars;
}
@property (weak) id<SettingsViewControllerDelegate> delegate;
@end

@protocol SettingsViewControllerDelegate <NSObject>
@required
-(BOOL)shouldSaveKeychain;
-(void)toggleShouldSaveKeychain:(BOOL)isOn;
-(BOOL)shouldShowAvatars;
-(void)toggleShouldShowAvatars:(BOOL)isOn;
-(void)closeSettingsView;
@end
