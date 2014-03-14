//
//  FXForms.h
//
//  Version 1.0.2
//
//  Created by Nick Lockwood on 13/02/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/FXForms
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#import <UIKit/UIKit.h>


#ifndef FXForms

static NSString *const FXFormFieldKey = @"key";
static NSString *const FXFormFieldType = @"type";
static NSString *const FXFormFieldClass = @"class";
static NSString *const FXFormFieldCell = @"cell";
static NSString *const FXFormFieldTitle = @"title";
static NSString *const FXFormFieldAction = @"action";
static NSString *const FXFormFieldOptions = @"options";
static NSString *const FXFormFieldHeader = @"header";
static NSString *const FXFormFieldFooter = @"footer";
static NSString *const FXFormFieldInline = @"inline";

static NSString *const FXFormFieldTypeDefault = @"default";
static NSString *const FXFormFieldTypeLabel = @"label";
static NSString *const FXFormFieldTypeText = @"text";
static NSString *const FXFormFieldTypeURL = @"url";
static NSString *const FXFormFieldTypeEmail = @"email";
static NSString *const FXFormFieldTypePassword = @"password";
static NSString *const FXFormFieldTypeNumber = @"number";
static NSString *const FXFormFieldTypeInteger = @"integer";
static NSString *const FXFormFieldTypeBoolean = @"boolean";
static NSString *const FXFormFieldTypeOption = @"option";
static NSString *const FXFormFieldTypeDate = @"date";
static NSString *const FXFormFieldTypeTime = @"time";
static NSString *const FXFormFieldTypeDateTime = @"datetime";

#endif


#pragma mark -
#pragma mark Models


@interface NSObject (FXForms)

- (NSString *)fieldDescription;

@end


@protocol FXForm <NSObject>
@optional

- (NSArray *)fields;
- (NSArray *)extraFields;

@end


@interface FXFormField : NSObject

@property (nonatomic, readonly) id<FXForm> form;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray *options;
@property (nonatomic, readonly) SEL action;
@property (nonatomic, strong) id value;

- (void)performActionWithResponder:(UIResponder *)responder sender:(id)sender;

@end


#pragma mark -
#pragma mark Controllers


@protocol FXFormControllerDelegate <UITableViewDelegate>

@end


@interface FXFormController : NSObject

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<FXFormControllerDelegate> delegate;
@property (nonatomic, strong) id<FXForm> form;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfFieldsInSection:(NSUInteger)section;
- (FXFormField *)fieldForIndexPath:(NSIndexPath *)indexPath;
- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block;

- (Class)cellClassForFieldType:(NSString *)fieldType;
- (void)registerDefaultFieldCellClass:(Class)cellClass;
- (void)registerCellClass:(Class)cellClass forFieldType:(NSString *)fieldType;

@end


@interface FXFormViewController : UIViewController <FXFormControllerDelegate>

@property (nonatomic, readonly) FXFormController *formController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end


#pragma mark -
#pragma mark Views


@protocol FXFormFieldCell <NSObject>

@property (nonatomic, strong) FXFormField *field;

@optional

+ (CGFloat)heightForField:(FXFormField *)field;
- (void)didSelectWithTableView:(UITableView *)tableView controller:(UIViewController *)controller;

@end


@interface FXFormBaseCell : UITableViewCell <FXFormFieldCell>

@property (nonatomic, strong) FXFormField *field;

@end


@interface FXFormTextFieldCell : FXFormBaseCell

@property (nonatomic, readonly) UITextField *textField;

@end


@interface FXFormSwitchCell : FXFormBaseCell

@property (nonatomic, readonly) UISwitch *switchControl;

@end


@interface FXFormStepperCell : FXFormBaseCell

@property (nonatomic, readonly) UIStepper *stepper;

@end


@interface FXFormSliderCell : FXFormBaseCell

@property (nonatomic, readonly) UISlider *slider;

@end


@interface FXFormDatePickerCell : FXFormBaseCell

@property (nonatomic, readonly) UIDatePicker *datePicker;

@end


#pragma GCC diagnostic pop

