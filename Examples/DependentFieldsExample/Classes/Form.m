//
//  Form.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "Form.h"

@implementation Form

- (id)init
{
    if ((self = [super init]))
    {
        _year = NSNotFound;
        _month = NSNotFound;
    }
    return self;
}

// configure the date fields

- (NSDictionary *)yearField
{
    NSMutableArray *years = [NSMutableArray array];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
    for (NSInteger i = [components year]; i >= 1900 ; i--)
    {
        [years addObject:@(i)];
    }
    
    return @{FXFormFieldOptions: years, FXFormFieldPlaceholder: @"-", FXFormFieldAction: @"updateFields"};
}

- (NSDictionary *)monthField
{
    NSArray *months = @[@"January",
                        @"February",
                        @"March",
                        @"April",
                        @"May",
                        @"June",
                        @"July",
                        @"August",
                        @"September",
                        @"October",
                        @"November",
                        @"December"];
    
    return @{FXFormFieldOptions: months, FXFormFieldPlaceholder: @"-", FXFormFieldAction: @"updateFields"};
}

- (NSDictionary *)dayField
{
    NSMutableArray *days = [NSMutableArray array];
    if (self.year != NSNotFound && self.month != NSNotFound)
    {
        NSArray *daysPerMonth = @[@31, @28, @31, @30, @31, @30, @31, @31, @30, @31, @30, @31];
        NSInteger max = [daysPerMonth[self.month] integerValue];
        if (self.month == 1 && (self.year % 4 == 0 || self.year % 1000 == 0))
        {
            max = 29; //leap year
        }
        for (NSInteger i = 1; i <= max; i++)
        {
            [days addObject:@(i)];
        }
        return @{FXFormFieldOptions: days, FXFormFieldPlaceholder: @"-"};
    }
    else
    {
        return @{FXFormFieldType: FXFormFieldTypeLabel, FXFormFieldValueTransformer: ^(__unused id value){
            return @"-";
        }};
    }
}

@end
