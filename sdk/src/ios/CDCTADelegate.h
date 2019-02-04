//
//  CDAnalyticsDelegate.h
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Localytics;

@protocol CDVCommandDelegate;
@protocol LLLocationMonitoringDelegate;
@class CDVInvokedUrlCommand;

@interface CDCTADelegate : NSObject <LLCallToActionDelegate>

@property (nonatomic, weak, nullable) id<CDVCommandDelegate> commandDelegate;
@property (nonatomic, strong, nullable) CDVInvokedUrlCommand *invokedUrlCommand;
@property (nonatomic, strong, nullable) id<LLLocationMonitoringDelegate> monitoringDelegate;

@end
