//
//  Tweets.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 22.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "Tweets.h"
#import "Parser.h"
#import "DBService.h"

@interface Tweets ()
@end

@implementation Tweets {
    GTMOAuthAuthentication *_auth;
    NSMutableData *_responseData;
    BOOL _newTweets;
    NSUInteger _minIdInThatSession;
    NSString *_minDateTimeInThatSession;
    NSString *_maxDateTimeInThatSession;
}

const NSUInteger amountOfTweetsToAsk = 20;
NSString *const tweetsAreReady = @"tweetsAreReady";
NSString *const kTwitterServiceName = @"Twitter";

+(id)sharedInstance {
    static dispatch_once_t once_token;
    static id _instance = nil;
    
    dispatch_once(&once_token, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

-(id)init {
    self = [super init];
    if (self) {
        self->_minIdInThatSession = -1;
        self->_minDateTimeInThatSession = @"9999-12-12 23:59:59";
        self->_maxDateTimeInThatSession = @"0000-00-00 00:00:00";
    }
    return self;
}

#pragma mark - OAuth methods
-(BOOL)isSignedIn {
    BOOL isSignedIn = [self->_auth canAuthorize];
    return isSignedIn;
}

-(GTMOAuthAuthentication *)authForTwitter {
    NSString *myConsumerKey = @"XmEY9VHvZLjqxCBzgoRfjG6F4";
    NSString *myConsumerSecret = @"e3Lmv7idgJFFPgJbdWEdCJdENkwSRBMGzLhUx8jBHKK8wqjdSL";
    
    GTMOAuthAuthentication *auth;
    auth = [[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                       consumerKey:myConsumerKey
                                                        privateKey:myConsumerSecret];
    
    //setting the service name lets us inspect the auth object later to know what service it is for
    [auth setServiceProvider:kTwitterServiceName];
    return auth;
}

-(void)setAuthentication:(GTMOAuthAuthentication *)auth {
    self->_auth = auth;
}

-(void)doAnAuthenticatedAPIFetchWithQueryId:(NSUInteger)queryId newTweets:(BOOL)newTweets {
    //Twitter status feed
    NSMutableString *urlStr = [NSMutableString stringWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    [urlStr appendFormat:@"?count=%lu", (unsigned long)amountOfTweetsToAsk];
    if (newTweets) {
//        [urlStr appendFormat:@"&since_id=%lu", (unsigned long)queryId];
    } else {
        [urlStr appendFormat:@"&max_id=%lu", (unsigned long)queryId];
    }
    NSLog(@"%@", urlStr);
    
    NSURL *url = [NSURL URLWithString:urlStr];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [_auth authorizeRequest:request];
    //NOTE: for requests with body, such as PUT or POST, the library will include the body
    //data when signing only if the request has the proper content-type header
    //
    //  [request setValue:@"application/x-www-form-urlencoded"
    // forHTTPHeaderField:@"Content-Type"];
    
    //Create url connection and fire request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [conn start];
}

#pragma mark - NSURLConnection Delegate Methods
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    //A response has been received, this is where we initialize the instance var created
    //to append data to it then in the didReceiveData method
    //Furthermore, this method is called each time there is a redirect to reinitializing it
    //also serves to clear it
    self->_responseData = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //Append the new data to the instance variable you declared
    [self->_responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //The request is complete and data has been received
    //You can parse the stuff in your instance variable now
    NSString *result = [[NSString alloc] initWithData:self->_responseData encoding:NSUTF8StringEncoding];
    if (![result containsString:@"\"errors\""]) {
        Parser *parser = [[Parser alloc] init];
        NSArray *dataObject = [parser parse:result];
    
        NSMutableArray *tweets = [[NSMutableArray alloc] init];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSDate *date;
        NSString *dataStr;
        for (NSDictionary *tweetData in dataObject) {
            BOOL tweetsAreRelevant = NO;
            [dateFormatter setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
            date = [dateFormatter dateFromString:[tweetData valueForKey:@"created_at"]];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            dataStr = [dateFormatter stringFromDate:date];
            if (self->_newTweets && [dataStr compare:self->_maxDateTimeInThatSession] > 0) {
                tweetsAreRelevant = YES;
            } else if (!(self->_newTweets) && [dataStr compare:self->_minDateTimeInThatSession] < 0) {
                tweetsAreRelevant = YES;
            }
            if (tweetsAreRelevant) {
                Tweet *tweet = [Tweet tweetWithId:(NSUInteger)[tweetData valueForKey:@"id"]
                                             text:[tweetData valueForKey:@"text"]
                                             date:dataStr
                                         username:[tweetData valueForKeyPath:@"user.name"]
                                    userAvatarURL:[tweetData valueForKeyPath:@"user.profile_image_url"]];
                [tweets addObject:tweet];
            }
        }
        //Sort
        NSArray *sortedTweets = [tweets sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Tweet *tObj1 = (Tweet *)obj1;
            Tweet *tObj2 = (Tweet *)obj2;
            return [[tObj1 date] compare:[tObj2 date]];
        }];
        [self saveTweetsInDB:sortedTweets];
    } else {
        NSLog(@"%@", result);
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //The request has failed for some reason!
    //Check the error var
    NSLog(@"%@", error);
}

-(void)notifyTweetsAreReady:(NSArray *)tweets {
    [[NSNotificationCenter defaultCenter] postNotificationName:tweetsAreReady object:self
                                                      userInfo:@{@"tweets":tweets,
                                                                 @"newTweets":@(self->_newTweets)}];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        typeof(self) sself = wself;
        if (sself) {
            for (Tweet *tweet in tweets) {
                if ([tweet tweetId] < sself->_minIdInThatSession)
                    sself->_minIdInThatSession = [tweet tweetId] - 1;
                if ([sself->_minDateTimeInThatSession compare:[tweet date]] > 0) {
                    sself->_minDateTimeInThatSession = [tweet date];
                }
                if ([sself->_maxDateTimeInThatSession compare:[tweet date]] < 0) {
                    sself->_maxDateTimeInThatSession = [tweet date];
                }
            }
        }
    });
}

#pragma mark - DB Methods
-(void)saveTweetsInDB:(NSArray *)tweets {
    __weak typeof(self) wself = self;
    [[DBService sharedInstance] querySaveTweets:tweets complete:^(NSArray *tweets) {
        typeof(self) sself = wself;
        if (sself != nil) {
            [sself notifyTweetsAreReady:tweets];
        }
    }];
}

-(void)getOldTweets {
    self->_newTweets = NO;
    __weak typeof(self) wself = self;
    [[DBService sharedInstance] queryGetSavedTweetsWithLimit:amountOfTweetsToAsk
                                                 minDateTime:self->_minDateTimeInThatSession
                                                       //minId:self->_minIdInThatSession
                                                    complete:^(NSArray *tweets) {
                                                        typeof(self) sself = wself;
                                                        if (sself != nil) {
                                                            if ([tweets count] == 0) {
                                                                [sself getOlderTweets];
                                                            }
                                                            [sself notifyTweetsAreReady:tweets];
                                                        }
                                                    }];
}

-(void)getOlderTweets {
    [self doAnAuthenticatedAPIFetchWithQueryId:self->_minIdInThatSession newTweets:NO];
}

-(void)getNewTweets {
    self->_newTweets = YES;
    __weak typeof(self) wself = self;
    [[DBService sharedInstance] queryGetLastId:^(NSUInteger lastId){
        typeof(self) sself = wself;
        if (sself != nil) {
            [sself doAnAuthenticatedAPIFetchWithQueryId:lastId + 1 newTweets:YES];
        }
    }];
}
@end

