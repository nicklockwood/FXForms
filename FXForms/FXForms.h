//
//  FXForms.h
//
//  Version 1.2.1
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

NSString *const FXFormFieldKey = @"key";
NSString *const FXFormFieldType = @"type";
NSString *const FXFormFieldClass = @"class";
NSString *const FXFormFieldCell = @"cell";
NSString *const FXFormFieldTitle = @"title";
NSString *const FXFormFieldPlaceholder = @"placeholder";
NSString *const FXFormFieldDefaultValue = @"default";
NSString *const FXFormFieldOptions = @"options";
NSString *const FXFormFieldTemplate = @"template";
NSString *const FXFormFieldValueTransformer = @"valueTransformer";
NSString *const FXFormFieldAction = @"action";
NSString *const FXFormFieldSegue = @"segue";
NSString *const FXFormFieldHeader = @"header";
NSString *const FXFormFieldFooter = @"footer";
NSString *const FXFormFieldInline = @"inline";
NSString *const FXFormFieldSortable = @"sortable";
NSString *const FXFormFieldViewController = @"viewController";

NSString *const FXFormFieldTypeDefault = @"default";
NSString *const FXFormFieldTypeLabel = @"label";
NSString *const FXFormFieldTypeText = @"text";
NSString *const FXFormFieldTypeLongText = @"longtext";
NSString *const FXFormFieldTypeURL = @"url";
NSString *const FXFormFieldTypeEmail = @"email";
NSString *const FXFormFieldTypePhone = @"phone";
NSString *const FXFormFieldTypePassword = @"password";
NSString *const FXFormFieldTypeNumber = @"number";
NSString *const FXFormFieldTypeInteger = @"integer";
NSString *const FXFormFieldTypeUnsigned = @"unsigned";
NSString *const FXFormFieldTypeFloat = @"float";
NSString *const FXFormFieldTypeBitfield = @"bitfield";
NSString *const FXFormFieldTypeBoolean = @"boolean";
NSString *const FXFormFieldTypeOption = @"option";
NSString *const FXFormFieldTypeDate = @"date";
NSString *const FXFormFieldTypeTime = @"time";
NSString *const FXFormFieldTypeDateTime = @"datetime";
NSString *const FXFormFieldTypeImage = @"image";

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
- (NSArray *)excludedFields;

// informal protocol:

// - (NSDictionary *)<fieldKey>Field
// - (NSString *)<fieldKey>FieldDescription

@end


@interface FXFormField : NSObject

@property (nonatomic, readonly) id<FXForm> form;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) id placeholder;
@property (nonatomic, readonly) NSDictionary *fieldTemplate;
@property (nonatomic, readonly) BOOL isSortable;
@property (nonatomic, readonly) BOOL isInline;
@property (nonatomic, readonly) Class valueClass;
@property (nonatomic, readonly) Class viewController;
@property (nonatomic, readonly) void (^action)(id sender);
@property (nonatomic, readonly) id segue;
@property (nonatomic, strong) id value;

- (NSUInteger)optionCount;
- (id)optionAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfOption:(id)option;
- (NSString *)optionDescriptionAtIndex:(NSUInteger)index;
- (void)setOptionSelected:(BOOL)selected atIndex:(NSUInteger)index;
- (BOOL)isOptionSelectedAtIndex:(NSUInteger)index;

@end


#pragma mark -
#pragma mark Controllers


@protocol FXFormControllerDelegate <UITableViewDelegate>

@end


@interface FXFormController : NSObject

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FXFormController *parentFormController;
@property (nonatomic, weak) id<FXFormControllerDelegate> delegate;
@property (nonatomic, strong) id<FXForm> form;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfFieldsInSection:(NSUInteger)section;
- (FXFormField *)fieldForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForField:(FXFormField *)field;
- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block;

- (Class)cellClassForField:(FXFormField *)field;
- (void)registerDefaultFieldCellClass:(Class)cellClass;
- (void)registerCellClass:(Class)cellClass forFieldType:(NSString *)fieldType;
- (void)registerCellClass:(Class)cellClass forFieldClass:(Class)fieldClass;

- (Class)viewControllerClassForField:(FXFormField *)field;
- (void)registerDefaultViewControllerClass:(Class)controllerClass;
- (void)registerViewControllerClass:(Class)controllerClass forFieldType:(NSString *)fieldType;
- (void)registerViewControllerClass:(Class)controllerClass forFieldClass:(Class)fieldClass;


@end


@protocol FXFormFieldViewController <NSObject>

@property (nonatomic, strong) FXFormField *field;

@end


@interface FXFormViewController : UIViewController <FXFormFieldViewController, FXFormControllerDelegate>

@property (nonatomic, readonly) FXFormController *formController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end


#pragma mark -
#pragma mark Views


@protocol FXFormFieldCell <NSObject>

@property (nonatomic, strong) FXFormField *field;

@optional

+ (CGFloat)heightForField:(FXFormField *)field width:(CGFloat)width;
- (void)didSelectWithTableView:(UITableView *)tableView
                    controller:(UIViewController *)controller;
@end


@interface FXFormBaseCell : UITableViewCell <FXFormFieldCell>

- (void)setUp;
- (void)update;
- (void)didSelectWithTableView:(UITableView *)tableView
                    controller:(UIViewController *)controller;
@end


@interface FXFormDefaultCell : FXFormBaseCell

@end


@interface FXFormTextFieldCell : FXFormBaseCell

@property (nonatomic, readonly) UITextField *textField;

@end


@interface FXFormTextViewCell : FXFormBaseCell

@property (nonatomic, readonly) UITextView *textView;

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


@interface FXFormImagePickerCell : FXFormBaseCell

@property (nonatomic, readonly) UIImageView *imagePickerView;
@property (nonatomic, readonly) UIImagePickerController *imagePickerController;

@end


@interface FXFormOptionPickerCell : FXFormBaseCell

@property (nonatomic, readonly) UIPickerView *pickerView;

@end


@interface FXFormOptionSegmentsCell : FXFormBaseCell

@property (nonatomic, readonly) UISegmentedControl *segmentedControl;

@end


#pragma GCC diagnostic pop

