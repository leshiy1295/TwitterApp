//
//  FileSystem.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 29.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "FileSystem.h"
#import "Coder.h"

@implementation FileSystem
+(NSString *)saveToFileWithURLString:(NSString *)url data:(NSData *)data {
    NSString *encodedFileName = [Coder getSHA1ForString:url];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:[Coder getSHA1ForString:@"images"]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (![self createDirectoryWithPath:path]) {
            return nil;
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
            return nil;
        }
        NSLog(@"File %@ successfully created", path);
    }
    return encodedFileName;
}

+(NSData *)getDataFromFile:(NSString *)fileName {
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
    return data;
}

+(BOOL)createDirectoryWithPath:(NSString *)path {
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
