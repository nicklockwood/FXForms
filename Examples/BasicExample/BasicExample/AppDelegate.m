//
//  AppDelegate.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "AppDelegate.h"
#import "RootForm.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //set up form
    FXFormViewController *formViewController = [[FXFormViewController alloc] init];
    formViewController.formController.form = [[RootForm alloc] init];
    
    //set up window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:formViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

//these are action methods for our forms
//the methods escalate through the responder chain until
//they reach the AppDelegate - normally we'd have put these
//on a view controller instead though

- (void)submitLoginForm:(UITableViewCell<FXFormFieldCell> *)cell
{
    //we can lookup the form from the cell if we want, like this:
    LoginForm *form = cell.field.form;
    
    //now we can display a form value in our alert
    [[[UIAlertView alloc] initWithTitle:@"Login Form Submitted"
                                message:[NSString stringWithFormat:@"User: %@", form.email]
                               delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

- (void)submitRegistrationForm
{
    [[[UIAlertView alloc] initWithTitle:@"Login Form Submitted" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end
