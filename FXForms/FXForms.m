//
//  FXForms.m
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

#import "FXForms.h"
#import <objc/runtime.h>


#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma GCC diagnostic ignored "-Wreceiver-is-weak"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wgnu"


static const CGFloat FXFormFieldLabelSpacing = 5;
static const CGFloat FXFormFieldMinLabelWidth = 97;
static const CGFloat FXFormFieldMaxLabelWidth = 240;
static const CGFloat FXFormFieldMinFontSize = 12;
static const CGFloat FXFormFieldPaddingLeft = 10;
static const CGFloat FXFormFieldPaddingRight = 10;


static UIView *FXFormsFirstResponder(UIView *view)
{
    if ([view isFirstResponder])
    {
        return view;
    }
    for (UIView *subview in view.subviews)
    {
        UIView *responder = FXFormsFirstResponder(subview);
        if (responder)
        {
            return responder;
        }
    }
    return nil;
}


#pragma mark -
#pragma mark Models


static inline CGFloat FXFormLabelMinFontSize(UILabel *label)
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    
    if (![label respondsToSelector:@selector(setMinimumScaleFactor:)])
    {
        return label.minimumFontSize;
    }
    
#endif
    
    return label.font.pointSize * label.minimumScaleFactor;
}

static inline void FXFormLabelSetMinFontSize(UILabel *label, CGFloat fontSize)
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    
    if (![label respondsToSelector:@selector(setMinimumScaleFactor:)])
    {
        label.minimumFontSize = fontSize;
    }
    else
        
#endif
        
    {
        label.minimumScaleFactor = fontSize / label.font.pointSize;
    }
}

static inline NSArray *FXFormProperties(id<FXForm> form)
{
    if (!form) return nil;
    
    static void *FXFormPropertiesKey = &FXFormPropertiesKey;
    NSMutableArray *properties = objc_getAssociatedObject(form, FXFormPropertiesKey);
    if (!properties)
    {
        properties = [NSMutableArray array];
        Class subclass = [form class];
        while (subclass != [NSObject class])
        {
            unsigned int propertyCount;
            objc_property_t *propertyList = class_copyPropertyList(subclass, &propertyCount);
            for (unsigned int i = 0; i < propertyCount; i++)
            {
                //get property name
                objc_property_t property = propertyList[i];
                const char *propertyName = property_getName(property);
                NSString *key = @(propertyName);
                
                //get property type
                Class valueClass = nil;
                NSString *valueType = nil;
                char *typeEncoding = property_copyAttributeValue(property, "T");
                switch (typeEncoding[0])
                {
                    case '@':
                    {
                        if (strlen(typeEncoding) >= 3)
                        {
                            char *className = strndup(typeEncoding + 2, strlen(typeEncoding) - 3);
                            __autoreleasing NSString *name = @(className);
                            NSRange range = [name rangeOfString:@"<"];
                            if (range.location != NSNotFound)
                            {
                                name = [name substringToIndex:range.location];
                            }
                            valueClass = NSClassFromString(name) ?: [NSObject class];
                            free(className);
                            
                            if ([valueClass isSubclassOfClass:[NSString class]])
                            {
                                NSString *lowercaseKey = [key lowercaseString];
                                if ([lowercaseKey hasSuffix:@"password"])
                                {
                                    valueType = FXFormFieldTypePassword;
                                }
                                else if ([lowercaseKey hasSuffix:@"email"])
                                {
                                    valueType = FXFormFieldTypeEmail;
                                }
                                else if ([lowercaseKey hasSuffix:@"url"] || [lowercaseKey hasSuffix:@"link"])
                                {
                                    valueType = FXFormFieldTypeURL;
                                }
                                else
                                {
                                    valueType = FXFormFieldTypeText;
                                }
                            }
                            else if ([valueClass isSubclassOfClass:[NSNumber class]])
                            {
                                valueType = FXFormFieldTypeNumber;
                            }
                            else if ([valueClass isSubclassOfClass:[NSDate class]])
                            {
                                valueType = FXFormFieldTypeDate;
                            }
                            else
                            {
                                valueType = FXFormFieldTypeDefault;
                            }
                        }
                        break;
                    }
                    case 'c':
                    case 'B':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeBoolean;
                        break;
                    }
                    case 'i':
                    case 's':
                    case 'l':
                    case 'q':
                    case 'C':
                    case 'I':
                    case 'S':
                    case 'L':
                    case 'Q':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeInteger;
                        break;
                    }
                    case 'f':
                    case 'd':
                    {
                        valueClass = [NSNumber class];
                        valueType = FXFormFieldTypeNumber;
                        break;
                    }
                    case '{': //struct
                    case '(': //union
                    {
                        valueClass = [NSValue class];
                        valueType = FXFormFieldTypeLabel;
                        break;
                    }
                    case ':': //selector
                    case '#': //class
                    default:
                    {
                        valueClass = nil;
                        valueType = nil;
                    }
                }
                free(typeEncoding);
 
                //add to properties
                if (valueClass && valueType)
                {
                    [properties addObject:@{FXFormFieldKey: key, FXFormFieldClass: valueClass, FXFormFieldType: valueType}];
                }
            }
            free(propertyList);
            subclass = [subclass superclass];
        }
        objc_setAssociatedObject(form, FXFormPropertiesKey, properties, OBJC_ASSOCIATION_RETAIN);
    }
    return properties;
}


@interface FXFormField ()

@property (nonatomic, strong) Class valueClass;
@property (nonatomic, strong) Class cell;
@property (nonatomic, readwrite) NSString *key;
@property (nonatomic, readwrite) NSArray *options;
@property (nonatomic, copy) NSString *header;
@property (nonatomic, copy) NSString *footer;
@property (nonatomic, assign) BOOL isInline;

@property (nonatomic, strong) NSMutableDictionary *cellConfig;

+ (NSArray *)fieldsWithForm:(id<FXForm>)form;
- (instancetype)initWithForm:(id<FXForm>)form attributes:(NSDictionary *)attributes;

@end


@implementation FXFormField

+ (NSArray *)fieldsWithForm:(id<FXForm>)form
{
    //get fields
    NSMutableArray *fields = [[form fields] mutableCopy];
    if (!fields)
    {
        //use default fields
        fields = [NSMutableArray arrayWithArray:FXFormProperties(form)];
    }
    
    //add extra fields
    [fields addObjectsFromArray:[form extraFields] ?: @[]];
    
    //process fields
    NSMutableDictionary *fieldDictionariesByKey = [NSMutableDictionary dictionary];
    for (NSDictionary *dict in FXFormProperties(form))
    {
        fieldDictionariesByKey[dict[FXFormFieldKey]] = dict;
    }
    
    for (NSInteger i = [fields count] - 1; i >= 0; i--)
    {
        NSMutableDictionary *dictionary = nil;
        id dictionaryOrKey = fields[i];
        if ([dictionaryOrKey isKindOfClass:[NSString class]])
        {
            dictionaryOrKey = @{FXFormFieldKey: dictionaryOrKey};
        }
        if ([dictionaryOrKey isKindOfClass:[NSDictionary class]])
        {
            dictionary = [NSMutableDictionary dictionary];
            NSString *key = dictionaryOrKey[FXFormFieldKey];
            [dictionary addEntriesFromDictionary:fieldDictionariesByKey[key]];
            NSString *selector = [key stringByAppendingString:@"Field"];
            if ([form respondsToSelector:NSSelectorFromString(selector)])
            {
                [dictionary addEntriesFromDictionary:[(NSObject *)form valueForKey:selector]];
            }
            [dictionary addEntriesFromDictionary:dictionaryOrKey];
            if ([dictionary[FXFormFieldClass] isKindOfClass:[NSString class]])
            {
                dictionary[FXFormFieldClass] = NSClassFromString(dictionary[FXFormFieldClass]);
            }
            if ([dictionary[FXFormFieldCell] isKindOfClass:[NSString class]])
            {
                dictionary[FXFormFieldCell] = NSClassFromString(dictionary[FXFormFieldCell]);
            }
            if ([(NSArray *)dictionary[FXFormFieldOptions] count])
            {
                dictionary[FXFormFieldType] = FXFormFieldTypeDefault;
            }
            if (!dictionary[FXFormFieldTitle])
            {
                BOOL wasCapital = YES;
                NSString *keyOrAction = dictionary[FXFormFieldKey] ?: dictionary[FXFormFieldAction];
                NSMutableString *output = [NSMutableString string];
                [output appendString:[[keyOrAction substringToIndex:1] uppercaseString]];
                for (NSUInteger j = 1; j < [keyOrAction length]; j++)
                {
                    unichar character = [keyOrAction characterAtIndex:j];
                    BOOL isCapital = ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character]);
                    if (isCapital && !wasCapital) [output appendString:@" "];
                    wasCapital = isCapital;
                    if (character != ':') [output appendFormat:@"%C", character];
                }
                dictionary[FXFormFieldTitle] = NSLocalizedString(output, nil);
            }
        }
        else
        {
            [NSException raise:@"FXFormsException" format:@"Unsupported field type: %@", [dictionaryOrKey class]];
        }
        fields[i] = [[self alloc] initWithForm:form attributes:dictionary];
    }
    
    return fields;
}

- (instancetype)init
{
    //this class's contructor is private
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithForm:(id<FXForm>)form attributes:(NSDictionary *)attributes
{
    if ((self = [super init]))
    {
        _form = form;
        _cellConfig = [NSMutableDictionary dictionary];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
            [self setValue:value forKey:key];
        }];
    }
    return self;
}

- (BOOL)isIndexedType
{
    if (![self.options count])
    {
        return NO;
    }
    if ([self.type isEqualToString:FXFormFieldTypeInteger] ||
        [self.type isEqualToString:FXFormFieldTypeNumber] ||
        [self.valueClass isSubclassOfClass:[NSNumber class]])
    {
        return ![[self.options firstObject] isKindOfClass:[NSNumber class]];
    }
    return NO;
}

- (NSString *)fieldDescription
{
    if ([self isIndexedType])
    {
        NSUInteger index = [self.value integerValue];
        if (index != NSNotFound && index < [self.options count])
        {
            return [self.options[index] fieldDescription];
        }
        return nil;
    }
    return [self.value fieldDescription];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return _cellConfig[key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    _cellConfig[key] = value;
}

- (id)value
{
    if (self.key)
    {
        id value = [(NSObject *)self.form valueForKey:self.key];
        if (!value && ([self.valueClass conformsToProtocol:@protocol(FXForm)] ||
                       [self.valueClass isSubclassOfClass:[UIViewController class]]))
        {
            value = [[self.valueClass alloc] init];
            [(NSObject *)self.form setValue:value forKey:self.key];
        }
        return value;
    }
    return nil;
}

- (void)setValue:(id)value
{
    if (self.key && [self.form respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [[self.key substringToIndex:1] uppercaseString], [self.key substringFromIndex:1]])])
    {
        [(NSObject *)self.form setValue:value forKey:self.key];
    }
}

- (void)setAction:(NSString *)action
{
    _action = NSSelectorFromString(action);
}

- (void)setClass:(Class)valueClass
{
    _valueClass = valueClass;
}

- (void)setInline:(BOOL)isInline
{
    _isInline = isInline;
}

- (void)setOptions:(NSArray *)options
{
    _options = [options copy];
}

- (void)performActionWithResponder:(UIResponder *)responder sender:(id)sender
{
    if (self.action)
    {
        while (responder)
        {
            if ([responder respondsToSelector:self.action])
            {
                
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
                
                [responder performSelector:self.action withObject:sender];
                
#pragma GCC diagnostic pop
                
                return;
            }
            responder = [responder nextResponder];
        }
        
        [NSException raise:@"FXFormsException" format:@"No object in the responder chain responds to the selector %@", NSStringFromSelector(self.action)];
    }
}


@end


@interface FXOptionsForm : NSObject <FXForm>

@property (nonatomic, strong) FXFormField *field;
@property (nonatomic, strong) NSArray *fields;

@end


@implementation FXOptionsForm

- (instancetype)initWithField:(FXFormField *)field
{
    if ((self = [super init]))
    {
        _field = field;
        NSMutableArray *fields = [NSMutableArray array];
        NSInteger index = 0;
        for (id option in field.options)
        {
            [fields addObject:@{FXFormFieldKey: [@(index) description],
                                FXFormFieldTitle: [option fieldDescription],
                                FXFormFieldType: FXFormFieldTypeOption}];
            index ++;
        }
        _fields = fields;
    }
    return self;
}

- (id)valueForKey:(NSString *)key
{
    NSInteger index = NSNotFound;
    if ([self.field isIndexedType])
    {
        index = [self.field.value integerValue];
    }
    else
    {
        index = [self.field.options indexOfObject:self.field.value];
    }
    return @([key integerValue] == index);
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    value = self.field.options[[key integerValue]];
    if ([self.field isIndexedType])
    {
        self.field.value = @([self.field.options indexOfObject:value]);
    }
    else
    {
        self.field.value = value;
    }
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([NSStringFromSelector(selector) hasPrefix:@"set"])
    {
        return YES;
    }
    return [super respondsToSelector:selector];
}

@end


@interface FXFormSection : NSObject

+ (NSArray *)sectionsWithForm:(id<FXForm>)form;

@property (nonatomic, strong) id<FXForm> form;
@property (nonatomic, strong) NSString *header;
@property (nonatomic, strong) NSString *footer;
@property (nonatomic, strong) NSMutableArray *fields;

@end


@implementation FXFormSection

+ (NSArray *)sectionsWithForm:(id<FXForm>)form
{
    NSMutableArray *sections = [NSMutableArray array];
    FXFormSection *section = nil;
    for (FXFormField *field in [FXFormField fieldsWithForm:form])
    {
        if ([field.options count] && field.isInline)
        {
            id<FXForm> subform = [[FXOptionsForm alloc] initWithField:field];
            NSArray *subsections = [FXFormSection sectionsWithForm:subform];
            if (![[subsections firstObject] header]) [[subsections firstObject] setHeader:field.header ?: field.title];
            [sections addObjectsFromArray:subsections];
            section = nil;
        }
        else if ([field.valueClass conformsToProtocol:@protocol(FXForm)] && field.isInline)
        {
            id<FXForm> subform = field.value;
            NSArray *subsections = [FXFormSection sectionsWithForm:subform];
            if (![[subsections firstObject] header]) [[subsections firstObject] setHeader:field.header ?: field.title];
            [sections addObjectsFromArray:subsections];
            section = nil;
        }
        else
        {
            if (!section || field.header)
            {
                section = [[FXFormSection alloc] init];
                section.form = form;
                section.header = field.header;
                [sections addObject:section];
            }
            [section.fields addObject:field];
            if (field.footer)
            {
                section.footer = field.footer;
                section = nil;
            }
        }
    }
    return sections;
}

- (NSMutableArray *)fields
{
    if (!_fields)
    {
        _fields = [NSMutableArray array];
    }
    return _fields;
}

@end


@implementation NSObject (FXForms)

- (NSString *)fieldDescription
{
    for (Class fieldClass in @[[NSString class], [NSNumber class], [NSDate class]])
    {
        if ([self isKindOfClass:fieldClass])
        {
            return [self description];
        }
    }
    return nil;
}

- (NSArray *)fields
{
    return nil;
}

- (NSArray *)extraFields
{
    return nil;
}

@end


#pragma mark -
#pragma mark Controllers


@interface FXFormController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong) NSMutableDictionary *cellClassesForFieldTypes;

@end


@implementation FXFormController

- (instancetype)init
{
    if ((self = [super init]))
    {
        _cellClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormBaseCell class],
                                       FXFormFieldTypeText: [FXFormTextFieldCell class],
                                       FXFormFieldTypeURL: [FXFormTextFieldCell class],
                                       FXFormFieldTypeEmail: [FXFormTextFieldCell class],
                                       FXFormFieldTypePassword: [FXFormTextFieldCell class],
                                       FXFormFieldTypeNumber: [FXFormTextFieldCell class],
                                       FXFormFieldTypeInteger: [FXFormTextFieldCell class],
                                       FXFormFieldTypeBoolean: [FXFormSwitchCell class],
                                       FXFormFieldTypeDate: [FXFormDatePickerCell class],
                                       FXFormFieldTypeTime: [FXFormDatePickerCell class],
                                       FXFormFieldTypeDateTime: [FXFormDatePickerCell class]} mutableCopy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (Class)cellClassForFieldType:(NSString *)fieldType
{
    return self.cellClassesForFieldTypes[fieldType] ?: self.cellClassesForFieldTypes[FXFormFieldTypeDefault];
}

- (void)registerDefaultFieldCellClass:(Class)cellClass
{
    NSParameterAssert([cellClass conformsToProtocol:@protocol(FXFormFieldCell)]);
    [self.cellClassesForFieldTypes setDictionary:@{FXFormFieldTypeDefault: cellClass}];
}

- (void)registerCellClass:(Class)cellClass forFieldType:(NSString *)fieldType
{
    NSParameterAssert([cellClass conformsToProtocol:@protocol(FXFormFieldCell)]);
    self.cellClassesForFieldTypes[fieldType] = cellClass;
}

- (void)setDelegate:(id<FXFormControllerDelegate>)delegate
{
    _delegate = delegate;
    
    //force table to update respondsToSelector: cache
    self.tableView.delegate = nil;
    self.tableView.delegate = self;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return [super respondsToSelector:selector] || [self.delegate respondsToSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.delegate];
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView reloadData];
}

- (UIViewController *)tableViewController
{
    id responder = self.tableView;
    while (responder)
    {
        if ([responder isKindOfClass:[UIViewController class]])
        {
            return responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (void)setForm:(id<FXForm>)form
{
    _form = form;
    self.sections = [FXFormSection sectionsWithForm:form];
}

- (NSUInteger)numberOfSections
{
    return [self.sections count];
}

- (FXFormSection *)sectionAtIndex:(NSUInteger)index
{
    return self.sections[index];
}

- (NSUInteger)numberOfFieldsInSection:(NSUInteger)index
{
    return [[self sectionAtIndex:index].fields count];
}

- (FXFormField *)fieldForIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionAtIndex:indexPath.section].fields[indexPath.row];
}

- (void)enumerateFieldsWithBlock:(void (^)(FXFormField *field, NSIndexPath *indexPath))block
{
    NSUInteger sectionIndex = 0;
    for (FXFormSection *section in self.sections)
    {
        NSUInteger fieldIndex = 0;
        for (FXFormField *field in section.fields)
        {
            block(field, [NSIndexPath indexPathForRow:fieldIndex inSection:sectionIndex]);
            fieldIndex ++;
        }
        sectionIndex ++;
    }
}

#pragma mark -
#pragma mark Datasource methods

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView
{
    return [self numberOfSections];
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)index
{
    return [self sectionAtIndex:index].header;
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForFooterInSection:(NSInteger)index
{
    return [self sectionAtIndex:index].footer;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)index
{
    return [self numberOfFieldsInSection:index];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];
    Class cellClass = field.cell ?: [self cellClassForFieldType:field.type];
    if ([cellClass respondsToSelector:@selector(heightForField:)])
    {
        return [cellClass heightForField:field];
    }
    return self.tableView.rowHeight;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];

    //don't recycle cells - it would make things complicated
    Class cellClass = field.cell ?: [self cellClassForFieldType:field.type];
    NSString *nibName = NSStringFromClass(cellClass);
    if ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"])
    {
        return [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] firstObject];
    }
    else
    {
        return [[cellClass alloc] init];
    }
}

#pragma mark -
#pragma mark Delegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];

    //set form field
    ((id<FXFormFieldCell>)cell).field = field;
    
    //configure cell
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [cell setValue:value forKeyPath:keyPath];
    }];
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //forward to cell
    UITableViewCell<FXFormFieldCell> *cell = (UITableViewCell<FXFormFieldCell> *)[tableView cellForRowAtIndexPath:indexPath];
    if ([cell respondsToSelector:@selector(didSelectWithTableView:controller:)])
    {
        [cell didSelectWithTableView:tableView controller:[self tableViewController]];
    }
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //dismiss keyboard
    [FXFormsFirstResponder(self.tableView) resignFirstResponder];
    
    //forward to delegate
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

#pragma mark -
#pragma mark Keyboard events

- (UITableViewCell *)cellContainingView:(UIView *)view
{
    if (view == nil || [view isKindOfClass:[UITableViewCell class]])
    {
        return (UITableViewCell *)view;
    }
    return [self cellContainingView:view.superview];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    UITableViewCell *cell = [self cellContainingView:FXFormsFirstResponder(self.tableView)];
    if (cell)
    {
        NSDictionary *keyboardInfo = [note userInfo];
        CGRect keyboardFrame = [keyboardInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        keyboardFrame = [self.tableView.window convertRect:keyboardFrame toView:self.tableView.superview];
        CGFloat inset = self.tableView.frame.origin.y + self.tableView.frame.size.height - keyboardFrame.origin.y;
        
        UIEdgeInsets tableContentInset = self.tableView.contentInset;
        tableContentInset.bottom = inset;
        
        UIEdgeInsets tableScrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
        tableScrollIndicatorInsets.bottom = inset;
        
        //animate insets
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:(UIViewAnimationCurve)keyboardInfo[UIKeyboardAnimationCurveUserInfoKey]];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        self.tableView.contentInset = tableContentInset;
        self.tableView.scrollIndicatorInsets = tableScrollIndicatorInsets;
        NSIndexPath *selectedRow = [self.tableView indexPathForCell:cell];
        [self.tableView scrollToRowAtIndexPath:selectedRow atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification *)note
{
    UITableViewCell *cell = [self cellContainingView:FXFormsFirstResponder(self.tableView)];
    if (cell)
    {
        NSDictionary *keyboardInfo = [note userInfo];
        
        UIEdgeInsets tableContentInset = self.tableView.contentInset;
        tableContentInset.bottom = 0;
        
        UIEdgeInsets tableScrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
        tableScrollIndicatorInsets.bottom = 0;
        
        //restore insets
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:(UIViewAnimationCurve)keyboardInfo[UIKeyboardAnimationCurveUserInfoKey]];
        [UIView setAnimationDuration:[keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        self.tableView.contentInset = tableContentInset;
        self.tableView.scrollIndicatorInsets = tableScrollIndicatorInsets;
        [UIView commitAnimations];
    }
}

@end


@interface FXFormViewController ()

@property (nonatomic, strong) FXFormController *formController;

@end


@implementation FXFormViewController

- (FXFormController *)formController
{
    if (!_formController)
    {
        _formController = [[FXFormController alloc] init];
        _formController.delegate = self;
    }
    return _formController;
}

- (void)viewDidLoad
{
    [super loadView];
    
    if (!self.tableView)
    {
        self.tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame
                                                      style:UITableViewStyleGrouped];
    }
    if (!self.tableView.superview)
    {
        self.view = self.tableView;
    }
}

- (void)setTableView:(UITableView *)tableView
{
    self.formController.tableView = tableView;
    if (![self isViewLoaded])
    {
        self.view = self.tableView;
    }
}

- (UITableView *)tableView
{
    return self.formController.tableView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
    if (selected)
    {
        [self.tableView reloadData];
        [self.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

@end


#pragma mark -
#pragma mark Views


@interface FXFormBaseCell ()

@property (nonatomic, strong) UITextField *textField;

@end


@implementation FXFormBaseCell

- (id)init
{
    return [self initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier ?: NSStringFromClass([self class])]))
    {
        self.textLabel.font = [UIFont boldSystemFontOfSize:17];
        FXFormLabelSetMinFontSize(self.textLabel, FXFormFieldMinFontSize);
        self.detailTextLabel.font = [UIFont systemFontOfSize:17];
        FXFormLabelSetMinFontSize(self.detailTextLabel, FXFormFieldMinFontSize);
        
        [self setUp];
    }
    return self;
}

- (void)setField:(FXFormField *)field
{
    _field = field;
    [self update];
    [self setNeedsLayout];
}

- (void)setUp
{
    //override
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
    {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else
    {
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    if ([self.field.valueClass conformsToProtocol:@protocol(FXForm)] ||
        [self.field.valueClass isSubclassOfClass:[UIViewController class]] ||
        [self.field.options count])
    {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        self.detailTextLabel.text = nil;
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
    }
    else if (self.field.action)
    {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (UITableView *)tableView
{
    UITableView *view = (UITableView *)[self superview];
    while (![view isKindOfClass:[UITableView class]])
    {
        view = (UITableView *)[view superview];
    }
    return view;
}

- (FXFormController *)formController
{
    id responder = [self nextResponder];
    while (responder)
    {
        if ([responder respondsToSelector:@selector(formController)])
        {
            return [responder formController];
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(UIViewController *)controller
{
    if (self.field.action)
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        [self.field performActionWithResponder:controller sender:self];
        [tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else if ([self.field.options count] || [self.field.valueClass conformsToProtocol:@protocol(FXForm)])
    {
        id<FXForm> form = self.field.value;
        if ([self.field.options count])
        {
            form = [[FXOptionsForm alloc] initWithField:self.field];
        }
        
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        FXFormViewController *subcontroller = [[FXFormViewController alloc] init];
        subcontroller.title = self.field.title;
        FXFormController *formController = [self formController];
        if (formController) subcontroller.formController.cellClassesForFieldTypes = [formController.cellClassesForFieldTypes mutableCopy];
        subcontroller.formController.form = form;
        [controller.navigationController pushViewController:subcontroller animated:YES];
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        self.field.value = @(![self.field.value boolValue]);
        self.accessoryType = [self.field.value boolValue]? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
        if ([self.field.type isEqualToString:FXFormFieldTypeOption])
        {
            NSIndexPath *indexPath = [tableView indexPathForCell:self];
            if (indexPath)
            {
                //reload entire section, in case fields are linked
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        else
        {
            //deselect the cell
            [tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
    else if ([self.field.valueClass isSubclassOfClass:[UIViewController class]])
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        UIViewController *subcontroller = self.field.value;
        if (!subcontroller.title) subcontroller.title = self.field.title;
        [controller.navigationController pushViewController:subcontroller animated:YES];
    }
}

@end


@interface FXFormTextFieldCell () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;

@end


@implementation FXFormTextFieldCell

- (void)setUp
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 21)];
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin |UIViewAutoresizingFlexibleLeftMargin;
    self.textField.font = [UIFont systemFontOfSize:self.textLabel.font.pointSize];
    self.textField.minimumFontSize = FXFormLabelMinFontSize(self.textLabel);
    self.textField.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textField.delegate = self;
    [self.contentView addSubview:self.textField];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textField action:NSSelectorFromString(@"becomeFirstResponder")]];
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    //TODO: is there a less hacky fix for this?
    static NSDictionary *specialCases = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        specialCases = @{@"textField.autocapitalizationType": ^(UITextField *f, NSInteger v){ f.autocapitalizationType = v; },
                         @"textField.autocorrectionType": ^(UITextField *f, NSInteger v){ f.autocorrectionType = v; },
                         @"textField.spellCheckingType": ^(UITextField *f, NSInteger v){ f.spellCheckingType = v; },
                         @"textField.keyboardType": ^(UITextField *f, NSInteger v){ f.keyboardType = v; },
                         @"textField.keyboardAppearance": ^(UITextField *f, NSInteger v){ f.keyboardAppearance = v; },
                         @"textField.returnKeyType": ^(UITextField *f, NSInteger v){ f.returnKeyType = v; },
                         @"textField.enablesReturnKeyAutomatically": ^(UITextField *f, NSInteger v){ f.enablesReturnKeyAutomatically = !!v; },
                         @"textField.secureTextEntry": ^(UITextField *f, NSInteger v){ f.secureTextEntry = !!v; }};
    });

    void (^block)(UITextField *f, NSInteger v) = specialCases[keyPath];
    if (block)
    {
        block(self.textField, [value integerValue]);
    }
    else
    {
        [super setValue:value forKeyPath:keyPath];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.size.width = MIN(MAX([self.textLabel sizeThatFits:CGSizeZero].width, FXFormFieldMinLabelWidth), FXFormFieldMaxLabelWidth);
    self.textLabel.frame = labelFrame;
    
	CGRect textFieldFrame = self.textField.frame;
    textFieldFrame.origin.x = self.textLabel.frame.origin.x + MAX(FXFormFieldMinLabelWidth, self.textLabel.frame.size.width) + FXFormFieldLabelSpacing;
    textFieldFrame.origin.y = (self.contentView.bounds.size.height - textFieldFrame.size.height) / 2;
	textFieldFrame.size.width = self.textField.superview.frame.size.width - textFieldFrame.origin.x - FXFormFieldPaddingRight;
	if (![self.textLabel.text length])
    {
		textFieldFrame.origin.x = FXFormFieldPaddingLeft;
		textFieldFrame.size.width = self.contentView.bounds.size.width - FXFormFieldPaddingLeft - FXFormFieldPaddingRight;
	}
    else if (self.textField.textAlignment == NSTextAlignmentRight)
    {
		textFieldFrame.origin.x = self.textLabel.frame.origin.x + labelFrame.size.width + FXFormFieldLabelSpacing;
		textFieldFrame.size.width = self.textField.superview.frame.size.width - textFieldFrame.origin.x - FXFormFieldPaddingRight;
	}
	self.textField.frame = textFieldFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.textField.text = [self.field fieldDescription];
    
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.textAlignment = NSTextAlignmentRight;
    self.textField.secureTextEntry = NO;
    
    if ([self.field.type isEqualToString:FXFormFieldTypeText])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.textField.keyboardType = UIKeyboardTypeAlphabet;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeNumber] || [self.field.type isEqualToString:FXFormFieldTypeInteger])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePassword])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeAlphabet;
        self.textField.secureTextEntry = YES;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeEmail])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeURL])
    {
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.keyboardType = UIKeyboardTypeURL;
    }
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField
{
    [self.textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField
{
    id value = self.textField.text;
    if ([self.field.type isEqualToString:FXFormFieldTypeNumber])
    {
        value = @([self.textField.text doubleValue]);
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeInteger])
    {
        value = @([self.textField.text longLongValue]);
    }
    else if ([self.field.valueClass isSubclassOfClass:[NSURL class]])
    {
        value = [self.field.valueClass URLWithString:self.textField.text];
    }
    
    //handle case where value is numeric but value class is string
    if (![value isKindOfClass:[NSString class]] && [self.field.valueClass isSubclassOfClass:[NSString class]])
    {
        value = [self.field.valueClass stringWithString:[value description]];
    }

    self.field.value = value;
    [self.field performActionWithResponder:self sender:self];
}

- (void)textFieldDidBeginEditing:(__unused UITextField *)textField
{
    [self.textField selectAll:nil];
}

@end


@implementation FXFormSwitchCell

- (void)setUp
{
    [super setUp];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryView = [[UISwitch alloc] init];
    [self.switchControl addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.switchControl.on = [self.field.value boolValue];
    [self.field performActionWithResponder:self sender:self];
}

- (UISwitch *)switchControl
{
    return (UISwitch *)self.accessoryView;
}

- (void)valueChanged
{
    self.field.value = @(self.switchControl.on);
    [self.field performActionWithResponder:self sender:self];
}

@end


@implementation FXFormStepperCell

- (void)setUp
{
    [super setUp];
    
    UIStepper *stepper = [[UIStepper alloc] init];
    stepper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    UIView *wrapper = [[UIView alloc] initWithFrame:stepper.frame];
    [wrapper addSubview:stepper];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
    {
        wrapper.frame = CGRectMake(0, 0, wrapper.frame.size.width + FXFormFieldPaddingRight, wrapper.frame.size.height);
    }
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryView = wrapper;
    [self.stepper addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription];
    self.stepper.value = [self.field.value doubleValue];
    [self setNeedsLayout];
}

- (UIStepper *)stepper
{
    return (UIStepper *)[self.accessoryView.subviews firstObject];
}

- (void)valueChanged
{
    self.field.value = @(self.stepper.value);
    self.detailTextLabel.text = [self.field fieldDescription];
    [self.field performActionWithResponder:self sender:self];
}

@end


@interface FXFormSliderCell ()

@property (nonatomic, strong) UISlider *slider;

@end


@implementation FXFormSliderCell

- (void)setUp
{
    [super setUp];
    
    self.slider = [[UISlider alloc] init];
    [self.slider addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect sliderFrame = self.slider.frame;
    sliderFrame.origin.x = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + FXFormFieldPaddingLeft;
    sliderFrame.origin.y = (self.contentView.frame.size.height - sliderFrame.size.height) / 2;
    sliderFrame.size.width = self.contentView.bounds.size.width - sliderFrame.origin.x - FXFormFieldPaddingRight;
    self.slider.frame = sliderFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.slider.value = [self.field.value doubleValue];
}

- (UIStepper *)stepper
{
    return (UIStepper *)[self.accessoryView.subviews firstObject];
}

- (void)valueChanged
{
    self.field.value = @(self.slider.value);
    [self.field performActionWithResponder:self sender:self];
}

@end


@interface FXFormDatePickerCell ()

@property (nonatomic, strong) UIDatePicker *datePicker;

@end


@implementation FXFormDatePickerCell

- (void)setUp
{
    [super setUp];
    
    self.datePicker = [[UIDatePicker alloc] init];
    [self.datePicker addTarget:self action:@selector(valueChanged) forControlEvents:UIControlEventValueChanged];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self formattedDate];
    
    if ([self.field.type isEqualToString:FXFormFieldTypeDate])
    {
        self.datePicker.datePickerMode = UIDatePickerModeDate;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeTime])
    {
        self.datePicker.datePickerMode = UIDatePickerModeTime;
    }
    else
    {
        self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    }
    
    [self setNeedsLayout];
}

- (NSString *)formattedDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if ([self.field.type isEqualToString:FXFormFieldTypeDate])
    {
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeTime])
    {
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
    }
    else
    {
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    }
    return [formatter stringFromDate:self.field.value];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputView
{
    return self.datePicker;
}

- (void)valueChanged
{
    self.field.value = self.datePicker.date;
    self.detailTextLabel.text = [self formattedDate];
    [self setNeedsLayout];
    
    [self.field performActionWithResponder:self sender:self];
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(__unused UIViewController *)controller
{
    [self becomeFirstResponder];
    [tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
}

@end
