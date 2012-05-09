//
//  LocationController.h
//  AdViewSDK_Sample
//
//  Created by Nigel Choi on 2/8/10.
//  Copyright 2010 Admob. Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManager.h>
#import "TableController.h"

@interface LocationController : TableController <CLLocationManagerDelegate> {
  CLLocationManager *locationManager;
  UIInterfaceOrientation currLayoutOrientation;
}

@property (nonatomic,readonly) UILabel *locLabel;

- (void)adjustLayoutToOrientation:(UIInterfaceOrientation)newOrientation;

@end
