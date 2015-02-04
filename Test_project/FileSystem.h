//
//  FileSystem.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 29.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSystem : NSObject
+(NSString *)saveToFileWithURLString:(NSString *)url data:(NSData *)data;
+(NSData *)getDataFromFile:(NSString *)fileName;
@end
