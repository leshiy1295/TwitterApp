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
        _minIdInThatSession = -1;
        _minDateTimeInThatSession = @"9999-12-12 23:59:59";
        _maxDateTimeInThatSession = @"0000-00-00 00:00:00";
    }
    return self;
}

#pragma mark - OAuth methods
-(BOOL)isSignedIn {
    BOOL isSignedIn = [_auth canAuthorize];
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
    _auth = auth;
}

-(void)doAnAuthenticatedAPIFetchWithQueryId:(NSUInteger)queryId {
    //Twitter status feed
    NSMutableString *urlStr = [NSMutableString stringWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    [urlStr appendFormat:@"?count=%lu", (unsigned long)amountOfTweetsToAsk];
    
    //_newTweets variable shows whether we should get the latest tweets or older. So in case newTweets is YES
    //one should use queryId parameter as since_id which is optional. Because of API shuffles tweet's id anyway
    //and after getting tweets there is a filter for them and they become sorted, that parameter is
    //unneccessary. In other case, if newTweets is NO one should get old tweets, and query_id is used as max_id
    //paameter. Although request to API with that parameter returns empty array, so it doesn't work at all, but
    //nevertheless here this code should be retained for future API updates.
    if (_newTweets) {
    //    [urlStr appendFormat:@"&since_id=%lu", (unsigned long)queryId];
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
    _responseData = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //The request is complete and data has been received
    //You can parse the stuff in your instance variable now
    NSString *result = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    if (![result containsString:@"\"errors\""]) {
        Parser *parser = [[Parser alloc] init];
        NSArray *dataObject = [parser parse:result];
    
        NSMutableArray *tweets = [[NSMutableArray alloc] init];
        for (NSDictionary *tweetData in dataObject) {
            NSString *date = [parser changeDateFormatWithString:[tweetData valueForKey:@"created_at"]
                                                     fromFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"
                                                       toFormat:@"yyyy-MM-dd HH:mm:ss"];
            BOOL tweetsAreRelevant = NO;
            if (_newTweets && [date compare:_maxDateTimeInThatSession] > 0) {
                tweetsAreRelevant = YES;
            } else if (!_newTweets && [date compare:_minDateTimeInThatSession] < 0) {
                tweetsAreRelevant = YES;
            }
            if (tweetsAreRelevant) {
                Tweet *tweet = [Tweet tweetWithId:(NSUInteger)[tweetData valueForKey:@"id"]
                                             text:[tweetData valueForKey:@"text"]
                                             date:date
                                           userId:(NSUInteger)[tweetData valueForKeyPath:@"user.id"]
                                         username:[tweetData valueForKeyPath:@"user.name"]
                                    userAvatarURL:[tweetData valueForKeyPath:@"user.profile_image_url"]];
                [tweets addObject:tweet];
            }
        }
        //Sorting tweets by date
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
                                                                 @"newTweets":@(_newTweets)}];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        typeof(self) sself = wself;
        if (sself) {
            for (Tweet *tweet in tweets) {
                if ([tweet tweetId] < _minIdInThatSession)
                    _minIdInThatSession = [tweet tweetId] - 1;
                if ([_minDateTimeInThatSession compare:[tweet date]] > 0) {
                    _minDateTimeInThatSession = [tweet date];
                }
                if ([_maxDateTimeInThatSession compare:[tweet date]] < 0) {
                    _maxDateTimeInThatSession = [tweet date];
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
        if (sself) {
            [sself notifyTweetsAreReady:tweets];
        }
    }];
}

-(void)getOldTweets {
    _newTweets = NO;
    __weak typeof(self) wself = self;
    //Old tweets should be found by id, but in that case they won't be sorted by date. Because of that here
    //parameter minId is in comments and there is another parameter - minDateTime. So really
    [[DBService sharedInstance] queryGetSavedTweetsWithLimit:amountOfTweetsToAsk
                                                 minDateTime:_minDateTimeInThatSession
                                                       //minId:_minIdInThatSession
                                                    complete:^(NSArray *tweets) {
        typeof(self) sself = wself;
        if (sself) {
            if ([tweets count] == 0) {
                [sself getOlderTweets];
            }
            [sself notifyTweetsAreReady:tweets];
        }
    }];
}

-(void)getOlderTweets {
    [self doAnAuthenticatedAPIFetchWithQueryId:_minIdInThatSession];
}

-(void)getNewTweets {
    _newTweets = YES;
    [self doAnAuthenticatedAPIFetchWithQueryId:0];
//Deprecated because since_id isn't used in request
//    __weak typeof(self) wself = self;
//    [[DBService sharedInstance] queryGetLastId:^(NSUInteger lastId) {
//        typeof(self) sself = wself;
//        if (sself) {
//            [sself doAnAuthenticatedAPIFetchWithQueryId:lastId + 1];
//        }
//    }];
}
@end

