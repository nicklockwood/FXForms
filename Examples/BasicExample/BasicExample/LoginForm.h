//
//  LoginForm.h
//  BasicExample
//
//  Created by Nick Lockwood on 05/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXForms.h"


@interface LoginForm : NSObject <FXForm>

@property (nonatomic, copy) NSDictionary *login;
@property (nonatomic, copy) NSDictionary *registration;

@end
