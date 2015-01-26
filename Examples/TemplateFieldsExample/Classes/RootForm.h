//
//  RootForm.h
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXForms.h"


@interface RootForm : NSObject <FXForm>

@property (nonatomic, strong) NSArray *array;
@property (nonatomic, strong) NSArray *sortableArray;
@property (nonatomic, strong) NSArray *arrayWithTemplate;
@property (nonatomic, strong) NSArray *sortableArrayWithTemplate;

@property (nonatomic, strong) NSArray *inlineArray;
@property (nonatomic, strong) NSArray *inlineSortableArray;
@property (nonatomic, strong) NSArray *inlineArrayWithTemplate;
@property (nonatomic, strong) NSArray *inlineSortableArrayWithTemplate;

@property (nonatomic, strong) NSArray *otherEmails;

@end
