//
//  LocationMapViewController.m
//  BasicExample
//
//  Created by Nick Lockwood on 24/03/2014.
//  Copyright (c) 2014 Charcoal Design. All rights reserved.
//

#import "LocationMapViewController.h"
#import <MapKit/MapKit.h>


@interface LocationMapViewController () <MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@end


@implementation LocationMapViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //set start location
    if (self.field.value)
    {
        self.mapView.centerCoordinate = ((CLLocation *)self.field.value).coordinate;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(__unused BOOL)animated
{
    //update field value
    self.field.value = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude
                                                  longitude:mapView.centerCoordinate.longitude];
    
    //update title
    self.title = [NSString stringWithFormat:@"Location: %0.3f, %0.3f",
                  mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude];
}

@end
