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
    SBJsonParser *jsonParser;
}

-(id)init {
    self = [super init];
    if (self) {
        self->jsonParser = [[SBJsonParser alloc] init];
    }
    return self;
}

-(NSArray *)parse:(NSString *)data {
    return [jsonParser objectWithString:data];
}
@end
