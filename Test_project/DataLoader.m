//
//  FileLoader.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 05.02.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "DataLoader.h"

@implementation DataLoader {
    dispatch_queue_t _serialQuery;
}
+(id)sharedInstance {
    static dispatch_once_t once_token;
    static id _instance = nil;
    
    dispatch_once(&once_token, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

-(id)init {
    self = [super init];
    if (self) {
        _serialQuery = dispatch_queue_create("Serial dataloader queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)getDataByURLString:(NSString *)url complete:(void (^)(NSData *))complete {
    dispatch_async(_serialQuery, ^{
        NSURL *dataURL = [NSURL URLWithString:url];
        NSData *receivedData = [NSData dataWithContentsOfURL:dataURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (receivedData != nil) {
                complete(receivedData);
            } else {
                NSLog(@"getDataByURLString returned nil for url: %@", url);
            }
        });
    });
}
@end
