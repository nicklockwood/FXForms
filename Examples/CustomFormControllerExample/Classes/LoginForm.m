//
//  LoginForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 05/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LoginForm.h"

@implementation LoginForm

//let's make the email field's title red, just because we can

- (NSDictionary *)emailField
{
    return @{@"textLabel.color": [UIColor redColor]};
}

//we're happy with the layout and properties of our login form, but we
//want to add an additional button field at the end, so
//we've used the extraFields method

- (NSArray *)extraFields
{
    return @[
             
             //this field doesn't correspond to any property of the form
             //it's just an action button. the action will be called on first
             //object in the responder chain that implements the submitForm
             //method, which in this case would be the AppDelegate
             
             @{FXFormFieldTitle: @"Submit", FXFormFieldHeader: @"", FXFormFieldAction: @"submitLoginForm"},
             
             ];
}

@end
