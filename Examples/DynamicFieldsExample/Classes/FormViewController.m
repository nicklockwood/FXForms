//
//  RootFormViewController.m
//  DynamicFieldsExample
//
//  Created by Nick Lockwood on 25/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "FormViewController.h"
#import "DynamicForm.h"


@implementation FormViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        //set up form
        self.formController.form = [[DynamicForm alloc] init];
    }
    return self;
}

- (void)submitRegistrationForm:(UITableViewCell<FXFormFieldCell> *)cell
{
    //we can lookup the form from the cell if we want, like this:
    DynamicForm *form = cell.field.form;
    
    //we can then perform validation, etc
    if ([[form valueForKey:@"agreedToTerms"] boolValue])
    {
        [[[UIAlertView alloc] initWithTitle:@"Login Form Submitted" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"User Error" message:@"Please agree to the terms and conditions before proceeding" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Yes Sir!", nil] show];
    }
}

@end
