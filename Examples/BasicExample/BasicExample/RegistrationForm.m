//
//  RegistrationForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "RegistrationForm.h"

@implementation RegistrationForm

//because we want to rearrange how this form
//is displayed, we've implemented the fields array
//which lets us dictate exactly which fields appear
//and in what order they appear

- (NSArray *)fields
{
    return @[
             
             //we want to add a group header for the field set of fields
             //we do that by adding the header key to the first field in the group
             
             @{FXFormFieldKey: @"email", FXFormFieldHeader: @"Account"},
             
             //we don't need to modify these fields at all, so we'll
             //just refer to them by name to use the default settings
             
             @"password",
             @"repeatPassword",
             
             //we want to add another group header here
             
             @{FXFormFieldKey: @"name", FXFormFieldHeader: @"Details"},
             
             //this is a multiple choice field, so we'll need to provide some options
             //because this is an enum property, the indexes of the options should match enum values
             
             @{FXFormFieldKey: @"gender", FXFormFieldOptions: @[@"Male", @"Female", @"It's Complicated"]},
             
             //another regular field
             
             @"dateOfBirth",
             
             //we want to use a stepper control for this values, so let's specify that
             
             @{FXFormFieldKey: @"age", FXFormFieldType: FXFormFieldTypeStepper},
             
             //this field doesn't correspond to any property of the form
             //it's just an action button. the action will be called on first
             //object in the responder chain that implements the submitForm
             //method, which in this case would be the AppDelegate
             
             @{FXFormFieldTitle: @"Submit", FXFormFieldHeader: @"", FXFormFieldAction: @"submitRegistrationForm"},
             
             ];
}

@end
