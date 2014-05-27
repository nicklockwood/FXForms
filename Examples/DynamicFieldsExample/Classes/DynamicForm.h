//
//  DynamicForm.h
//  DynamicFieldsExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXForms.h"


typedef NS_ENUM(NSInteger, Gender)
{
    GenderMale = 0,
    GenderFemale,
    GenderOther
};


typedef NS_OPTIONS(NSInteger, Interests)
{
    InterestComputers = 1 << 0,
    InterestSocializing = 1 << 1,
    InterestSports = 1 << 2
};


@interface DynamicForm : NSObject <FXForm>

//this dictionary stores the values that the user sets on the form
//the property can be called whateevr you want, and won't appear as
//a field in the form - it doesn't even have to be a property; you
//could use an ivar instead - and it doesn't have to be public; you
//can get the values directly from the form itself using -valueForKey:

@property (nonatomic, strong) NSMutableDictionary *valuesByKey;

@end
