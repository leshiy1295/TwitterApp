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
#import "FileSystem.h"
#import "DataLoader.h"

@implementation Tweet
+(instancetype)tweetWithId:(NSUInteger)tweetId text:(NSString *)text date:(NSString *)created_at
                    userId:(NSUInteger)userId username:(NSString *)name userAvatarURL:(NSString *)url {
    Tweet *newTweet = [[self alloc] initWithId:(NSUInteger)tweetId text:(NSString *)text
                                          date:(NSString *)created_at userId:(NSUInteger)userId
                                      username:(NSString *)name userAvatarURL:(NSString *)url];
    return newTweet;
}

-(id)initWithId:(NSUInteger)tweetId text:(NSString *)text date:(NSString *)created_at userId:(NSUInteger)userId
       username:(NSString *)name userAvatarURL:(NSString *)url {
    self = [super init];
    if (self) {
        _tweetId = tweetId;
        _text = text;
        _date = created_at;
        _userId = userId;
        _username = name;
        _userAvatarURL = url;
        _imageData = nil;
    }
    return self;
}

-(void)queryGetImageData {
    [self queryGetImageDataFromCache];
}

-(void)queryWasImageDataAsked {
    __weak typeof(self) wself = self;
    [[CacheController sharedInstance] queryWasImageDataAskedByURLString:[self userAvatarURL] complete:^{
        typeof(self) sself = wself;
        if (sself) {
            [sself queryGetImageDataFromDB];
        }
    }];
}

-(void)queryGetImageDataFromCache {
    __weak typeof(self) wself = self;
    [[CacheController sharedInstance] queryGetImageDataByURLString:[self userAvatarURL]
                                                                 complete:^(NSData *imageData) {
         typeof(self) sself = wself;
         if (sself) {
             if (imageData != nil) {
                 NSLog(@"success getting data from cache for id: %lu", (unsigned long)[sself tweetId]);
                 [sself setImageData:imageData];
                 [sself.delegate reloadView];
             } else {
                 [sself queryWasImageDataAsked];
             }
         }
     }];
}

-(void)querySaveImageDataInCache {
    [[CacheController sharedInstance] querySaveImageDataWithURLString:[self imageData] url:[self userAvatarURL]];
}

-(void)queryGetImageDataFromDB {
    __weak typeof(self) wself = self;
    [[DBService sharedInstance] queryGetImageDataURLByUserId:[self userId] url:[self userAvatarURL]
                                      complete:^(NSString *imageDataURL) {
      typeof(self) sself = wself;
      if (sself) {
          if (imageDataURL) {
              [sself queryGetImageDataFromFileSystemByURL:imageDataURL];
          } else {
              [sself queryGetImageDataFromDataLoader];
          }
      }
    }];
}

-(void)queryGetImageDataFromFileSystemByURL:(NSString *)imageDataURL {
    __weak typeof(self) wself = self;
    [[FileSystem sharedInstance] getDataFromFile:imageDataURL complete:^(NSData *imageData) {
        typeof(self) sself = wself;
        if (sself) {
            [sself setImageData:imageData];
            [sself querySaveImageDataInCache];
            [sself.delegate reloadView];
        }
    }];
}

-(void)querySaveImageDataInFileSystemAndDB {
    __weak typeof(self) wself = self;
    [[FileSystem sharedInstance] saveToFileWithURLString:[self userAvatarURL]
                                                    data:[self imageData]
                                                complete:^(NSString *fileName) {
        typeof(self) sself = wself;
        if (sself) {
            [[DBService sharedInstance] querySaveImageDataPathByUserId:[sself userId] filePath:fileName];
        }
    }];
}

-(void)queryGetImageDataFromDataLoader {
    __weak typeof(self) wself = self;
    [[DataLoader sharedInstance] getDataByURLString:[self userAvatarURL] complete:^(NSData *imageData) {
        typeof(self) sself = wself;
        if (sself) {
            [sself setImageData:imageData];
            [sself querySaveImageDataInFileSystemAndDB];
            [sself querySaveImageDataInCache];
            [sself.delegate reloadView];
        }
    }];
}

#pragma mark - Print method
-(void)print {
//    NSLog(@"{\n");
    NSLog(@" id: %lu,\n", (unsigned long)[self tweetId]);
//    NSLog(@" text: %@,\n", [self text]);
//    NSLog(@" date: %@,\n", [self date]);
//    NSLog(@" userId: %lu", (unsigned long)[self userId]);
//    NSLog(@" username: %@,\n", [self username]);
//    NSLog(@" userAvatarURL: %@\n", [self userAvatarURL]);
//    NSLog(@"}\n");
}
@end
