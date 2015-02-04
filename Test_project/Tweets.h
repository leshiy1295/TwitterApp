//
//  Tweets.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 22.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTMOAuthAuthentication.h"
#import "Tweet.h"

FOUNDATION_EXPORT NSString *const tweetsAreReady;

@interface Tweets : NSObject <NSURLConnectionDelegate>
+(id)sharedInstance;
-(void)getNewTweets;
-(void)getOldTweets;
-(BOOL)isSignedIn;
-(GTMOAuthAuthentication *)authForTwitter;
-(void)setAuthentication:(GTMOAuthAuthentication *)auth;
@end