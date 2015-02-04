//
//  Tweet.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "Tweet.h"
#import "CacheController.h"
#import "DBService.h"

@implementation Tweet
+(instancetype)tweetWithId:(NSUInteger)tweetId text:(NSString *)text date:(NSString *)created_at username:(NSString *)name userAvatarURL:(NSString *)url {
    Tweet *newTweet = [[self alloc] initWithId:(NSUInteger)tweetId text:(NSString *)text date:(NSString *)created_at username:(NSString *)name userAvatarURL:(NSString *)url];
    return newTweet;
}

-(id)initWithId:(NSUInteger)tweetId text:(NSString *)text date:(NSString *)created_at username:(NSString *)name userAvatarURL:(NSString *)url {
    self = [super init];
    if (self) {
        _tweetId = tweetId;
        _text = text;
        _date = created_at;
        _username = name;
        _userAvatarURL = url;
        _imageData = nil;
    }
    return self;
}

-(void)queryGetImageData {
    NSData *imageData = [[CacheController sharedInstance] getImageDataByURLString:[self userAvatarURL]];
    if (imageData != nil) {
        [self setImageData:imageData];
    } else {
        __weak typeof(self) wself = self;
        [[DBService sharedInstance] queryGetImageDataByTweetId:[self tweetId] url:[self userAvatarURL]
                                      complete:^(NSData *data) {
                                          typeof(self) sself = wself;
                                          if (sself) {
                                              NSLog(@"complete: %d, data: %d", [sself tweetId], data == nil);
                                              if (data != nil) {
                                                  [sself setImageData:data];
                                                  [[CacheController sharedInstance]
                                                   saveImageDataWithURLString:data
                                                   url:[sself userAvatarURL]];
                                                  [sself.delegate reloadView];
                                              }
                                          }
                                      }];
    }
}

#pragma mark - Print method
-(void)print {
//    NSLog(@"{\n");
    NSLog(@" id: %d,\n", [self tweetId]);
//    NSLog(@" text: %@,\n", [self text]);
//    NSLog(@" date: %@,\n", [self date]);
//    NSLog(@" username: %@,\n", [self username]);
//    NSLog(@" userAvatarURL: %@\n", [self userAvatarURL]);
//    NSLog(@"}\n");
}
@end
