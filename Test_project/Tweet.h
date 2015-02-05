//
//  Tweet.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TweetDelegate;

@interface Tweet : NSObject
-(void)queryGetImageData;
@property (assign, nonatomic, readonly) NSUInteger tweetId;
@property (assign, nonatomic, readonly) NSUInteger userId;
@property (copy, nonatomic, readonly) NSString *text;
@property (copy, nonatomic, readonly) NSString *date;
@property (copy, nonatomic, readonly) NSString *username;
@property (copy, nonatomic, readonly) NSString *userAvatarURL;
@property (copy, nonatomic) NSData *imageData;
@property (weak) id<TweetDelegate> delegate;
+(instancetype)tweetWithId:(NSUInteger)tweetId text:(NSString *)text date:(NSString *)created_at
                    userId:(NSUInteger)userId username:(NSString *)name userAvatarURL:(NSString *)url;
-(void)print;
@end

@protocol TweetDelegate <NSObject>
-(void)reloadView;
@end