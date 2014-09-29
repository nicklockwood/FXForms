//
//  RegistrationFormViewController.swift
//  SwiftExample
//
//  Created by Nick Lockwood on 29/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit

class RegistrationFormViewController: FXFormViewController {

    override func awakeFromNib() {
        
        formController.form = RegistrationForm()
    }

    func submitRegistrationForm(cell: FXFormFieldCellProtocol) {
        
        //we can lookup the form from the cell if we want, like this:
        let form = cell.field.form as RegistrationForm
    
        //we can then perform validation, etc
        if form.agreedToTerms {
            
            UIAlertView(title: "Registration Form Submitted", message: "", delegate: nil, cancelButtonTitle: "OK").show()
        
        } else {
            
            UIAlertView(title: "User Error", message: "Please agree to the terms and conditions before proceeding", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "Yes Sir!").show()
        }
    }
    
}

