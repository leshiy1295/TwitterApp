//
//  Prefetcher.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 01.02.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "Prefetcher.h"
#import "Tweet.h"

@implementation Prefetcher
+(void)prefetchImages:(NSArray *)tweets {
    for (Tweet *tweet in tweets) {
        if ([tweet imageData] == nil) {
            [tweet queryGetImageData];
        }
    }
}
@end
