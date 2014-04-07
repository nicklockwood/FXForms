//
//  RootFormViewController.h
//  BasicExample
//
//  Created by Nick Lockwood on 25/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "FXForms.h"

@interface LoginFormViewController : UIViewController <FXFormControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FXFormController *formController;

@end
