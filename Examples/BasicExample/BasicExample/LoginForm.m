//
//  LoginForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 05/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LoginForm.h"

@implementation LoginForm

//because we want to rearrange how this form
//is displayed, we've implemented the fields array
//which lets us dictate exactly which fields appear
//and in what order they appear

- (NSArray *)fields
{
    return @[
             
             //we don't need to modify these fields at all, so we'll
             //just refer to them by name to use the default settings
             
             @"email",
             @"password",
             @"rememberMe",
             
             //this field doesn't correspond to any property of the form
             //it's just an action button. the action will be called on first
             //object in the responder chain that implements the submitForm
             //method, which in this case would be the AppDelegate
             
             @{FXFormFieldTitle: @"Submit", FXFormFieldHeader: @"", FXFormFieldAction: @"submitForm"},
             
             ];
}

@end
