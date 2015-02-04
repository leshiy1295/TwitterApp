//
//  DBService.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 29.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "DBService.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FileSystem.h"
#import "Tweet.h"

@implementation DBService {
    FMDatabaseQueue *_queue;
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
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dbPath = [documentsPath stringByAppendingPathComponent:@"tweets.db"];
        NSLog(@"%@",dbPath);
        _queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        _serialQuery = dispatch_queue_create("Serial database queue", DISPATCH_QUEUE_SERIAL);
        [self dbSchemeCheck];
    }
    return self;
}

-(void)dbSchemeCheck {
    dispatch_async(_serialQuery, ^{
        [_queue inDatabase:^(FMDatabase *db) {
            NSString *sql = @"CREATE TABLE IF NOT EXISTS `Tweets` ("
            "  `id` BIGINT NOT NULL,"
            "  `username` VARCHAR(255) NOT NULL,"
            "  `text` TEXT NOT NULL,"
            "  `date` DATETIME NOT NULL,"
            "  `avatarURL` VARCHAR(255) NOT NULL,"
            "  `imageDataURL` VARCHAR(255) DEFAULT NULL"
            ");";
            NSLog(@"query: %@", sql);
            NSLog(@"Creating table succeed: %hhd", [db executeUpdate:sql]);
        }];
    });
}

-(void)queryGetLastId:(void (^)(NSUInteger lastId))complete {
    dispatch_async(_serialQuery, ^{
        NSLog(@"start:queryGetLastId");
        NSUInteger __block lastId = 0;
        [_queue inDatabase:^(FMDatabase *db) {
            NSString *sql = @"SELECT MAX(`id`) FROM `Tweets`;";
            NSLog(@"query: %@", sql);
            FMResultSet *result = [db executeQuery:sql];
            if ([result next]) {
                lastId = [result intForColumnIndex:0];
                NSLog(@"lastId: %lu", (unsigned long)lastId);
            }
            [result close];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                NSLog(@"complete:queryGetLastId");
                complete(lastId);
            });
        }];
    });
}

-(void)queryGetSavedTweetsWithLimit:(NSUInteger)limit minDateTime:(NSString *)dateTime //minId:(NSUInteger)minId
                           complete:(void (^)(NSArray *))complete {
    dispatch_async(_serialQuery, ^{
        NSLog(@"start:queryGetSavedTweets");
        [_queue inDatabase:^(FMDatabase *db) {
            NSMutableArray *tweets = [[NSMutableArray alloc] init];
            //Below in comments variant for id
            //  NSString *sql = @"SELECT `id`, `username`, `text`, `date`, `avatarURL` FROM `Tweets`"
            //  "WHERE `id` < %lu ORDER BY `id` DESC LIMIT %lu;";
            //  NSLog(@"query: %@, id: %lu, limit: %lu", sql, (unsigned long)minId,
            //                                                (unsigned long)limit);
            //  FMResultSet *result = [db executeQueryWithFormat:sql, minId, limit];
            NSString *sql = @"SELECT `id`, `text`, `date`, `username`, `avatarURL` FROM `Tweets`"
                             " WHERE `date` < %@ ORDER BY `date` DESC LIMIT %lu;";
            NSLog(@"query: %@, date: %@, limit: %lu", sql, dateTime, (unsigned long)limit);
            FMResultSet *result = [db executeQueryWithFormat:sql, dateTime, limit];
            while ([result next]) {
                Tweet *tweet = [Tweet tweetWithId:[result intForColumnIndex:0]
                                             text:[result stringForColumnIndex:1]
                                             date:[result stringForColumnIndex:2]
                                         username:[result stringForColumnIndex:3]
                                    userAvatarURL:[result stringForColumnIndex:4]];
                [tweets addObject:tweet];
            }
            [result close];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                NSLog(@"complete:queryGetSavedTweets");
                complete(tweets);
            });
        }];
    });
}

-(void)querySaveTweets:(NSArray *)tweets complete:(void (^)(NSArray *))complete {
    dispatch_async(_serialQuery, ^{
        NSLog(@"start:querySaveTweets");
        [_queue inDatabase:^(FMDatabase *db) {
            NSString *selectSql = @"SELECT 1 FROM `Tweets` WHERE `date` = %@;";
            NSString *insertSql = @"INSERT INTO `Tweets` (`id`, `username`, `text`, `date`, `avatarURL`)"
            " VALUES (%lu, %@, %@, %@, %@);";
            for (Tweet *tweet in tweets) {
                NSLog(@"query: %@, id: %lu", selectSql, (unsigned long)[tweet tweetId]);
                FMResultSet *result = [db executeQueryWithFormat:selectSql, [tweet date]];
                if (![result next]) {
                    NSLog(@"query: %@, id: %lu", insertSql, (unsigned long)[tweet tweetId]);
                    NSLog(@"update succeed: %hhd", [db executeUpdateWithFormat:insertSql, [tweet tweetId], [tweet username], [tweet text], [tweet date], [tweet userAvatarURL]]);
                    NSArray *oneTweetArray = [[NSArray alloc] initWithObjects:tweet, nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"complete:querySaveTweets");
                        complete(oneTweetArray);
                    });
                }
                [result close];
            }
        }];
    });
}

-(void)queryGetImageDataByTweetId:(NSUInteger)tweetId
                              url:(NSString *)url
                         complete:(void (^)(NSData *))complete {
    dispatch_async(_serialQuery, ^{
        NSLog(@"start:queryGetImageData");
        [_queue inDatabase:^(FMDatabase *db) {
            NSString *sql = @"SELECT `imageDataURL` FROM `Tweets` WHERE id = %lu;";
            NSLog(@"query: %@, id: %lu", sql, (unsigned long)tweetId);
            FMResultSet *result = [db executeQueryWithFormat:sql, tweetId];
            if ([result next]) {
                NSString *imageDataURL = [result stringForColumnIndex:0];
                NSData *imageData;
                if (imageDataURL != nil) {
                    NSLog(@"imageDataURL: %@", imageDataURL);
                    imageData = [FileSystem getDataFromFile:imageDataURL];
                } else {
                    NSURL *imageURL = [NSURL URLWithString:url];
                    imageData = [NSData dataWithContentsOfURL:imageURL];
                    imageDataURL = [FileSystem saveToFileWithURLString:url data:imageData];
                    sql = @"UPDATE `Tweets` SET `imageDataURL` = %@ WHERE id = %lu;";
                    NSLog(@"query: %@, id: %lu", sql, (unsigned long)tweetId);
                    NSLog(@"Update succeed: %hhd", [db executeUpdateWithFormat:sql, imageDataURL, tweetId]);
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"complete:queryGetImageData");
                    complete(imageData);
                });
            }
            [result close];
        }];
    });
}
@end
