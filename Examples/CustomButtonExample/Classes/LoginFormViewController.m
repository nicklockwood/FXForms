//
//  RootFormViewController.m
//  BasicExample
//
//  Created by Nick Lockwood on 25/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LoginFormViewController.h"
#import "LoginForm.h"


@implementation LoginFormViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set up form and form controller
    self.formController = [[FXFormController alloc] init];
    self.formController.tableView = self.tableView;
    self.formController.delegate = self;
    self.formController.form = [[LoginForm alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //reload the table
    [self.tableView reloadData];
}


//this is the action method for our submit button
//the methods escalate through the responder chain until
//they reach the AppDelegate

- (void)submitLoginForm
{
    //now we can display a form value in our alert
    [[[UIAlertView alloc] initWithTitle:@"Login Form Submitted" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end
