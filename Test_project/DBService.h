//
//  DBService.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 29.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBService : NSObject
+(id)sharedInstance;
-(void)queryGetLastId:(void (^)(NSUInteger lastId))complete;
-(void)queryGetSavedTweetsWithLimit:(NSUInteger)limit minDateTime:(NSString *)dateTime
                              //minId:(NSUInteger)minId
                           complete:(void (^)(NSArray *tweets))complete;
-(void)querySaveTweets:(NSArray *)tweets complete:(void (^)(NSArray *tweets))complete;
-(void)queryGetImageDataByTweetId:(NSUInteger)tweetId url:(NSString *)url
                         complete:(void (^)(NSData *data))complete;
@end