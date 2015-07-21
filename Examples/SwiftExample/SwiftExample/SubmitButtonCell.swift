//
//  SubmitButtonCell.swift
//  SwiftExample
//
//  Created by Felipe Leal Coutinho on 21/07/15.
//  Copyright (c) 2015 Nick Lockwood. All rights reserved.
//

import Foundation
import UIKit

class SubmitButtonCell: FXFormBaseCell {
    
    @IBAction func buttonAction(sender: UIButton) {
        if let action = field.action {
            action(self)
        }
    }
}