//
//  ViewController.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 22.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "ViewController.h"
#import "Tweets.h"
#import "GTMOAuthViewControllerTouch.h"
#import "CustomTableCell.h"
#import "Prefetcher.h"

@interface ViewController () <SettingsViewControllerDelegate, TweetDelegate, UITableViewDataSource, UITableViewDelegate>

@end

@implementation ViewController {
    NSUInteger _seconds;
    UITableView *_tableView;
    NSArray *_tweets;
}

NSString *const kShouldShowAvatars = @"shouldShowAvatars";
NSString *const kShouldSaveKeychain = @"shouldSaveKeychain";
NSString *const kTwitterKeychainItemName = @"TwitterKeychain";

const int SECONDS_COOLDOWN = 60;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTweets:) name:tweetsAreReady object:nil];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width,
                                                                     self.view.frame.size.height - 120)];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    [self initStartParams];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) initStartParams {
    if ([[Tweets sharedInstance] isSignedIn]) {
        [self queryOldTweets];
        [self queryNewTweets];
        [self startTimer];
    }
    [self updateUI];
}

-(void)substractTime {
    [timerLabel setText:[NSString stringWithFormat:@"Time: %lu", (unsigned long)--_seconds]];
    
    if (_seconds == 0) {
        _seconds = SECONDS_COOLDOWN;
        [self queryNewTweets];
    }
}

-(void)startTimer {
    _seconds = SECONDS_COOLDOWN;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                             target:self
                                           selector:@selector(substractTime)
                                           userInfo:nil
                                            repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


-(void)stopTimer {
    [timer invalidate];
}

#pragma mark - SettingsViewControllerDelegate Methods
-(BOOL)shouldSaveKeychain {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kShouldSaveKeychain];
}

-(void)toggleShouldSaveKeychain:(BOOL)isOn {
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kShouldSaveKeychain];
}

-(BOOL)shouldShowAvatars {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kShouldShowAvatars];
}

-(void)toggleShouldShowAvatars:(BOOL)isOn {
    if (isOn) {
        [Prefetcher prefetchImages:_tweets];
    }
    [_tableView reloadData];
    return [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:kShouldShowAvatars];
}

#pragma mark - UI Methods
-(IBAction)onSignInOutButtonClick:(id)sender {
    if (![[Tweets sharedInstance] isSignedIn]) {
        [self signInToTwitter];
    } else {
        [self signOut];
    }
}

-(void)updateUI {
    if (![[Tweets sharedInstance] isSignedIn]) {
        [signInOutButton setTitle:@"Sign in.." forState:0];
        [timerLabel setHidden:YES];
        [_tableView removeFromSuperview];
    } else {
        [signInOutButton setTitle:@"Sign out" forState:0];
        [timerLabel setHidden:NO];
        [timerLabel setText:[NSString stringWithFormat:@"Time: %i", _seconds]];
        [self.view addSubview:_tableView];
    }
}

-(IBAction)openSettingsView:(id)sender {
    SettingsViewController *settingsViewController;
    settingsViewController = [[SettingsViewController alloc] init];
    settingsViewController.delegate = self;
    [[self navigationController] pushViewController:settingsViewController animated:YES];
}

#pragma mark - OAuth methods
-(void)awakeFromNib {
    //Get the saved authentication, if any, from the keychain
    //Library's controller supports methods for saving and restoring
    //authentication under arbitrary keychain item names; these names
    //are up to the application and may reflect multiple accounts for
    //one ore more services
    GTMOAuthAuthentication *auth = [[Tweets sharedInstance] authForTwitter];
    if (auth) {
        [GTMOAuthViewControllerTouch authorizeFromKeychainForName:kTwitterKeychainItemName
                                                   authentication:auth];
    }
    //save the authentication object, which holds the auth tokens
    [[Tweets sharedInstance] setAuthentication:auth];
}

-(void)signOut {
    //remove the stored Twitter authentication from the keychan, if any
    [GTMOAuthViewControllerTouch removeParamsFromKeychainForName:kTwitterKeychainItemName];
    
    //setting auth to nil
    [[Tweets sharedInstance] setAuthentication:nil];
    
    //timer stop, if was
    [self stopTimer];
    
    [self updateUI];
}

-(void)signInToTwitter {
    [self signOut];
    
    NSURL *requestURL = [NSURL URLWithString:@"https://twitter.com/oauth/request_token"];
    NSURL *accessURL = [NSURL URLWithString:@"https://twitter.com/oauth/access_token"];
    NSURL *authorizeURL = [NSURL URLWithString:@"https://twitter.com/oauth/authorize"];
    NSString *scope = @"https://api.twitter.com/";
    
    GTMOAuthAuthentication *auth = [[Tweets sharedInstance] authForTwitter];
    
    //set the callback URL to which the site should redirect, and
    //for which the OAuth controller should look to determine when
    //sign-in has finished or been canceled
    //
    //This URL does not need to be for an actual web page
    [auth setCallback:@"http://www.example.com/OAuthCallback"];
    
    NSString *appServiceName = nil;
    if ([self shouldSaveKeychain])
        appServiceName = kTwitterKeychainItemName;
    
    GTMOAuthViewControllerTouch *viewControllerTouch;
    viewControllerTouch = [[GTMOAuthViewControllerTouch alloc] initWithScope:scope
                                                                    language:nil
                                                             requestTokenURL:requestURL
                                                           authorizeTokenURL:authorizeURL
                                                              accessTokenURL:accessURL
                                                              authentication:auth
                                                              appServiceName:appServiceName
                                                                    delegate:self
                                                            finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    // We can set a URL for deleting the cookies after sign-in so the next time
    // the user signs in, the browser does not assume the user is already signed
    // in
    [viewControllerTouch setBrowserCookiesURL:[NSURL URLWithString:@"https://api.twitter.com/"]];
    
    [[self navigationController] pushViewController:viewControllerTouch animated:YES];
}

-(void)viewController:(GTMOAuthViewControllerTouch *)viewController finishedWithAuth:(GTMOAuthAuthentication *)auth error:(NSError *)error {
    if (error != nil) {
        //Authentication failed (perhaps the user denied access, or closed the
        //window before granting success)
        NSLog(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; //kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            //show the body of the server's authentication failure response
            NSString *str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSLog(@"%@", str);
        }
        [[Tweets sharedInstance] setAuthentication:nil];
    } else {
        //Authentication succeed
        //
        //At this point, we either use the authentication object to explicity
        //authorize request, like
        //
        //  [auth authorizeRequest:myNSURLMutableRequest]
        //
        //or store the authentication object into a GTMHTTPFetcher object like
        //
        //  [fetcher setAuthorizer:auth]
        
        //Save the authentication object
        [[Tweets sharedInstance] setAuthentication:auth];
        
        [self startTimer];
        _tweets = @[];
        [self queryOldTweets];
        [self queryNewTweets];
        [self updateUI];
    }
}

#pragma mark - UpdateTweets Methods
-(void)queryNewTweets {
    if (![[Tweets sharedInstance] isSignedIn])
        [self signInToTwitter];
    else
        [[Tweets sharedInstance] getNewTweets];
}

-(void)queryOldTweets {
    if (![[Tweets sharedInstance] isSignedIn])
        [self signInToTwitter];
    else {
        [[Tweets sharedInstance] getOldTweets];
    }
}

-(void)showTweets:(NSNotification *)notification {
    NSLog(@"Received message!!!");
    NSMutableArray *newTweets = [NSMutableArray arrayWithArray:notification.userInfo[@"tweets"]];
    for (Tweet *tweet in newTweets) {
        tweet.delegate = self;
        [tweet print];
    }
    if ([notification.userInfo[@"newTweets"]  isEqual: @(YES)]) {
        [newTweets addObjectsFromArray:_tweets];
         _tweets = newTweets;
    } else {
        NSMutableArray *resultArray = [[NSMutableArray alloc] init];
        [resultArray addObjectsFromArray:_tweets];
        [resultArray addObjectsFromArray:newTweets];
        _tweets = resultArray;
    }
    
    if ([self shouldShowAvatars])
        [Prefetcher prefetchImages:newTweets];
    [self reloadView];
}

#pragma mark - TableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == [_tweets count]) {
        [self queryOldTweets];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tweets count] + 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] != [_tweets count])
        return 128;
    else
        return 50;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] != [_tweets count]) {
        CustomTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CustomTableCell"];
        if (!cell) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomTableCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        cell.nameLabel.text = [_tweets[[indexPath row]] valueForKey:@"username"];
        cell.dateLabel.text = [_tweets[[indexPath row]] valueForKey:@"date"];
        cell.textLabel.text = [_tweets[[indexPath row]] valueForKey:@"text"];
        if ([self shouldShowAvatars]) {
            if ([_tweets[[indexPath row]] imageData] == nil) {
                [_tweets[[indexPath row]] queryGetImageData];
            } else {
                cell.userAvatarImageView.image = [UIImage imageWithData:[_tweets[[indexPath row]] valueForKey:@"imageData"]];
                [cell.userAvatarImageView setHidden:NO];
            }
        } else {
            [cell.userAvatarImageView setHidden:YES];
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        }
        cell.textLabel.text = @"Show older tweets...";
        return cell;
    }
}

#pragma mark - TweetDelegate Methods
-(void)reloadView {
    [_tableView reloadData];
}
@end
