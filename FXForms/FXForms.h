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
#pragma GCC diagnostic ignored "-Wmissing-variable-declarations"


#import <UIKit/UIKit.h>


extern NSString *const FXFormFieldKey; //key
extern NSString *const FXFormFieldType; //type
extern NSString *const FXFormFieldClass; //class
extern NSString *const FXFormFieldCell; //cell
extern NSString *const FXFormFieldTitle; //title
extern NSString *const FXFormFieldPlaceholder; //placeholder
extern NSString *const FXFormFieldDefaultValue; //default
extern NSString *const FXFormFieldOptions; //options
extern NSString *const FXFormFieldTemplate; //template
extern NSString *const FXFormFieldValueTransformer; //valueTransformer
extern NSString *const FXFormFieldAction; //action
extern NSString *const FXFormFieldSegue; //segue
extern NSString *const FXFormFieldHeader; //header
extern NSString *const FXFormFieldFooter; //footer
extern NSString *const FXFormFieldInline; //inline
extern NSString *const FXFormFieldSortable; //sortable
extern NSString *const FXFormFieldViewController; //viewController

extern NSString *const FXFormFieldTypeDefault; //default
extern NSString *const FXFormFieldTypeLabel; //label
extern NSString *const FXFormFieldTypeText; //text
extern NSString *const FXFormFieldTypeLongText; //longtext
extern NSString *const FXFormFieldTypeURL; //url
extern NSString *const FXFormFieldTypeEmail; //email
extern NSString *const FXFormFieldTypePhone; //phone
extern NSString *const FXFormFieldTypePassword; //password
extern NSString *const FXFormFieldTypeNumber; //number
extern NSString *const FXFormFieldTypeInteger; //integer
extern NSString *const FXFormFieldTypeUnsigned; //unsigned
extern NSString *const FXFormFieldTypeFloat; //float
extern NSString *const FXFormFieldTypeBitfield; //bitfield
extern NSString *const FXFormFieldTypeBoolean; //boolean
extern NSString *const FXFormFieldTypeOption; //option
extern NSString *const FXFormFieldTypeDate; //date
extern NSString *const FXFormFieldTypeTime; //time
extern NSString *const FXFormFieldTypeDateTime; //datetime
extern NSString *const FXFormFieldTypeImage; //image


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

