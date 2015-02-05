//
//  SettingsViewController.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 26.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Settings";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(back)];
    self.navigationItem.leftBarButtonItem = backButton;
    [shouldSaveKeychainSwitch setOn:[self.delegate shouldSaveKeychain]];
    [shouldShowAvatars setOn:[self.delegate shouldShowAvatars]];
}

-(void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(IBAction)onShouldShowAvatarChange:(id)sender {
    [self.delegate toggleShouldShowAvatars:[sender isOn]];
}

-(IBAction)onShouldSaveKeyChange:(id)sender {
    [self.delegate toggleShouldSaveKeychain:[sender isOn]];
}
@end
