//
//  ISO3166CountryValueTransformer.swift
//  SwiftExample
//
//  Created by Nick Lockwood on 29/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit

class ISO3166CountryValueTransformer: NSValueTransformer {
   
    override class func transformedValueClass() -> AnyClass {
        
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        
        return false
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        
        if value != nil {
            return NSLocale(localeIdentifier: "en_US").displayNameForKey(NSLocaleCountryCode, value:value!) ?? value
        }
        return nil
    }
}
