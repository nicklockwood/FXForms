//
//  RegistrationForm.m
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "RegistrationForm.h"
#import "ISO3166CountryValueTransformer.h"


@implementation RegistrationForm

//because we want to rearrange how this form
//is displayed, we've implemented the fields array
//which lets us dictate exactly which fields appear
//and in what order they appear

- (NSArray *)fields
{
    return @[
             
             //we want to add a group header for the field set of fields
             //we do that by adding the header key to the first field in the group
             
             @{FXFormFieldKey: @"email", FXFormFieldHeader: @"Account"},
             
             //we don't need to modify these fields at all, so we'll
             //just refer to them by name to use the default settings
             
             @"password",
             @"repeatPassword",
             
             //we want to add another group header here, and modify the auto-capitalization
             
             @{FXFormFieldKey: @"name", FXFormFieldHeader: @"Details",
               @"textField.autocapitalizationType": @(UITextAutocapitalizationTypeWords)},
             
             //this is a multiple choice field, so we'll need to provide some options
             //because this is an enum property, the indexes of the options should match enum values
             
             @{FXFormFieldKey: @"gender", FXFormFieldOptions: @[@"Male", @"Female", @"It's Complicated"]},
             
             //another regular field
             
             @"dateOfBirth",
             
             //we want to use a stepper control for this value, so let's specify that
             
             @{FXFormFieldKey: @"age", FXFormFieldCell: [FXFormStepperCell class]},
             
             //some more regular fields
             
             @"profilePhoto",
             @"phone",
             
             //the country value in our form is a locale code, which isn't human readable
             //so we've used the FXFormFieldValueTransformer option to supply a value transformer
             
             @{FXFormFieldKey: @"country",
               FXFormFieldOptions: @[@"us", @"ca", @"gb", @"sa", @"be"],
               FXFormFieldDefaultValue: @"us",
               FXFormFieldValueTransformer: [[ISO3166CountryValueTransformer alloc] init]},
             
             //this is an options field that uses a FXFormOptionPickerCell to display the available
             //options in a UIPickerView
             
             @{FXFormFieldKey: @"language",
               FXFormFieldOptions: @[@"English", @"Spanish", @"French", @"Dutch"],
               FXFormFieldDefaultValue: @"English",
               FXFormFieldCell: [FXFormOptionPickerCell class]},
             
             //this is a multi-select options field - FXForms knows this because the
             //class of the field property is a collection (in this case, NSArray)
             
             @{FXFormFieldKey: @"interests",
               FXFormFieldDefaultValue: @"Videogames",
               FXFormFieldOptions: @[@"Videogames", @"Animals", @"Cooking"]},
             
             //this is another multi-select options field, but in this case it's represented
             //as a bitfield. FXForms can't infer this from the property (which is just an integer), so
             //we explicitly specify the type as FXFormFieldTypeBitfield
             
             @{FXFormFieldKey: @"otherInterests",
               FXFormFieldType: FXFormFieldTypeBitfield,
               FXFormFieldDefaultValue: @(InterestComputers),
               FXFormFieldOptions: @[@"Computers", @"Socializing", @"Sports"]},

             //this is a multiline text view that grows to fit its contents
             
             @{FXFormFieldKey: @"about", FXFormFieldType: FXFormFieldTypeLongText, FXFormFieldPlaceholder: @"Text..."},
             
             //this is an options field that uses a FXFormOptionSegmentsCell to display the available
             //options in a UIPickerView
             
             @{FXFormFieldHeader: @"Plan",
               FXFormFieldKey: @"plan",
               FXFormFieldTitle: @"",
               FXFormFieldPlaceholder: @"Free",
               FXFormFieldOptions: @[@"Micro", @"Normal", @"Maxi"],
               FXFormFieldCell: [FXFormOptionSegmentsCell class]},
             
             //we want to add a section header here, so we use another config dictionary
             
             @{FXFormFieldKey: @"termsAndConditions", FXFormFieldHeader: @"Legal"},
             
             //another regular field. note that we haven't actually instantiated the terms
             //and conditions or privacy policy view controllers - FXForms will instantiate
             //view controllers automatically if the value is nil, or will used the supplied
             //controller instance if there is one
             
             @"privacyPolicy",
             
             //the automatically generated title (Agreed To Terms) and cell (FXFormSwitchCell)
             //don't really work for this field, so we'll override them both (a type of
             //FXFormFieldTypeOption will use an checkmark instead of a switch by default)
             
             @{FXFormFieldKey: @"agreedToTerms", FXFormFieldTitle: @"I Agree To These Terms", FXFormFieldType: FXFormFieldTypeOption},
             
             //this field doesn't correspond to any property of the form
             //it's just an action button. the action will be called on first
             //object in the responder chain that implements the submitForm
             //method, which in this case would be the AppDelegate
             
             @{FXFormFieldTitle: @"Submit", FXFormFieldHeader: @"", FXFormFieldAction: @"submitRegistrationForm:"},
             
             ];
}

@end
