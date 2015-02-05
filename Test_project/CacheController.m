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
    }
    return self;
}

-(NSData *)getImageDataByURLString:(NSString *)url {
    return [_cache objectForKey:url];
}

-(void)saveImageDataWithURLString:(NSData *)imageData url:(NSString *)url {
    [_cache setObject:imageData forKey:url];
}

-(BOOL)wasImageDataAskedByURLString:(NSString *)url {
    id object = [_didImageDataAskedFlagsCache objectForKey:url];
    return object != nil;
}

-(void)setImageDataAskedFlagByURLString:(NSString *)url {
    [_didImageDataAskedFlagsCache setObject:@(1) forKey:url];
}
@end
