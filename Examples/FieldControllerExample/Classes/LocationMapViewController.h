//
//  LocationMapViewController.h
//  BasicExample
//
//  Created by Nick Lockwood on 24/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FXForms.h"

@interface LocationMapViewController : UIViewController <FXFormFieldViewController>

@property (nonatomic, strong) FXFormField *field;

@end
