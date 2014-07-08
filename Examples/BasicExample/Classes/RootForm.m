//
//  RootForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "RootForm.h"


@implementation RootForm

//we want to display our login form inline instead
//of in a separate view controller, so by implementing
//the <propertyName>Field method, we can specify that

- (NSDictionary *)loginField
{
    return @{FXFormFieldInline: @YES};
}

//let's specify a header for our registration form field

- (NSDictionary *)registrationField
{
    return @{FXFormFieldHeader: @"Not Registered?"};
}

@end
