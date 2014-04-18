//
//  AppDelegate.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "AppDelegate.h"
#import "FormViewController.h"


@implementation AppDelegate

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions
{
    //set up window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[FormViewController alloc] init]];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
