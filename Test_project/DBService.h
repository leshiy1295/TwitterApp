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
-(void)queryGetSavedTweetsWithLimit:(NSUInteger)limit minDateTime:(NSString *)dateTime
                           complete:(void (^)(NSArray *tweets))complete;
-(void)querySaveTweets:(NSArray *)tweets complete:(void (^)(NSArray *tweets))complete;
-(void)queryCheckVolumeAndDeleteIfNeeded:(NSUInteger)count maxVolume:(NSUInteger)maxVolume;
-(void)queryGetImageDataURLByUserId:(NSUInteger)userId url:(NSString *)url
                         complete:(void (^)(NSString *imageDataURL))complete;
-(void)querySaveImageDataPathByUserId:(NSUInteger)userId filePath:(NSString *)filePath;
@end