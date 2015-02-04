//
//  Parser.m
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import "Parser.h"
#import "SBJson.h"

@implementation Parser {
    SBJsonParser *_jsonParser;
    NSDateFormatter *_dateFormatter;
}

-(id)init {
    self = [super init];
    if (self) {
        _jsonParser = [[SBJsonParser alloc] init];
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return self;
}

-(NSArray *)parse:(NSString *)data {
    return [_jsonParser objectWithString:data];
}

-(NSString *)changeDateFormatWithString:(NSString *)dateString fromFormat:(NSString *)fromFormat
                    toFormat:(NSString *)toFormat {
    [_dateFormatter setDateFormat:fromFormat];
    NSDate *date = [_dateFormatter dateFromString:dateString];
    [_dateFormatter setDateFormat:toFormat];
    return [_dateFormatter stringFromDate:date];
}
@end
