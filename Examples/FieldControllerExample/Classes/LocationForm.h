//
//  LocationForm.h
//  FieldControllerExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "FXForms.h"


@interface LocationForm : NSObject <FXForm>

@property (nonatomic, strong) CLLocation *location;

@end
