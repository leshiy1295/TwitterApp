//
//  ImageController.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CacheController : NSObject
+(id)sharedInstance;
-(BOOL)wasImageDataAskedByURLString:(NSString *)url;
-(void)setImageDataAskedFlagByURLString:(NSString *)url;
-(NSData *)getImageDataByURLString:(NSString *)url;
-(void)saveImageDataWithURLString:(NSData *)imageData url:(NSString *)url;
@end