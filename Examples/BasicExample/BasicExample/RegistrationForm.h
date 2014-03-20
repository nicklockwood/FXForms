//
//  RegistrationForm.h
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TermsViewController.h"
#import "PrivacyPolicyViewController.h"
#import "FXForms.h"


typedef NS_OPTIONS(NSInteger, Gender)
{
    GenderMale = 0,
    GenderFemale,
    GenderOther
};


@interface RegistrationForm : NSObject <FXForm>

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *repeatPassword;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) Gender gender;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, strong) NSDate *dateOfBirth;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *about;

@property (nonatomic, strong) UIImage *profilePhoto;

@property (nonatomic, readonly) TermsViewController *termsAndConditions;
@property (nonatomic, readonly) PrivacyPolicyViewController *privacyPolicy;
@property (nonatomic, assign) BOOL agreedToTerms;

@end
