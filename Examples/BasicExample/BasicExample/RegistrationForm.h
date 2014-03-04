//
//  RegistrationForm.h
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXForms.h"


@interface RegistrationForm : NSObject <FXForm>

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *repeatPassword;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *gender;
@property (nonatomic, assign) NSUInteger age;

@end
