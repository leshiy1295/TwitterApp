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
                            "  `id` BIGINT PRIMARY KEY,"
                            "  `userId` BIGINT NOT NULL,"
                            "  `text` TEXT NOT NULL,"
                            "  `date` DATETIME NOT NULL"
                            ");";
            NSLog(@"query: %@", sql);
            NSLog(@"Creating table succeed: %hhd", [db executeUpdate:sql]);
            sql = @"CREATE TABLE IF NOT EXISTS `User` ("
                  "     `id` BIGINT PRIMARY KEY,"
                  "     `username` VARCHAR(255) NOT NULL,"
                  "     `avatarURL` VARCHAR(255) NOT NULL,"
                  "     `imageDataURL` VARCHAR(255) DEFAULT NULL"
                  ");";
            NSLog(@"query: %@", sql);
            NSLog(@"Creating table succeed: %hhd", [db executeUpdate:sql]);
            sql = @"CREATE INDEX IF NOT EXISTS `date` ON `Tweets` (`date`);";
        }];
    });
}

//Deprecated, because since_id isn't used in request
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
            //  NSString *sql = @"SELECT `Tweets`.`id`, `text`, `date`, `User`.`id`, `username`, `avatarURL`"
            //                  " FROM `Tweets`"
            //                  " JOIN `User` ON `userId` = `User`.`id`"
            //                  " WHERE `id` < %@ ORDER BY `id` DESC LIMIT %lu;";
            //  NSLog(@"query: %@, id: %lu, limit: %lu", sql, (unsigned long)minId,
            //                                                (unsigned long)limit);
            //  FMResultSet *result = [db executeQueryWithFormat:sql, minId, limit];
            NSString *sql = @"SELECT `Tweets`.`id`, `text`, `date`, `User`.`id`, `username`, `avatarURL`"
                            " FROM `Tweets`"
                            " JOIN `User` ON `userId` = `User`.`id`"
                            " WHERE `date` < %@ ORDER BY `date` DESC LIMIT %lu;";
            NSLog(@"query: %@, date: %@, limit: %lu", sql, dateTime, (unsigned long)limit);
            FMResultSet *result = [db executeQueryWithFormat:sql, dateTime, (unsigned long)limit];
            while ([result next]) {
                Tweet *tweet = [Tweet tweetWithId:[result intForColumnIndex:0]
                                             text:[result stringForColumnIndex:1]
                                             date:[result stringForColumnIndex:2]
                                           userId:[result intForColumnIndex:3]
                                         username:[result stringForColumnIndex:4]
                                    userAvatarURL:[result stringForColumnIndex:5]];
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
            NSString *insertTweetsSql = @"INSERT INTO `Tweets` (`id`, `userId`, `text`, `date`)"
                                        " VALUES (%lu, %lu, %@, %@);";
            NSString *insertUserSql = @"INSERT INTO `User` (`id`, `username`, `avatarURL`)"
                                      " VALUES (%lu, %@, %@)";
            for (Tweet *tweet in tweets) {
                NSLog(@"query: %@, id: %lu", selectSql, (unsigned long)[tweet tweetId]);
                FMResultSet *result = [db executeQueryWithFormat:selectSql, (unsigned long)[tweet date]];
                if (![result next]) {
                    NSLog(@"query: %@, id: %lu", insertTweetsSql, (unsigned long)[tweet tweetId]);
                    NSLog(@"update succeed: %hhd", [db executeUpdateWithFormat:insertTweetsSql,
                                                    (unsigned long)[tweet tweetId], [tweet userId],
                                                    [tweet text], [tweet date]]);
                    NSLog(@"query: %@, id: %lu", insertUserSql, (unsigned long)[tweet tweetId]);
                    NSLog(@"update succeed: %hhd", [db executeUpdateWithFormat:insertUserSql,
                                                    (unsigned long)[tweet userId], [tweet username], [tweet userAvatarURL]]);
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

-(void)queryGetImageDataURLByUserId:(NSUInteger)userId
                              url:(NSString *)url
                         complete:(void (^)(NSString *))complete {
    dispatch_async(_serialQuery, ^{
        NSLog(@"start:queryGetImageData");
        [_queue inDatabase:^(FMDatabase *db) {
            NSString *sql = @"SELECT `imageDataURL` FROM `User` WHERE id = %lu;";
            NSLog(@"query: %@, userId: %lu", sql, (unsigned long)userId);
            FMResultSet *result = [db executeQueryWithFormat:sql, (unsigned long)userId];
            if ([result next]) {
                NSString *imageDataURL = [result stringForColumnIndex:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"complete:queryGetImageData for userId: %lu", (unsigned long)userId);
                    complete(imageDataURL);
                });
            }
            [result close];
        }];
    });
}

-(void)querySaveImageDataPathByUserId:(NSUInteger)userId filePath:(NSString *)filePath {
    dispatch_async(_serialQuery, ^{
        NSLog(@"start:querySaveImageData");
        [_queue inDatabase:^(FMDatabase *db) {
            NSString *sql = @"UPDATE `User` SET `imageDataURL` = %@ WHERE id = %lu;";
            NSLog(@"query: %@, userId: %lu", sql, (unsigned long)userId);
            NSLog(@"Update succeed: %hhd", [db executeUpdateWithFormat:sql, filePath, (unsigned long)userId]);
        }];
    });
}
@end
