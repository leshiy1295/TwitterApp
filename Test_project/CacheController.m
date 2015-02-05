//
//  ImageController.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "CacheController.h"

@interface CacheController ()

@end

@implementation CacheController {
    dispatch_queue_t _serialQueue;
    NSCache *_cache;
    NSCache *_didImageDataAskedFlagsCache;
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
        _cache = [[NSCache alloc] init];
        _didImageDataAskedFlagsCache = [[NSCache alloc] init];
        _serialQueue = dispatch_queue_create("Serial cache queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)queryGetImageDataByURLString:(NSString *)url complete:(void (^)(NSData *))complete {
    dispatch_async(_serialQueue, ^{
        NSData *data = [_cache objectForKey:url];
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(data);
        });
    });
}

-(void)querySaveImageDataWithURLString:(NSData *)imageData url:(NSString *)url {
    dispatch_async(_serialQueue, ^{
        [_cache setObject:imageData forKey:url];
    });
}

-(void)queryWasImageDataAskedByURLString:(NSString *)url complete:(void (^)(void))complete {
    dispatch_async(_serialQueue, ^{
        id object = [_didImageDataAskedFlagsCache objectForKey:url];
        if (object == nil) {
            [_didImageDataAskedFlagsCache setObject:@(1) forKey:url];
            dispatch_async(dispatch_get_main_queue(), ^{
                complete();
            });
        }
    });
}
@end
