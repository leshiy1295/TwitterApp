//
//  Prefetcher.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 01.02.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "Prefetcher.h"
#import "Tweet.h"

@interface Prefetcher ()
@property (nonatomic, copy) NSArray *tArray;
@end

@implementation Prefetcher
-(void)prefetchImages:(NSArray *)tweets {
    self.tArray = tweets;
    __weak typeof(self) wself = self;
    typeof(self) sself = wself;
    if (sself != nil) {
        for (Tweet *tweet in sself.tArray) {
            if ([tweet imageData] == nil) {
                [tweet queryGetImageData];
            }
        }
    }
}
@end
