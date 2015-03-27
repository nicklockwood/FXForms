//
//  RootForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "RootForm.h"


@implementation RootForm

- (id)init
{
    if ((self = [super init]))
    {
        _array = @[@"Foo", @"Bar", @"Baz"];
        _sortableArray = @[@"Foo", @"Bar", @"Baz"];
        _inlineArray = @[@"Foo", @"Bar", @"Baz"];
        _inlineSortableArray = @[@"Foo", @"Bar", @"Baz"];
    }
    return self;
}

- (NSDictionary *)sortableArrayField
{
    return @{FXFormFieldSortable: @YES};
}

- (NSDictionary *)arrayWithTemplateField
{
    return @{FXFormFieldTemplate: @{FXFormFieldType: FXFormFieldTypeImage}};
}

- (NSDictionary *)sortableArrayWithTemplateField
{
    return @{FXFormFieldSortable: @YES,
             FXFormFieldTemplate: @{FXFormFieldType: FXFormFieldTypeImage}};
}

- (NSDictionary *)inlineArrayField
{
    return @{FXFormFieldInline: @YES};
}

- (NSDictionary *)inlineSortableArrayField
{
    return @{FXFormFieldInline: @YES, FXFormFieldSortable: @YES};
}

- (NSDictionary *)inlineArrayWithTemplateField
{
    return @{FXFormFieldInline: @YES, FXFormFieldTemplate: @{
                     FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"],
                     FXFormFieldTitle: @"Add Choice"}
             };
}

- (NSDictionary *)inlineSortableArrayWithTemplateField
{
    return @{FXFormFieldInline: @YES, FXFormFieldSortable: @YES, FXFormFieldTemplate: @{
                     FXFormFieldType: FXFormFieldTypeLongText}
             };
}

- (NSDictionary *)otherEmailsField
{
  return @{
           FXFormFieldInline: @YES,
           FXFormFieldTemplate: @{
               FXFormFieldType: FXFormFieldTypeEmail,
               FXFormFieldTitle: @"Add another email",
               }
           };
}

@end
