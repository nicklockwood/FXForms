//
//  DynamicForm.m
//  DynamicFieldsExample
//
//  Created by Nick Lockwood on 04/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "DynamicForm.h"


@implementation DynamicForm

- (id)init
{
    if ((self = [super init]))
    {
        //set up dictionary for storing form values
        //we could prepopulate this with defaults if we wanted
        //or load previously saved values from a file or database
        
        _valuesByKey = [NSMutableDictionary dictionary];
    }
    return self;
}

//these two methods proxy any values that we set/get on the form
//to the internal valuesByKey dictionary. you don't have to store
//them in a dictionary though - you could put them into a coredata
//object, or save them in a database, or whatever

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if (value)
    {
        self.valuesByKey[key] = value;
    }
    else
    {
        [self.valuesByKey removeObjectForKey:key];
    }
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return self.valuesByKey[key];
}

//load the complete specificiation for all our fields from a json file
//we could equally use a plist, or an array that we downloaded from a web service
//or loaded from a database of some kind - as long as it contains the right
//structure, it doesn't matter where it comes from

- (NSArray *)fields
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"FormFields" ofType:@"json"];
    NSData *fieldsData = [NSData dataWithContentsOfFile:path];
    return [NSJSONSerialization JSONObjectWithData:fieldsData options:(NSJSONReadingOptions)0 error:NULL];
}

@end
