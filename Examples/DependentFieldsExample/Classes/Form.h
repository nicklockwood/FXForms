//
//  Form.h
//  BasicExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXForms.h"


@interface Form : NSObject <FXForm>

@property (nonatomic, assign) NSUInteger year;
@property (nonatomic, assign) NSUInteger month;
@property (nonatomic, assign) NSUInteger day;

@end
