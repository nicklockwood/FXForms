//
//  RegistrationForm.swift
//  SwiftExample
//
//  Created by Nick Lockwood on 29/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit


class RegistrationForm: NSObject, FXForm {

    var email: String?
    var password: String?
    var repeatPassword: String?
    
    var name: String?
    var gender = 0
    var age: UInt = 0
    var dateOfBirth: NSDate?
    var profilePhoto: UIImage?
    var phone: String?
    var country: String?
    var language: String?
    var interests: [AnyObject]?
    var otherInterests = 0
    var about: String?
    
    var plan: Int = 0
    
    var notifications: String?
    
    var agreedToTerms = false
    
    //because we want to rearrange how this form
    //is displayed, we've implemented the fields array
    //which lets us dictate exactly which fields appear
    //and in what order they appear
        
    func fields() -> [AnyObject] {
        
        return [
        
            //we want to add a group header for the field set of fields
            //we do that by adding the header key to the first field in the group
            
            [FXFormFieldKey: "email", FXFormFieldHeader: "Account"],
            
            //we don't need to modify these fields at all, so we'll
            //just refer to them by name to use the default settings
            
            "password",
            "repeatPassword",
            
            //we want to add another group header here, and modify the auto-capitalization
            
            [FXFormFieldKey: "name", FXFormFieldHeader: "Details",
                "textField.autocapitalizationType": UITextAutocapitalizationType.Words.rawValue],

            //this is a multiple choice field, so we'll need to provide some options
            //because this is an enum property, the indexes of the options should match enum values
            
            [FXFormFieldKey: "gender", FXFormFieldOptions: ["Male", "Female", "It's Complicated"]],
            
            //another regular field
            
            "dateOfBirth",
            
            //we want to use a stepper control for this value, so let's specify that
            
            [FXFormFieldKey: "age", FXFormFieldCell: FXFormStepperCell.self],
            
            //some more regular fields
            
            "profilePhoto",
            "phone",
            
            //the country value in our form is a locale code, which isn't human readable
            //so we've used the FXFormFieldValueTransformer option to supply a value transformer
            
            [FXFormFieldKey: "country",
                FXFormFieldOptions: ["us", "ca", "gb", "sa", "be"],
                FXFormFieldPlaceholder: "None",
                FXFormFieldValueTransformer: ISO3166CountryValueTransformer()],
            
            //this is an options field that uses a FXFormOptionPickerCell to display the available
            //options in a UIPickerView
            
            [FXFormFieldKey: "language",
                FXFormFieldOptions: ["English", "Spanish", "French", "Dutch"],
                FXFormFieldPlaceholder: "None",
                FXFormFieldCell: FXFormOptionPickerCell.self],
            
            //this is a multi-select options field - FXForms knows this because the
            //class of the field property is a collection (in this case, NSArray)
            
            [FXFormFieldKey: "interests", FXFormFieldPlaceholder: "None",
                FXFormFieldOptions: ["Videogames", "Animals", "Cooking"]],
            
            //this is another multi-select options field, but in this case it's represented
            //as a bitfield. FXForms can't infer this from the property (which is just an integer), so
            //we explicitly specify the type as FXFormFieldTypeBitfield
            
            [FXFormFieldKey: "otherInterests",
                FXFormFieldType: FXFormFieldTypeBitfield,
                FXFormFieldPlaceholder: "None",
                FXFormFieldOptions: ["Computers", "Socializing", "Sports"]],
            
            //this is a multiline text view that grows to fit its contents
            
            [FXFormFieldKey: "about", FXFormFieldType: FXFormFieldTypeLongText],
            
            //this is an options field that uses a FXFormOptionSegmentsCell to display the available
            //options in a UIPickerView
            
            [FXFormFieldHeader: "Plan",
                FXFormFieldKey: "plan",
                FXFormFieldTitle: "",
                FXFormFieldPlaceholder: "Free",
                FXFormFieldOptions: ["Micro", "Normal", "Maxi"],
                FXFormFieldCell: FXFormOptionSegmentsCell.self],
            
            //we've implemented the terms and privacy policy as segues, which means that
            //they have to be set up with configuration dictionaries, as there's no way
            //to infer them from the form properties
            
            [FXFormFieldHeader: "Legal",
                FXFormFieldTitle: "Terms And Conditions",
                FXFormFieldSegue: "TermsSegue"],
            
            [FXFormFieldTitle: "Privacy Policy",
                FXFormFieldSegue: "PrivacyPolicySegue"],
            
            //the automatically generated title (Agreed To Terms) and cell (FXFormSwitchCell)
            //don't really work for this field, so we'll override them both (a type of
            //FXFormFieldTypeOption will use an checkmark instead of a switch by default)
            
            [FXFormFieldKey: "agreedToTerms", FXFormFieldTitle: "I Agree To These Terms", FXFormFieldType: FXFormFieldTypeOption],
        ]
    }
   
    func extraFields() -> [AnyObject] {
        
        return [
            //this field doesn't correspond to any property of the form
            //it's just an action button. the action will be called on first
            //object in the responder chain that implements the submitForm
            //method, which in this case would be the AppDelegate
            
            [FXFormFieldCell: SubmitButtonCell.self, FXFormFieldHeader: "", FXFormFieldAction: "submitRegistrationForm:"],
        ]
    }
}
