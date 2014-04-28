//
//  FXForms.m
//
//  Version 1.1.6
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


static NSString *const FXFormsException = @"FXFormsException";


static const CGFloat FXFormFieldLabelSpacing = 5;
static const CGFloat FXFormFieldMinLabelWidth = 97;
static const CGFloat FXFormFieldMaxLabelWidth = 240;
static const CGFloat FXFormFieldMinFontSize = 12;
static const CGFloat FXFormFieldPaddingLeft = 10;
static const CGFloat FXFormFieldPaddingRight = 10;
static const CGFloat FXFormFieldPaddingTop = 12;
static const CGFloat FXFormFieldPaddingBottom = 12;


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
                            else if ([valueClass isSubclassOfClass:[UIImage class]])
                            {
                                valueType = FXFormFieldTypeImage;
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
                        valueType = FXFormFieldTypeFloat;
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

static BOOL *FXFormOverridesSelector(id<FXForm> form, SEL selector)
{
    Class formClass = [form class];
    while (formClass && formClass != [NSObject class])
    {
        unsigned int numberOfMethods;
        Method *methods = class_copyMethodList(formClass, &numberOfMethods);
        for (unsigned int i = 0; i < numberOfMethods; i++)
        {
            if (method_getName(methods[i]) == selector)
            {
                free(methods);
                return YES;
            }
        }
        if (methods) free(methods);
        formClass = [formClass superclass];
    }
    return NO;
}

static BOOL *FXFormCanGetValueForKey(id<FXForm> form, NSString *key)
{
    //has key?
    if (![key length])
    {
        return NO;
    }
    
    //does a property exist for it?
    if ([[FXFormProperties(form) valueForKey:FXFormFieldKey] containsObject:key])
    {
        return YES;
    }
    
    //is there a getter method for this key?
    if ([form respondsToSelector:NSSelectorFromString(key)])
    {
        return YES;
    }
    
    //does it override valurForKey?
    if (FXFormOverridesSelector(form, @selector(valueForKey:)))
    {
        return YES;
    }
    
    //does it override valueForUndefinedKey?
    if (FXFormOverridesSelector(form, @selector(valueForUndefinedKey:)))
    {
        return YES;
    }
    
    //it will probably crash
    return NO;
}

static BOOL *FXFormCanSetValueForKey(id<FXForm> form, NSString *key)
{
    //has key?
    if (![key length])
    {
        return NO;
    }
    
    //does a property exist for it?
    if ([[FXFormProperties(form) valueForKey:FXFormFieldKey] containsObject:key])
    {
        return YES;
    }
    
    //is there a setter method for this key?
    if ([form respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]])])
    {
        return YES;
    }
    
    //does it override setValueForKey?
    if (FXFormOverridesSelector(form, @selector(setValue:forKey:)))
    {
        return YES;
    }
    
    //does it override setValue:forUndefinedKey?
    if (FXFormOverridesSelector(form, @selector(setValue:forUndefinedKey:)))
    {
        return YES;
    }
    
    //it will probably crash
    return NO;
}

static BOOL *FXFormSetValueForKey(id<FXForm> form, id value, NSString *key)
{
    if (FXFormCanSetValueForKey(form, key))
    {
        if (!value)
        {
            for (NSDictionary *field in FXFormProperties(form))
            {
                if ([field[FXFormFieldKey] isEqualToString:key])
                {
                    if ([@[FXFormFieldTypeBoolean, FXFormFieldTypeInteger, FXFormFieldTypeFloat] containsObject:field[FXFormFieldType]])
                    {
                        //prevents NSInvalidArgumentException in setNilValueForKey: method
                        value = @0;
                    }
                    break;
                }
            }
        }
        [(NSObject *)form setValue:value forKey:key];
        return YES;
    }
    return NO;
}


@interface FXFormController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong) NSMutableDictionary *cellClassesForFieldTypes;
@property (nonatomic, strong) NSMutableDictionary *controllerClassesForFieldTypes;

- (void)performAction:(SEL)selector withSender:(id)sender;

@end


@interface FXFormField ()

@property (nonatomic, strong) Class valueClass;
@property (nonatomic, strong) Class cell;
@property (nonatomic, readwrite) NSString *key;
@property (nonatomic, readwrite) NSArray *options;
@property (nonatomic, readonly) id (^valueTransformer)(id input);
@property (nonatomic, copy) NSString *header;
@property (nonatomic, copy) NSString *footer;
@property (nonatomic, assign) BOOL isInline;

@property (nonatomic, weak) FXFormController *formController;
@property (nonatomic, strong) NSMutableDictionary *cellConfig;

+ (NSArray *)fieldsWithForm:(id<FXForm>)form controller:(FXFormController *)formController;
- (instancetype)initWithForm:(id<FXForm>)form controller:(FXFormController *)formController attributes:(NSDictionary *)attributes;

@end


@implementation FXFormField

+ (NSArray *)fieldsWithForm:(id<FXForm>)form controller:(FXFormController *)formController
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
            [dictionary addEntriesFromDictionary:dictionaryOrKey];
            NSString *selector = [key stringByAppendingString:@"Field"];
            if (selector && [form respondsToSelector:NSSelectorFromString(selector)])
            {
                [dictionary addEntriesFromDictionary:[(NSObject *)form valueForKey:selector]];
            }
            if ([dictionary[FXFormFieldClass] isKindOfClass:[NSString class]])
            {
                dictionary[FXFormFieldClass] = NSClassFromString(dictionary[FXFormFieldClass]);
            }
            if ([dictionary[FXFormFieldCell] isKindOfClass:[NSString class]])
            {
                dictionary[FXFormFieldCell] = NSClassFromString(dictionary[FXFormFieldCell]);
            }
            if ([dictionary[FXFormFieldViewController] isKindOfClass:[NSString class]])
            {
                dictionary[FXFormFieldViewController] = NSClassFromString(dictionary[FXFormFieldViewController]);
            }
            if (([(NSArray *)dictionary[FXFormFieldOptions] count] || dictionary[FXFormFieldViewController])
                && [dictionary[FXFormFieldType] isEqualToString:fieldDictionariesByKey[key][FXFormFieldType]]
                && ![dictionary[FXFormFieldInline] boolValue])
            {
                //TODO: is there a better way to force non-inline cells to use base cell?
                dictionary[FXFormFieldType] = FXFormFieldTypeDefault;
            }
            if (!dictionary[FXFormFieldTitle])
            {
                BOOL wasCapital = YES;
                NSString *keyOrAction = dictionary[FXFormFieldKey];
                if (!keyOrAction && [dictionary[FXFormFieldAction] isKindOfClass:[NSString class]])
                {
                    keyOrAction = dictionary[FXFormFieldAction];
                }
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
            [NSException raise:FXFormsException format:@"Unsupported field type: %@", [dictionaryOrKey class]];
        }
        fields[i] = [[self alloc] initWithForm:form controller:formController attributes:dictionary];
    }
    
    return fields;
}

- (instancetype)init
{
    //this class's contructor is private
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithForm:(id<FXForm>)form controller:(FXFormController *)formController attributes:(NSDictionary *)attributes
{
    if ((self = [super init]))
    {
        _form = form;
        _formController = formController;
        _cellConfig = [NSMutableDictionary dictionary];
        [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, __unused BOOL *stop) {
            [self setValue:value forKey:key];
        }];
    }
    return self;
}

- (BOOL)isIndexedType
{
    //return YES if value should be set as index of option, not value of option
    if ([self.valueClass isSubclassOfClass:[NSNumber class]] && ![self.type isEqualToString:FXFormFieldTypeBitfield])
    {
        return ![[self.options firstObject] isKindOfClass:[NSNumber class]];
    }
    return NO;
}

- (BOOL)isCollectionType
{
    for (Class valueClass in @[[NSArray class], [NSSet class], [NSOrderedSet class], [NSIndexSet class], [NSDictionary class]])
    {
        if ([self.valueClass isSubclassOfClass:valueClass]) return YES;
    }
    return NO;
}

- (BOOL)isSubform
{
    return (![self.type isEqualToString:FXFormFieldTypeLabel] &&
            ([self.valueClass conformsToProtocol:@protocol(FXForm)] ||
             [self.valueClass isSubclassOfClass:[UIViewController class]] ||
             [self.options count] || self.viewController));
}

- (NSString *)valueDescription:(id)value
{
    if (self.valueTransformer)
    {
        return [self.valueTransformer(value) fieldDescription];
    }
    
    if ([value isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        if ([self.type isEqualToString:FXFormFieldTypeDate])
        {
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterNoStyle;
        }
        else if ([self.type isEqualToString:FXFormFieldTypeTime])
        {
            formatter.dateStyle = NSDateFormatterNoStyle;
            formatter.timeStyle = NSDateFormatterMediumStyle;
        }
        else //datetime
        {
            formatter.dateStyle = NSDateFormatterShortStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
        }
        
        return [formatter stringFromDate:value];
    }
    
    return [value fieldDescription];
}

- (NSString *)optionDescriptionAtIndex:(NSUInteger)index
{
    if (index != NSNotFound && index < [self.options count])
    {
        return [self valueDescription:self.options[index]];
    }
    return nil;
}

- (NSString *)fieldDescription
{
    NSString *descriptionKey = [self.key stringByAppendingString:@"FieldDescription"];
    if (descriptionKey && [self.form respondsToSelector:NSSelectorFromString(descriptionKey)])
    {
        return [(NSObject *)self.form valueForKey:descriptionKey];
    }
    
    if (self.options)
    {
        if ([self isIndexedType])
        {
            NSUInteger index = self.value ? [self.value integerValue]: NSNotFound;
            return [self optionDescriptionAtIndex:index];
        }
        
        //TODO: should we pass the results of these transforms to the
        //valueTransformer afterwards? seems dangerous since
        //the type won't match that of the options, and people
        //probably won't be expecting it
        
        if ([self isCollectionType])
        {
            id value = self.value;
            if ([value isKindOfClass:[NSIndexSet class]])
            {
                NSMutableArray *options = [NSMutableArray array];
                [self.options enumerateObjectsUsingBlock:^(id option, NSUInteger i, __unused BOOL *stop) {
                    NSUInteger index = i;
                    if ([option isKindOfClass:[NSNumber class]])
                    {
                        index = [option integerValue];
                    }
                    if ([value containsIndex:index])
                    {
                        NSString *description = [self optionDescriptionAtIndex:i];
                        if ([description length]) [options addObject:description];
                    }
                }];
                
                return value = [options count]? options: nil;
            }
            
            return [value fieldDescription];
        }
        else if ([self.type isEqual:FXFormFieldTypeBitfield])
        {
            NSUInteger value = [self.value integerValue];
            NSMutableArray *options = [NSMutableArray array];
            [self.options enumerateObjectsUsingBlock:^(id option, NSUInteger i, __unused BOOL *stop) {
                NSUInteger bit = 1 << i;
                if ([option isKindOfClass:[NSNumber class]])
                {
                    bit = [option integerValue];
                }
                if (value & bit)
                {
                    NSString *description = [self optionDescriptionAtIndex:i];
                    if ([description length]) [options addObject:description];
                }
            }];
            
            return [options count]? [options fieldDescription]: nil;
        }
        else if (self.placeholder && ![self.options containsObject:self.value])
        {
            return [self.placeholder description];
        }
    }
    
    return [self valueDescription:self.value];
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
    if (FXFormCanGetValueForKey(self.form, self.key))
    {
        id value = [(NSObject *)self.form valueForKey:self.key];
        if (!value && (([self.valueClass conformsToProtocol:@protocol(FXForm)] &&
                        ![self.valueClass isSubclassOfClass:NSClassFromString(@"NSManagedObject")]) ||
                       [self.valueClass isSubclassOfClass:[UIViewController class]]))
        {
            value = [[self.valueClass alloc] init];
            FXFormSetValueForKey(self.form, value, self.key);
        }
        return value;
    }
    return nil;
}

- (void)setValue:(id)value
{
    FXFormSetValueForKey(self.form, value, self.key);
}

- (void)setValueTransformer:(id)valueTransformer
{
    if ([valueTransformer isKindOfClass:[NSString class]])
    {
        valueTransformer = NSClassFromString(valueTransformer);
    }
    if ([valueTransformer respondsToSelector:@selector(alloc)])
    {
        valueTransformer = [[valueTransformer alloc] init];
    }
    if ([valueTransformer isKindOfClass:[NSValueTransformer class]])
    {
        NSValueTransformer *transformer = valueTransformer;
        valueTransformer = ^(id input)
        {
            return [transformer transformedValue:input];
        };
    }
    
    _valueTransformer = [valueTransformer copy];
}

- (void)setAction:(id)action
{
    if ([action isKindOfClass:[NSString class]])
    {
        SEL selector = NSSelectorFromString(action);
        __weak FXFormField *weakSelf = self;
        action = ^(id sender)
        {
            [weakSelf.formController performAction:selector withSender:sender];
        };
    }
    
    _action = [action copy];
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

#pragma mark -
#pragma mark Option cell Helpers

- (NSUInteger)indexOfOption:(id)option
{
    NSUInteger index = [self.options indexOfObject:option];
    if (index == NSNotFound)
    {
        return self.placeholder? 0: NSNotFound;
    }
    else
    {
        return index + (self.placeholder? 1: 0);
    }
}

- (id)optionAtIndex:(NSUInteger)index
{
    if (index == 0)
    {
        return self.placeholder ?: self.options[0];
    }
    else
    {
        return self.options[index - (self.placeholder? 1: 0)];
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
        id action = ^(__unused id sender)
        {
            if (field.action)
            {
                //this nasty hack is neccesary to pass the expected cell as the sender
                FXFormController *formController = field.formController;
                [formController enumerateFieldsWithBlock:^(FXFormField *f, NSIndexPath *indexPath) {
                    if ([f.key isEqual:field.key])
                    {
                        field.action([formController.tableView cellForRowAtIndexPath:indexPath]);
                    }
                }];
            }
        };
        NSMutableArray *fields = [NSMutableArray array];
        if (field.placeholder)
        {
            [fields addObject:@{FXFormFieldKey: [@(NSNotFound) description],
                                FXFormFieldTitle: [field.placeholder fieldDescription],
                                FXFormFieldType: FXFormFieldTypeOption,
                                FXFormFieldAction: action}];
        }
        for (NSUInteger i = 0; i < [field.options count]; i++)
        {
            [fields addObject:@{FXFormFieldKey: [@(i) description],
                                FXFormFieldTitle: [field optionDescriptionAtIndex:i],
                                FXFormFieldType: FXFormFieldTypeOption,
                                FXFormFieldAction: action}];
        }
        _fields = fields;
    }
    return self;
}

- (id)valueForKey:(NSString *)key
{
    NSInteger index = [key integerValue];
    id value = (index == NSNotFound)? nil: self.field.options[index];
    if ([self.field isCollectionType])
    {
        if (index == NSNotFound)
        {
            return @(![(NSArray *)self.field.value count]);
        }
        else if ([self.field.valueClass isSubclassOfClass:[NSIndexSet class]])
        {
            if ([value isKindOfClass:[NSNumber class]])
            {
                index = [value integerValue];
            }
            return @([self.field.value containsIndex:index]);
        }
        else
        {
            return @([self.field.value containsObject:value]);
        }
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBitfield])
    {
        if (index == NSNotFound)
        {
            return @(![self.field.value integerValue]);
        }
        else if ([value isKindOfClass:[NSNumber class]])
        {
            index = [value integerValue];
        }
        else
        {
            index = 1 << index;
        }
        return @(([self.field.value integerValue] & index) != 0);
    }
    else if ([self.field isIndexedType])
    {
        return @(index == [self.field.value integerValue]);
    }
    else if (value)
    {
        return @([value isEqual:self.field.value]);
    }
    else
    {
        return @(![self.field.options containsObject:self.field.value]);
    }
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    NSUInteger index = [key integerValue];
    if ([self.field isCollectionType])
    {
        BOOL addValue = [value boolValue];
        BOOL copyNeeded = ([NSStringFromClass(self.field.valueClass) rangeOfString:@"Mutable"].location == NSNotFound);
        
        id collection = self.field.value ?: [[self.field.valueClass alloc] init];
        if (copyNeeded) collection = [collection mutableCopy];
        
        if (index == NSNotFound)
        {
            collection = nil;
        }
        else if ([self.field.valueClass isSubclassOfClass:[NSIndexSet class]])
        {
            if (addValue)
            {
                [collection addIndex:index];
            }
            else
            {
                [collection removeIndex:index];
            }
        }
        else if ([self.field.valueClass isSubclassOfClass:[NSDictionary class]])
        {
            if (addValue)
            {
                collection[@(index)] = self.field.options[index];
            }
            else
            {
                [(NSMutableDictionary *)collection removeObjectForKey:@(index)];
            }
        }
        else
        {
            //need to preserve order for ordered collections
            [collection removeAllObjects];
            [self.field.options enumerateObjectsUsingBlock:^(id option, NSUInteger i, __unused BOOL *stop) {
                
                if (i == index)
                {
                    if (addValue) [collection addObject:option];
                }
                else if ([self.field.value containsObject:option])
                {
                    [collection addObject:option];
                }
            }];
            self.field.value = collection;
        }
        
        if (copyNeeded) collection = [collection copy];
        self.field.value = collection;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeBitfield])
    {
        if (index == NSNotFound)
        {
            self.field.value = @0;
        }
        else
        {
            if ([self.field.options[index] isKindOfClass:[NSNumber class]])
            {
                index = [self.field.options[index] integerValue];
            }
            else
            {
                index = 1 << index;
            }
            if ([value boolValue])
            {
                self.field.value = @([self.field.value integerValue] | index);
            }
            else
            {
                self.field.value = @([self.field.value integerValue] ^ index);
            }
        }
    }
    else if ([self.field isIndexedType])
    {
        self.field.value = @(index);
    }
    else if (index != NSNotFound)
    {
        self.field.value = self.field.options[index];
    }
    else
    {
        value = nil;
        for (NSDictionary *field in FXFormProperties(self.field.form))
        {
            if ([field[FXFormFieldKey] isEqualToString:self.field.key])
            {
                if ([field[FXFormFieldType] isEqualToString:FXFormFieldTypeInteger])
                {
                    value = @(NSNotFound);
                }
                break;
            }
        }
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

+ (NSArray *)sectionsWithForm:(id<FXForm>)form controller:(FXFormController *)formController;

@property (nonatomic, strong) id<FXForm> form;
@property (nonatomic, strong) NSString *header;
@property (nonatomic, strong) NSString *footer;
@property (nonatomic, strong) NSMutableArray *fields;

@end


@implementation FXFormSection

+ (NSArray *)sectionsWithForm:(id<FXForm>)form controller:(FXFormController *)formController
{
    NSMutableArray *sections = [NSMutableArray array];
    FXFormSection *section = nil;
    for (FXFormField *field in [FXFormField fieldsWithForm:form controller:formController])
    {
        if ([field.options count] && field.isInline)
        {
            id<FXForm> subform = [[FXOptionsForm alloc] initWithField:field];
            NSArray *subsections = [FXFormSection sectionsWithForm:subform controller:formController];
            if (![[subsections firstObject] header]) [[subsections firstObject] setHeader:field.header ?: field.title];
            [sections addObjectsFromArray:subsections];
            section = nil;
        }
        else if ([field.valueClass conformsToProtocol:@protocol(FXForm)] && field.isInline)
        {
            id<FXForm> subform = field.value;
            NSArray *subsections = [FXFormSection sectionsWithForm:subform controller:formController];
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
    for (Class fieldClass in @[[NSDictionary class], [NSArray class], [NSSet class], [NSOrderedSet class]])
    {
        if ([self isKindOfClass:fieldClass])
        {
            id collection = self;
            if (fieldClass == [NSDictionary class])
            {
                collection = [collection allValues];
            }
            NSMutableArray *array = [NSMutableArray array];
            for (id object in collection)
            {
                NSString *description = [object fieldDescription];
                if ([description length]) [array addObject:description];
            }
            return [array componentsJoinedByString:@", "];
        }
    }
    if ([self isKindOfClass:[NSDate class]])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        return [formatter stringFromDate:(NSDate *)self];
    }
    return @"";
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


@implementation FXFormController

- (instancetype)init
{
    if ((self = [super init]))
    {
        _cellClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormBaseCell class],
                                       FXFormFieldTypeText: [FXFormTextFieldCell class],
                                       FXFormFieldTypeLongText: [FXFormTextViewCell class],
                                       FXFormFieldTypeURL: [FXFormTextFieldCell class],
                                       FXFormFieldTypeEmail: [FXFormTextFieldCell class],
                                       FXFormFieldTypePassword: [FXFormTextFieldCell class],
                                       FXFormFieldTypeNumber: [FXFormTextFieldCell class],
                                       FXFormFieldTypeFloat: [FXFormTextFieldCell class],
                                       FXFormFieldTypeInteger: [FXFormTextFieldCell class],
                                       FXFormFieldTypeBoolean: [FXFormSwitchCell class],
                                       FXFormFieldTypeDate: [FXFormDatePickerCell class],
                                       FXFormFieldTypeTime: [FXFormDatePickerCell class],
                                       FXFormFieldTypeDateTime: [FXFormDatePickerCell class],
                                       FXFormFieldTypeImage: [FXFormImagePickerCell class]} mutableCopy];
        
        _controllerClassesForFieldTypes = [@{FXFormFieldTypeDefault: [FXFormViewController class]} mutableCopy];
                
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
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (Class)cellClassForFieldType:(NSString *)fieldType
{
    return self.cellClassesForFieldTypes[fieldType] ?:
    self.parentFormController.cellClassesForFieldTypes[fieldType] ?:
    self.cellClassesForFieldTypes[FXFormFieldTypeDefault];
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

- (Class)viewControllerClassForFieldType:(NSString *)fieldType
{
    return self.controllerClassesForFieldTypes[fieldType] ?:
    self.parentFormController.controllerClassesForFieldTypes[fieldType] ?:
    self.controllerClassesForFieldTypes[FXFormFieldTypeDefault];
}

- (void)registerDefaultViewControllerClass:(Class)controllerClass
{
    NSParameterAssert([controllerClass conformsToProtocol:@protocol(FXFormFieldViewController)]);
    [self.controllerClassesForFieldTypes setDictionary:@{FXFormFieldTypeDefault: controllerClass}];
}

- (void)registerViewControllerClass:(Class)controllerClass forFieldType:(NSString *)fieldType
{
    NSParameterAssert([controllerClass conformsToProtocol:@protocol(FXFormFieldViewController)]);
    self.controllerClassesForFieldTypes[fieldType] = controllerClass;
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
    self.sections = [FXFormSection sectionsWithForm:form controller:self];
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
#pragma mark Action handler

- (void)performAction:(SEL)selector withSender:(id)sender
{
    //walk up responder chain
    id responder = self.tableView;
    while (responder)
    {
        if ([responder respondsToSelector:selector])
        {
            
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
            
            [responder performSelector:selector withObject:sender];
            
#pragma GCC diagnostic pop
            
            return;
        }
        responder = [responder nextResponder];
    }
    
    //trye parent controller
    if (self.parentFormController)
    {
        [self.parentFormController performAction:selector withSender:sender];
    }
    else
    {
        [NSException raise:FXFormsException format:@"No object in the responder chain responds to the selector %@", NSStringFromSelector(selector)];
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
    if ([cellClass respondsToSelector:@selector(heightForField:width:)])
    {
        return [cellClass heightForField:field width:self.tableView.frame.size.width];
    }
    if ([cellClass respondsToSelector:@selector(heightForField:)])
    {
        return [cellClass heightForField:field];
    }
    return self.tableView.rowHeight;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];

    Class cellClass = field.cell ?: [self cellClassForFieldType:field.type];
    NSString *nibName = NSStringFromClass(cellClass);
    if ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"])
    {
        //load cell from nib
        return [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] firstObject];
    }
    else
    {
        //hackity-hack-hack
        UITableViewCellStyle style = UITableViewCellStyleDefault;
        if ([field valueForKeyPath:@"style"])
        {
            style = [[field valueForKeyPath:@"style"] integerValue];
        }
        else if (FXFormCanGetValueForKey(field.form, field.key))
        {
            style = UITableViewCellStyleValue1;
        }

        //don't recycle cells - it would make things complicated
        return [[cellClass alloc] initWithStyle:style reuseIdentifier:nil];
    }
}

#pragma mark -
#pragma mark Delegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    FXFormField *field = [self fieldForIndexPath:indexPath];

    //configure cell before setting field (in case it affects how value is displayed)
    [field.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, __unused BOOL *stop) {
        [cell setValue:value forKeyPath:keyPath];
    }];
    
    //set form field
    ((id<FXFormFieldCell>)cell).field = field;
    
    //configure cell after setting field as well (not ideal, but allows overriding keyboard attributes, etc)
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
        [self.delegate scrollViewWillBeginDragging:scrollView];
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
    if (cell && ![self.delegate isKindOfClass:[UITableViewController class]])
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
    if (cell && ![self.delegate isKindOfClass:[UITableViewController class]])
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

@synthesize field = _field;

- (void)dealloc
{
    _formController.delegate = nil;
}

- (void)setField:(FXFormField *)field
{
    _field = field;
    
    id<FXForm> form = self.field.value;
    if ([field.options count])
    {
        form = [[FXOptionsForm alloc] initWithField:field];
    }
    else if ([field.valueClass conformsToProtocol:@protocol(FXForm)])
    {
        form = field.value;
    }
    else
    {
        [NSException raise:FXFormsException format:@"FXFormViewController field value must conform to FXForm protocol"];
    }
    
    self.formController.parentFormController = field.formController;
    self.formController.form = form;
}

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
        [self.tableView deselectRowAtIndexPath:selected animated:YES];
    }
}

@end


#pragma mark -
#pragma mark Views


@implementation FXFormBaseCell

@synthesize field = _field;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier ?: NSStringFromClass([self class])]))
    {
        self.textLabel.font = [UIFont boldSystemFontOfSize:17];
        FXFormLabelSetMinFontSize(self.textLabel, FXFormFieldMinFontSize);
        self.detailTextLabel.font = [UIFont systemFontOfSize:17];
        FXFormLabelSetMinFontSize(self.detailTextLabel, FXFormFieldMinFontSize);
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
        {
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else
        {
            self.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    if (![keyPath isEqualToString:@"style"])
    {
        [super setValue:value forKeyPath:keyPath];
    }
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
    //override
    
    if ([self class] == [FXFormBaseCell class])
    {
        self.textLabel.text = self.field.title;
        self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
        
        if ([self.field.type isEqualToString:FXFormFieldTypeLabel])
        {
            self.accessoryType = UITableViewCellAccessoryNone;
            if (!self.field.action)
            {
                self.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
        else if ([self.field isSubform])
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
            self.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        else
        {
            self.accessoryType = UITableViewCellAccessoryNone;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
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

- (NSIndexPath *)indexPathForNextCell
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    if (indexPath)
    {
        //get next indexpath
        if ([tableView numberOfRowsInSection:indexPath.section] > indexPath.row + 1)
        {
            return [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        }
        else if ([tableView numberOfSections] > indexPath.section + 1)
        {
            return [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
        }
    }
    return nil;
}

- (UITableViewCell <FXFormFieldCell> *)nextCell
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [self indexPathForNextCell];
    if (indexPath)
    {
        //get next cell
        return (UITableViewCell <FXFormFieldCell> *)[tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(UIViewController *)controller
{
    if ([self.field.type isEqualToString:FXFormFieldTypeBoolean] || [self.field.type isEqualToString:FXFormFieldTypeOption])
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        self.field.value = @(![self.field.value boolValue]);
        if (self.field.action) self.field.action(self);
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
            [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
        }
    }
    else if ([self.field isSubform])
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        UIViewController *subcontroller = nil;
        if ([self.field.valueClass isSubclassOfClass:[UIViewController class]])
        {
            subcontroller = self.field.value;
        }
        else
        {
            subcontroller = [[self.field.viewController ?: [FXFormViewController class] alloc] init];
            ((id <FXFormFieldViewController>)subcontroller).field = self.field;
        }
        if (!subcontroller.title) subcontroller.title = self.field.title;
        [controller.navigationController pushViewController:subcontroller animated:YES];
    }
    else if (self.field.action)
    {
        [FXFormsFirstResponder(tableView) resignFirstResponder];
        self.field.action(self);
        [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
    }
}

@end


@interface FXFormTextFieldCell () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign, getter = isReturnKeyOverriden) BOOL returnKeyOverridden;

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

- (void)dealloc
{
    _textField.delegate = nil;
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
        if ([keyPath isEqualToString:@"textField.returnKeyType"])
        {
            //oh god, the hack, it burns
            self.returnKeyOverridden = YES;
        }
        
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
    self.textField.placeholder = [self.field.placeholder fieldDescription];
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
    if (self.textField.returnKeyType == UIReturnKeyNext)
    {
        [[self nextCell] becomeFirstResponder];
    }
    else
    {
        [self.textField resignFirstResponder];
    }
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
    if (self.field.action) self.field.action(self);
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
    //welcome to hacksville, population: you
    if (!self.returnKeyOverridden)
    {
        //get return key type
        UIReturnKeyType returnKeyType = UIReturnKeyDone;
        UITableViewCell <FXFormFieldCell> *nextCell = [self nextCell];
        if ([nextCell canBecomeFirstResponder])
        {
            returnKeyType = UIReturnKeyNext;
        }
        
        self.textField.returnKeyType = returnKeyType;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(__unused UITextField *)textField
{
    [self.textField selectAll:nil];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

@end


@interface FXFormTextViewCell () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;

@end


@implementation FXFormTextViewCell

+ (CGFloat)heightForField:(FXFormField *)field width:(CGFloat)width
{
    static UITextView *textView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        textView = [[UITextView alloc] init];
        textView.font = [UIFont systemFontOfSize:17];
    });
    
    textView.text = [field fieldDescription] ?: @" ";
    CGSize textViewSize = [textView sizeThatFits:CGSizeMake(width - FXFormFieldPaddingLeft - FXFormFieldPaddingRight, FLT_MAX)];
    
    CGFloat height = [field.title length]? 21: 0; // label height
    height += FXFormFieldPaddingTop + ceilf(textViewSize.height) + FXFormFieldPaddingBottom;
    return height;
}

- (void)setUp
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.textView.font = [UIFont systemFontOfSize:17];
    self.textView.textColor = [UIColor colorWithRed:0.275f green:0.376f blue:0.522f alpha:1.000f];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.delegate = self;
    self.textView.scrollEnabled = NO;
    [self.contentView addSubview:self.textView];
    
    self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    self.detailTextLabel.numberOfLines = 0;
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.textView action:NSSelectorFromString(@"becomeFirstResponder")]];
}

- (void)dealloc
{
    _textView.delegate = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.y = FXFormFieldPaddingTop;
    labelFrame.size.width = MIN(MAX([self.textLabel sizeThatFits:CGSizeZero].width, FXFormFieldMinLabelWidth), FXFormFieldMaxLabelWidth);
    self.textLabel.frame = labelFrame;
    
	CGRect textViewFrame = self.textView.frame;
    textViewFrame.origin.x = FXFormFieldPaddingLeft;
    textViewFrame.origin.y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    textViewFrame.size.width = self.contentView.bounds.size.width - FXFormFieldPaddingLeft - FXFormFieldPaddingRight;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
    textViewFrame.size.height = ceilf(textViewSize.height);
	if (![self.textLabel.text length])
    {
		textViewFrame.origin.y = self.textLabel.frame.origin.y;
	}
	self.textView.frame = textViewFrame;
    
    textViewFrame.origin.x += 5;
    textViewFrame.size.width -= 5;
    self.detailTextLabel.frame = textViewFrame;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.height = self.textView.frame.origin.y + self.textView.frame.size.height + FXFormFieldPaddingBottom;
    self.contentView.frame = contentViewFrame;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = self.field.placeholder;
    self.textView.text = [self.field fieldDescription];
    
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.textView.textAlignment = NSTextAlignmentLeft;
    self.textView.secureTextEntry = NO;
    
    if ([self.field.type isEqualToString:FXFormFieldTypeText])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.textView.keyboardType = UIKeyboardTypeAlphabet;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeNumber] || [self.field.type isEqualToString:FXFormFieldTypeInteger])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypePassword])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeAlphabet;
        self.textView.secureTextEntry = YES;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeEmail])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeEmailAddress;
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeURL])
    {
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textView.keyboardType = UIKeyboardTypeURL;
    }
    
    [self setNeedsLayout];
}

- (void)textViewDidBeginEditing:(__unused UITextView *)textView
{
    [self.textView selectAll:nil];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self updateFieldValue];
    
    //show/hide placeholder
    self.detailTextLabel.hidden = ([textView.text length] > 0);
    
    //resize the tableview if required
    UITableView *tableView = [self tableView];
    [tableView beginUpdates];
    [tableView endUpdates];
    
    //scroll to show cursor
    CGRect cursorRect = [self.textView caretRectForPosition:self.textView.selectedTextRange.end];
    [tableView scrollRectToVisible:[tableView convertRect:cursorRect fromView:self.textView] animated:YES];
}

- (void)textViewDidEndEditing:(__unused UITextView *)textView
{
    [self updateFieldValue];
    if (self.field.action) self.field.action(self);
}

- (void)updateFieldValue
{
    if ([self.field.type isEqualToString:FXFormFieldTypeNumber])
    {
        self.field.value = @([self.textView.text doubleValue]);
    }
    else if ([self.field.type isEqualToString:FXFormFieldTypeInteger])
    {
        self.field.value = @([self.textView.text integerValue]);
    }
    else if ([self.field.valueClass isSubclassOfClass:[NSURL class]])
    {
        self.field.value = [self.field.valueClass URLWithString:self.textView.text];
    }
    else
    {
        self.field.value = self.textView.text;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [self.textView becomeFirstResponder];
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
    [self setNeedsLayout];
}

- (UISwitch *)switchControl
{
    return (UISwitch *)self.accessoryView;
}

- (void)valueChanged
{
    self.field.value = @(self.switchControl.on);
    if (self.field.action) self.field.action(self);
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
    if (self.field.action) self.field.action(self);
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
    [self setNeedsLayout];
}

- (void)valueChanged
{
    self.field.value = @(self.slider.value);
    if (self.field.action) self.field.action(self);
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
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
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
    
    self.datePicker.date = self.field.value ?: ([self.field.placeholder isKindOfClass:[NSDate class]]? self.field.placeholder: [NSDate date]);
    
    [self setNeedsLayout];
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
    self.detailTextLabel.text = [self.field fieldDescription];
    [self setNeedsLayout];
    
    if (self.field.action) self.field.action(self);
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(__unused UIViewController *)controller
{
    [self becomeFirstResponder];
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
}

@end


@interface FXFormImagePickerCell () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end


@implementation FXFormImagePickerCell

- (void)setUp
{
    [super setUp];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    self.accessoryView = imageView;
    [self setNeedsLayout];
}

- (void)dealloc
{
    _imagePickerController.delegate = nil;
}

- (void)layoutSubviews
{
    CGRect frame = self.imagePickerView.bounds;
    frame.size.height = self.bounds.size.height - 10;
    frame.size.width = self.imagePickerView.image? self.imagePickerView.image.size.width / frame.size.height: 0;
    self.imagePickerView.bounds = frame;
    
    [super layoutSubviews];
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.imagePickerView.image = [self imageValue];
    [self setNeedsLayout];
}

- (UIImage *)imageValue
{
    if (self.field.value)
    {
        return self.field.value;
    }
    else if (self.field.placeholder)
    {
        UIImage *placeholderImage = self.field.placeholder;
        if ([placeholderImage isKindOfClass:[NSString class]])
        {
            placeholderImage = [UIImage imageNamed:self.field.placeholder];
        }
        return placeholderImage;
    }
    return nil;
}

- (UIImagePickerController *)imagePickerController
{
    if (!_imagePickerController)
    {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        [self setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    return _imagePickerController;
}

- (UIImageView *)imagePickerView
{
    return (UIImageView *)self.accessoryView;
}

- (BOOL)setSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:sourceType])
    {
        self.imagePickerController.sourceType = sourceType;
        return YES;
    }
    return NO;
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(UIViewController *)controller
{
    [self becomeFirstResponder];
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
    [controller presentViewController:self.imagePickerController animated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.field.value = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    self.imagePickerView.image = [self imageValue];
    [self setNeedsLayout];
    
    if (self.field.action) self.field.action(self);
}

@end


@interface FXFormOptionPickerCell () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIPickerView *pickerView;

@end


@implementation FXFormOptionPickerCell

- (void)setUp
{
    [super setUp];
    
    self.pickerView = [[UIPickerView alloc] init];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
}

- (void)dealloc
{
    _pickerView.dataSource = nil;
    _pickerView.delegate = nil;
}

- (void)update
{
    self.textLabel.text = self.field.title;
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    NSUInteger index = self.field.value? [self.field.options indexOfObject:self.field.value]: NSNotFound;
    if (self.field.placeholder)
    {
        index = (index == NSNotFound)? 0: index + 1;
    }
    if (index != NSNotFound)
    {
        [self.pickerView selectRow:index inComponent:0 animated:NO];
    }
    
    [self setNeedsLayout];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputView
{
    return self.pickerView;
}

- (void)didSelectWithTableView:(UITableView *)tableView controller:(__unused UIViewController *)controller
{
    [self becomeFirstResponder];
    [tableView deselectRowAtIndexPath:tableView.indexPathForSelectedRow animated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component
{
    return [self.field.options count] + (self.field.placeholder? 1: 0);
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component
{
    if (row == 0)
    {
        return [self.field.placeholder fieldDescription] ?: [self.field optionDescriptionAtIndex:0];
    }
    else
    {
        return [self.field optionDescriptionAtIndex:row - (self.field.placeholder? 1: 0)];
    }
}

- (void)pickerView:(__unused UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(__unused NSInteger)component
{
    id value = nil;
    if (!self.field.placeholder || row > 0)
    {
        value = self.field.options[row - (self.field.placeholder? 1: 0)];
    }
    self.field.value = value;
    self.detailTextLabel.text = [self.field fieldDescription] ?: [self.field.placeholder fieldDescription];
    
    [self setNeedsLayout];
    
    if (self.field.action) self.field.action(self);
}

@end
