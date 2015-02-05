//
//  FileSystem.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 29.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "FileSystem.h"
#import "Coder.h"

@implementation FileSystem {
    dispatch_queue_t _serialQueue;
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
        _serialQueue = dispatch_queue_create("Serial filesystem queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)saveToFileWithURLString:(NSString *)url data:(NSData *)data
                            complete:(void (^)(NSString *))complete {
    dispatch_async(_serialQueue, ^{
        NSString *encodedFileName = [Coder getSHA1ForString:url];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        path = [path stringByAppendingPathComponent:[Coder getSHA1ForString:@"images"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            if (![self createDirectoryWithPath:path]) {
                return;
            }
        }
        path = [path stringByAppendingPathComponent:encodedFileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"File %@ already exists", path);
        } else {
            if (![[NSFileManager defaultManager] createFileAtPath:path
                                                         contents:data
                                                       attributes:nil]) {
                NSLog(@"Create file error");
                return;
            }
            NSLog(@"File %@ successfully created", path);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
           complete(encodedFileName);
        });
    });
}

-(void)getDataFromFile:(NSString *)fileName complete:(void (^)(NSData *))complete {
    dispatch_async(_serialQueue, ^{
        NSData *data = nil;
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        path = [path stringByAppendingPathComponent:[Coder getSHA1ForString:@"images"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            path = [path stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                data = [[NSData alloc] initWithContentsOfFile:path];
            } else {
                NSLog(@"File %@ not exists", path);
            }
        } else {
            NSLog(@"Directory %@ not exists", path);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data != nil) {
                complete(data);
            } else {
                NSLog(@"getDataFromFile returned nil for file: %@", fileName);
            }
        });
    });
}

-(BOOL)createDirectoryWithPath:(NSString *)path {
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if ([[NSFileManager defaultManager] createDirectoryAtPath:path
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error]) {
            NSLog(@"Directory %@ successfully created", path);
            return YES;
        } else {
            NSLog(@"Create directory error: %@", error);
            return NO;
        }
    } else {
        NSLog(@"Directory %@ already exists", path);
        return YES;
    }
}
@end
