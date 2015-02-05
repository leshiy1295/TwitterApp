//
//  FileLoader.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 05.02.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataLoader : NSObject
+(id)sharedInstance;
-(void)getDataByURLString:(NSString *)url complete:(void (^)(NSData *data))complete;
@end
