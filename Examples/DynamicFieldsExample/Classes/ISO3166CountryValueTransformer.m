//
//  ISO3166CountryValueTransformer.m
//  DynamicFieldsExample
//
//  Created by Bart Vandendriessche on 17/03/14.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "ISO3166CountryValueTransformer.h"

@implementation ISO3166CountryValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    return value? [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:value]: nil;
}

@end
