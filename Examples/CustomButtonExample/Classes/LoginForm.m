//
//  LoginForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 05/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LoginForm.h"
#import "CustomButtonCell.h"


@implementation LoginForm

- (NSArray *)extraFields
{
    return @[
             
             //we declare our custom submit buytton cell as normal, but note that
             //we have specified that we want to use our CustomButtonCell class
             //instead of the default FXFormBaseCell
             
             @{FXFormFieldCell: [CustomButtonCell class], FXFormFieldHeader: @"", FXFormFieldAction: @"submitLoginForm"},
             
             ];
}

@end
