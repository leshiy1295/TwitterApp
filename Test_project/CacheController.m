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
        self->_cache = [[NSCache alloc] init];
    }
    return self;
}

-(NSData *)getImageDataByURLString:(NSString *)url {
    return [self->_cache objectForKey:url];
}

-(void)saveImageDataWithURLString:(NSData *)imageData url:(NSString *)url {
    [self->_cache setObject:imageData forKey:url];
}
@end
