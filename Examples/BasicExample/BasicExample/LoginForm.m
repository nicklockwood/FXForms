//
//  LoginForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 05/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LoginForm.h"


@interface LoginForm ()

@end


@implementation LoginForm
{
    NSArray *_fields;
}

@synthesize fields = _fields;

- (id)init
{
    if ((self = [super init]))
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Form" ofType:@"plist"];
        _fields = [NSDictionary dictionaryWithContentsOfFile:path][@"fields"];
    }
    return self;
}

@end
