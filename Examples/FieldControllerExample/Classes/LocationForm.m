//
//  LocationForm.m
//  FieldControllerExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LocationForm.h"

@implementation LocationForm

//we want to edit our location using a LocationMapViewController
//instead of an inline field, so we specify that using the
//FXFormFieldViewController property

- (NSDictionary *)locationField
{
    return @{FXFormFieldViewController: @"LocationMapViewController"};
}

//we want to display our location in human readable format
//CLLocation has no default implementation for -fieldDescription
//so we can specify how its value should be displayed using the
//following <fieldName>FieldDescription syntax

- (NSString *)locationFieldDescription
{
    return self.location? [NSString stringWithFormat:@"%0.3f, %0.3f",
                           self.location.coordinate.latitude,
                           self.location.coordinate.longitude]: nil;
}

@end
