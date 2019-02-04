//
//  CDLocationDelegate.h
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Localytics;

@protocol CDVCommandDelegate;
@class CDVInvokedUrlCommand;

@interface CDLocationDelegate : NSObject <LLLocationDelegate>

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand;

@end
