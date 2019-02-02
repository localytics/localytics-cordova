//
//  CDMessagingDelegate.h
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Localytics;

@protocol CDVCommandDelegate;
@class CDVInvokedUrlCommand;

@interface CDMessagingDelegate : NSObject <LLMessagingDelegate>

@property (nonatomic, strong) NSDictionary *inAppConfig;
@property (nonatomic, strong) NSDictionary *placesConfig;

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand
                     inAppCampaignCache:(NSMutableDictionary *)inAppCampaignCache
                    placesCampaignCache:(NSMutableDictionary *)placesCampaignCache;

@end
