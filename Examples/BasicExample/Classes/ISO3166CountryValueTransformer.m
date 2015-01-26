//
//  ISO3166CountryValueTransformer.m
//  BasicExample
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
    return YES;
}

- (id)transformedValue:(id)value
{
    return value? [[NSLocale localeWithLocaleIdentifier:@"en_US"] displayNameForKey:NSLocaleCountryCode value:value]: nil;
}

- (id)reverseTransformedValue:(id)value
{
  static NSMutableDictionary *reverseLookup;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    reverseLookup = [NSMutableDictionary dictionary];
    for (NSString *code in [NSLocale ISOCountryCodes])
    {
        NSString *countryName = [self transformedValue:code];
        if (countryName) reverseLookup[countryName] = code;
    }
  });
  
  return reverseLookup[value];
}

@end
