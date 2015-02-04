//
//  Parser.h
//  Test_project
//
//  Created by Alexey Halaidzhy on 27.01.15.
//  Copyright (c) 2015 Alexey Halaidzhy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Parser : NSObject
-(NSArray *)parse:(NSString *)data;
-(NSString *)changeDateFormatWithString:(NSString *)dateString fromFormat:(NSString *)fromFormat
                       toFormat:(NSString *)toFormat;
@end
