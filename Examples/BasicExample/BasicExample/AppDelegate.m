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

- (void)submitForm
{
    [[[UIAlertView alloc] initWithTitle:@"Form Submitted" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

@end
