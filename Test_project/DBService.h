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
//One should use minId here but here will be used dateTime for filtering and sorting tweets
-(void)queryGetSavedTweetsWithLimit:(NSUInteger)limit minDateTime:(NSString *)dateTime
                              //minId:(NSUInteger)minId
                           complete:(void (^)(NSArray *tweets))complete;
-(void)querySaveTweets:(NSArray *)tweets complete:(void (^)(NSArray *tweets))complete;
-(void)queryGetImageDataURLByTweetId:(NSUInteger)tweetId url:(NSString *)url
                         complete:(void (^)(NSString *imageDataURL))complete;
-(void)querySaveImageDataPathByTweetId:(NSUInteger)tweetId filePath:(NSString *)filePath;
@end