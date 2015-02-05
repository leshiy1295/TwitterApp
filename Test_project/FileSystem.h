//
//  FileSystem.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 29.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSystem : NSObject
+(id)sharedInstance;
-(void)saveToFileWithURLString:(NSString *)url data:(NSData *)data
                            complete:(void (^)(NSString *fileName))complete;
-(void)getDataFromFile:(NSString *)fileName complete:(void (^)(NSData *data))complete;
@end
