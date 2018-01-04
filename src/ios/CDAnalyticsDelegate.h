//
//  CDAnalyticsDelegate.h
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Localytics;

@protocol CDVCommandDelegate;
@class CDVInvokedUrlCommand;

@interface CDAnalyticsDelegate : NSObject <LLAnalyticsDelegate>

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand;

@end
