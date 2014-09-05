//
//  FXFormsTests.m
//  UnitTests
//
//  Created by Nick Lockwood on 17/06/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "FXForms.h"


@interface Form : NSObject <FXForm>

@property (nonatomic, assign) NSInteger options1;
@property (nonatomic, assign) NSInteger options2;
@property (nonatomic, copy) NSString *options3;
@property (nonatomic, copy) NSString *options4;
@property (nonatomic, assign) NSInteger options5;
@property (nonatomic, assign) NSInteger options6;
@property (nonatomic, strong) NSNumber *options7;
@property (nonatomic, strong) NSNumber *options8;
@property (nonatomic, strong) NSArray *options9;
@property (nonatomic, strong) NSNumber *options10;

@end


@implementation Form

- (NSDictionary *)options1Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"]};
}

- (NSDictionary *)options2Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"], FXFormFieldPlaceholder: @"Nope"};
}

- (NSDictionary *)options3Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"]};
}

- (NSDictionary *)options4Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"], FXFormFieldPlaceholder: @"Nope"};
}

- (NSDictionary *)options5Field
{
    return @{FXFormFieldOptions: @[@5, @10, @15]};
}

- (NSDictionary *)options6Field
{
    return @{FXFormFieldOptions: @[@5, @10, @15], FXFormFieldPlaceholder: @"Nope"};
}

- (NSDictionary *)options7Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"]};
}

- (NSDictionary *)options8Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"], FXFormFieldPlaceholder: @"Nope"};
}

- (NSDictionary *)options9Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"], FXFormFieldPlaceholder: @"Nope"};
}

- (NSDictionary *)options10Field
{
    return @{FXFormFieldOptions: @[@"Foo", @"Bar", @"Baz"], FXFormFieldDefaultValue: @1};
}

@end


@interface FXFormsTests : XCTestCase

@property (nonatomic, strong) FXFormController *controller;

@end


@implementation FXFormsTests

- (void)setUp
{
    self.controller = [[FXFormController alloc] init];
    self.controller.form = [[Form alloc] init];
}

- (void)testIndexedOptions
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertEqual([field optionCount], 3, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Foo", @"");
    XCTAssertEqualObjects(field.value, @0, @""); //defaults to zero
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertEqualObjects(field.value, @0, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @1, @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @2, @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:2];
    XCTAssertEqualObjects(field.value, @2, @"");
}

- (void)testIndexedOptionsWithPlaceholder
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    XCTAssertEqual([field optionCount], 4, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Nope", @"");
    XCTAssertEqualObjects(field.value, @0, @""); //defaults to zero
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertNil(field.value, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @0, @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @1, @"");
    
    [field setOptionSelected:YES atIndex:3];
    XCTAssertEqualObjects(field.value, @2, @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:3];
    XCTAssertEqualObjects(field.value, @2, @"");
}

- (void)testStringOptions
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    XCTAssertEqual([field optionCount], 3, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Foo", @"");
    XCTAssertNil(field.value, @""); //defaults to nil
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertEqualObjects(field.value, @"Foo", @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @"Bar", @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @"Baz", @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:2];
    XCTAssertEqualObjects(field.value, @"Baz", @"");
}

- (void)testStringOptionsWithPlaceholder
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    XCTAssertEqual([field optionCount], 4, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Nope", @"");
    XCTAssertNil(field.value, @""); //defaults to nil
    
    [field setOptionSelected:NO atIndex:0];
    XCTAssertNil(field.value, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @"Foo", @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @"Bar", @"");
    
    [field setOptionSelected:YES atIndex:3];
    XCTAssertEqualObjects(field.value, @"Baz", @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:3];
    XCTAssertEqualObjects(field.value, @"Baz", @"");
}

- (void)testNumberOptions
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    XCTAssertEqual([field optionCount], 3, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"5", @"");
    XCTAssertNil(field.value, @""); //defaults to nil/zero
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertEqualObjects(field.value, @5, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @10, @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @15, @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:2];
    XCTAssertEqualObjects(field.value, @15, @"");
}

- (void)testNumberOptionsWithPlaceholder
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    XCTAssertEqual([field optionCount], 4, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Nope", @"");
    XCTAssertNil(field.value, @""); //defaults to nil/zero
    
    [field setOptionSelected:NO atIndex:0];
    XCTAssertNil(field.value, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @5, @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @10, @"");
    
    [field setOptionSelected:YES atIndex:3];
    XCTAssertEqualObjects(field.value, @15, @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:3];
    XCTAssertEqualObjects(field.value, @15, @"");
}

- (void)testIndexedOptionsWithNSNumber
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    XCTAssertEqual([field optionCount], 3, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Foo", @"");
    XCTAssertNil(field.value, @""); //defaults to nil
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertEqualObjects(field.value, @0, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @1, @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @2, @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:2];
    XCTAssertEqualObjects(field.value, @2, @"");
}

- (void)testIndexedOptionsWithNSNumberWithPlaceholder
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:7 inSection:0]];
    XCTAssertEqual([field optionCount], 4, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Nope", @"");
    XCTAssertNil(field.value, @""); //defaults to nil
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertNil(field.value, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @0, @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @1, @"");
    
    [field setOptionSelected:YES atIndex:3];
    XCTAssertEqualObjects(field.value, @2, @"");
    
    //trying to unset an index has no effect
    //unless it's a multiselect field
    [field setOptionSelected:NO atIndex:3];
    XCTAssertEqualObjects(field.value, @2, @"");
}

- (void)testOptions1Type
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertEqualObjects(field.type, FXFormFieldTypeDefault, @"");
    XCTAssertEqualObjects(field.valueClass, [NSNumber class], @"");
}

- (void)testToggleOptions
{
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:8 inSection:0]];
    
    [field setOptionSelected:YES atIndex:0];
    XCTAssertNil(field.value, @"");
    
    [field setOptionSelected:NO atIndex:0];
    XCTAssertNil(field.value, @"");
    
    [field setOptionSelected:YES atIndex:1];
    XCTAssertEqualObjects(field.value, @[@"Foo"], @"");
    
    [field setOptionSelected:NO atIndex:1];
    XCTAssertEqualObjects(field.value, @[], @"");
    
    [field setOptionSelected:YES atIndex:2];
    XCTAssertEqualObjects(field.value, @[@"Bar"], @"");
    
    [field setOptionSelected:NO atIndex:2];
    XCTAssertEqualObjects(field.value, @[], @"");
}

- (void)testDefaultValue
{
    NSString *defaultValue = [(Form *)self.controller.form options10Field][FXFormFieldDefaultValue];
    FXFormField *field = [self.controller fieldForIndexPath:[NSIndexPath indexPathForRow:9 inSection:0]];
    XCTAssertEqual([field optionCount], 3, @"");
    XCTAssertEqualObjects([field optionDescriptionAtIndex:0], @"Foo", @"");
    XCTAssertEqualObjects(field.value, defaultValue);
}

@end
