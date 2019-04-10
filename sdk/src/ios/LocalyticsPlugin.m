//
//  LocalyticsPlugin.m
//
//  Copyright 2015 Localytics. All rights reserved.
//

#import <objc/runtime.h>
#import "AppDelegate.h"
#import "LocalyticsPlugin.h"
#import "CDAnalyticsDelegate.h"
#import "CDLocationDelegate.h"
#import "CDMessagingDelegate.h"
#import "CDCTADelegate.h"

@import UserNotifications;
@import Localytics;

#define PLUGIN_VERSION @"Cordova_5.5.0"

#define PROFILE_SCOPE_ORG @"org"
#define PROFILE_SCOPE_APP @"app"

@interface LocalyticsPlugin ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLInAppCampaign *> *inAppCampaignCache;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLInboxCampaign *> *inboxCampaignCache;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLPlacesCampaign *> *placesCampaignCache;

@property (nonatomic, strong) CDAnalyticsDelegate *analyticsDelegate;
@property (nonatomic, strong) CDLocationDelegate *locationDelegate;
@property (nonatomic, strong) CDCTADelegate *ctaDelegate;
@property (nonatomic, strong) CDMessagingDelegate *messagingDelegate;

@end

@implementation LocalyticsPlugin

LocalyticsPlugin *shared;

- (instancetype)init {
    if (self = [super init]) {
        shared = self;
    }
    return self;
}

+ (LocalyticsPlugin *)sharedInstance {
    if (!shared) {
        shared = [[LocalyticsPlugin alloc] init];
    }
    return shared;
}

#pragma mark Native Cordova Specific

+ (void)setLocationMonitoringDelegate:(nullable id<LLLocationMonitoringDelegate>)delegate {
    [[LocalyticsPlugin sharedInstance] setLocationMonitoringDelegate:delegate];
}

- (void)setLocationMonitoringDelegate:(nullable id<LLLocationMonitoringDelegate>)delegate {
    if (!self.ctaDelegate) {
        self.ctaDelegate = [CDCTADelegate new];
        [Localytics setCallToActionDelegate:self.ctaDelegate];
    }
    self.ctaDelegate.monitoringDelegate = delegate;
}

#pragma mark Private

- (NSUInteger)getProfileScope:(NSString *)scope {
    if ([scope caseInsensitiveCompare:PROFILE_SCOPE_ORG] == NSOrderedSame) {
        return LLProfileScopeOrganization;
    } else {
        return LLProfileScopeApplication;
    }
}

- (LLInAppMessageDismissButtonLocation)getDismissButtonLocation:(NSString *)value {
    if ([value caseInsensitiveCompare:@"right"] == NSOrderedSame) {
        return LLInAppMessageDismissButtonLocationRight;
    } else {
        return LLInAppMessageDismissButtonLocationLeft;
    }
}

- (NSString *)fromDismissButtonLocation:(LLInAppMessageDismissButtonLocation)location {
    switch (location) {
        case LLInAppMessageDismissButtonLocationRight:
            return @"right";
        default:
            return @"left";
    }
}

- (LLCustomer *)customerFrom:(NSDictionary *)dict {
    if (dict) {
        return [LLCustomer customerWithBlock:^(LLCustomerBuilder* builder) {
            builder.customerId = dict[@"customerId"];
            builder.firstName = dict[@"firstName"];
            builder.lastName = dict[@"lastName"];
            builder.fullName = dict[@"fullName"];
            builder.emailAddress = dict[@"emailAddress"];
        }];
    }

    return nil;
}

- (NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromInboxCampaigns:(NSArray<LLInboxCampaign *> *)campaigns {
    NSMutableArray *array = [NSMutableArray new];
    for (LLInboxCampaign *campaign in campaigns) {
        [array addObject:[LocalyticsPlugin dictionaryFromInboxCampaign:campaign]];
    }

    return [array copy];
}

+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromInboxCampaign:(LLInboxCampaign *)campaign {
    return @{
        // LLCampaignBase
        @"campaignId": @(campaign.campaignId),
        @"name": campaign.name,
        @"attributes": campaign.attributes ?: [NSNull null],

        // LLWebViewCampaign
        @"creativeFilePath": campaign.creativeFilePath ?: [NSNull null],

        // LLInboxCampaign
        @"read": @(campaign.isRead),
        @"title": campaign.titleText ?: [NSNull null],
        @"summary": campaign.summaryText ?: [NSNull null],
        @"thumbnailUrl": [campaign.thumbnailUrl absoluteString] ?: [NSNull null],
        @"hasCreative": @(campaign.hasCreative),
        @"sortOrder": @(campaign.sortOrder),
        @"receivedDate": @(campaign.receivedDate),
        @"deeplink": campaign.deepLinkURL ?: [NSNull null],
        @"isPushToInboxCampaign": @(campaign.isPushToInboxCampaign),
        @"deleted": @(campaign.isDeleted)
    };
}

+ (NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromRegions:(NSArray<LLRegion *> *)regions {
    NSMutableArray *array = [NSMutableArray new];
    for (LLRegion *region in regions) {
        if ([region isKindOfClass:[LLGeofence class]]) {
            [array addObject:[LocalyticsPlugin dictionaryFromGeofence:(LLGeofence *)region]];
        }
    }

    return [array copy];
}

+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromGeofence:(LLGeofence *)geofence {
    return @{
        @"uniqueId": geofence.region.identifier,
        @"latitude": @(geofence.region.center.latitude),
        @"longitude": @(geofence.region.center.longitude),
        @"name": geofence.name ?: [NSNull null],
        @"attributes": geofence.attributes ?: [NSNull null]
    };
}

- (NSArray<CLRegion *> *)regionsFromDictionaryArray:(NSArray<NSDictionary *> *)dictArray {
    NSMutableArray *array = [NSMutableArray new];
    for (NSDictionary *dict in dictArray) {
        [array addObject:[self regionFromDictionary:dict]];
    }

    return [array copy];
}

- (CLRegion *)regionFromDictionary:(NSDictionary *)dict {
    return [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(0.0, 0.0)
                                             radius:1
                                         identifier:dict[@"uniqueId"]];
}

- (LLRegionEvent)eventFrom:(NSString *)event {
    if ([@"enter" isEqualToString:event]) {
        return LLRegionEventEnter;
    } else {
        return LLRegionEventExit;
    }
}

+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromInAppCampaign:(LLInAppCampaign *)campaign {
    NSString *typeString = @"";
    switch (campaign.type) {
        case LLInAppMessageTypeTop:
            typeString = @"top";
            break;
        case LLInAppMessageTypeBottom:
            typeString = @"bottom";
            break;
        case LLInAppMessageTypeCenter:
            typeString = @"center";
            break;
        case LLInAppMessageTypeFull:
            typeString = @"full";
            break;
    }
    return @{
        // LLCampaignBase
        @"campaignId": @(campaign.campaignId),
        @"name": campaign.name,
        @"attributes": campaign.attributes ?: [NSNull null],

        // LLWebViewCampaign
        @"creativeFilePath": campaign.creativeFilePath ?: [NSNull null],

        // LLInAppCampaign
        @"type": typeString,
        @"isResponsive": @(campaign.isResponsive),
        @"aspectRatio": @(campaign.aspectRatio),
        @"offset": @(campaign.offset),
        @"backgroundAlpha": @(campaign.backgroundAlpha),
        @"dismissButtonHidden": @(campaign.isDismissButtonHidden),
        @"dismissButtonLocation": campaign.dismissButtonLocation == LLInAppMessageDismissButtonLocationLeft ? @"left" : @"right",
        @"eventName": campaign.eventName,
        @"eventAttributes": campaign.eventAttributes ?: [NSNull null]
    };
}

+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromPlacesCampaign:(LLPlacesCampaign *)campaign {
    return @{
        // LLCampaignBase
        @"campaignId": @(campaign.campaignId),
        @"name": campaign.name,
        @"attributes": campaign.attributes ?: [NSNull null],

        // LLPlacesCampaign
        @"message": campaign.message,
        @"soundFilename": campaign.soundFilename ?: [NSNull null],
        @"region": [LocalyticsPlugin dictionaryFromGeofence:(LLGeofence *)campaign.region],
        @"triggerEvent": campaign.event == LLRegionEventEnter ? @"enter" : @"exit"
    };
}

+ (LLInAppMessageDismissButtonLocation)locationFrom:(NSString *)location {
    if ([@"left" isEqualToString:location]) {
        return LLInAppMessageDismissButtonLocationLeft;
    } else {
        return LLInAppMessageDismissButtonLocationRight;
    }
}

- (NSMutableDictionary<NSNumber *, LLInAppCampaign *> *)inAppCampaignCache {
    if (_inAppCampaignCache == nil) {
        _inAppCampaignCache = [NSMutableDictionary new];
    }

    return _inAppCampaignCache;
}

- (NSMutableDictionary<NSNumber *, LLInboxCampaign *> *)inboxCampaignCache {
    if (_inboxCampaignCache == nil) {
        _inboxCampaignCache = [NSMutableDictionary new];
    }

    return _inboxCampaignCache;
}

- (NSMutableDictionary<NSNumber *, LLPlacesCampaign *> *)placesCampaignCache {
    if (_placesCampaignCache == nil) {
        _placesCampaignCache = [NSMutableDictionary new];
    }

    return _placesCampaignCache;
}

- (void)updateInboxCampaignCache {
    [self.commandDelegate runInBackground:^{
        for (LLInboxCampaign *campaign in [Localytics allInboxCampaigns]) {
            [self.inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }
    }];
}

#pragma mark Integration

- (void)integrate:(CDVInvokedUrlCommand *)command {
    [self logInput:@"integrate" withCommand:command];
    NSString *appKey = nil;
    NSDictionary *localyticsOptions = nil;

    if ([command argumentAtIndex:0]) {
        appKey = [command argumentAtIndex:0];
    } else {
        appKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LocalyticsAppKey"];
    }

    if ([command argumentAtIndex:1]) {
        localyticsOptions = [command argumentAtIndex:1];
    } else {
        NSLog(@"Localytics Cordova wrapper found no options in integrate call. Using defaults.");
    }

    if (appKey) {
      [Localytics setOptions:@{@"plugin_library": PLUGIN_VERSION}];
      [Localytics integrate:appKey withLocalyticsOptions:localyticsOptions];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
      NSLog(@"Localytics Cordova wrapper can't integrate. No App Key found.");
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)autoIntegrate:(CDVInvokedUrlCommand *)command {
    [self logInput:@"autoIntegrate" withCommand:command];
    NSString *appKey = nil;
    NSDictionary *localyticsOptions = nil;

    if ([command argumentAtIndex:0]) {
        appKey = [command argumentAtIndex:0];
    } else {
        appKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LocalyticsAppKey"];
    }

    if ([command argumentAtIndex:1]) {
      localyticsOptions = [command argumentAtIndex:1];
    } else {
      NSLog(@"Localytics Cordova wrapper can't integrate. No App Key found.");
    }

    if (appKey) {
      [Localytics setOptions:@{@"plugin_library": PLUGIN_VERSION}];
      [Localytics autoIntegrate:appKey withLocalyticsOptions:localyticsOptions launchOptions:nil];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
      NSLog(@"Localytics Cordova wrapper can't integrate. No App Key found.");
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)openSession:(CDVInvokedUrlCommand *)command {
    [self logInput:@"openSession" withCommand:command];
    [Localytics openSession];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)closeSession:(CDVInvokedUrlCommand *)command {
    [self logInput:@"closeSession" withCommand:command];
    [Localytics closeSession];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)upload:(CDVInvokedUrlCommand *)command {
    [self logInput:@"upload" withCommand:command];
    [Localytics upload];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pauseDataUploading:(CDVInvokedUrlCommand *)command {
    [self logInput:@"pauseDataUploading" withCommand:command];
    NSNumber *pause = [command argumentAtIndex:0];
    if ([pause isKindOfClass:[NSNumber class]]) {
      [Localytics pauseDataUploading:[pause boolValue]];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
      NSLog(@"Localytics Cordova wrapper received bad input in call to pauseDataUploading.");
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


#pragma mark Analytics

- (void)setOptedOut:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setOptedOut" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
      [Localytics setOptedOut:[enabled boolValue]];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
      NSLog(@"Localytics Cordova wrapper received bad input in call to setOptedOut.");
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)isOptedOut:(CDVInvokedUrlCommand *)command {
    [self logInput:@"isOptedOut" withCommand:command];
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isOptedOut];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setPrivacyOptedOut:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setPrivacyOptedOut" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
      [Localytics setPrivacyOptedOut:[enabled boolValue]];
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
      NSLog(@"Localytics Cordova wrapper received bad input in call to setPrivacyOptedOut.");
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)isPrivacyOptedOut:(CDVInvokedUrlCommand *)command {
    [self logInput:@"isPrivacyOptedOut" withCommand:command];
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isPrivacyOptedOut];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)tagEvent:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagEvent" withCommand:command];
    if ([command.arguments count] == 3) {
        NSString *eventName = [command argumentAtIndex:0];
        NSDictionary *attributes = [command argumentAtIndex:1];
        NSNumber *customerValueIncrease = [command argumentAtIndex:2];

        if ([eventName isKindOfClass:[NSString class]] && eventName.length > 0) {
            [Localytics tagEvent:eventName attributes:attributes customerValueIncrease:customerValueIncrease];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to tagEvent; Event name is invalid.");
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
}

- (void)tagPurchased:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagPurchased" withCommand:command];
    if ([command.arguments count] == 5) {
        NSString *itemName = [command argumentAtIndex:0];
        NSString *itemId = [command argumentAtIndex:1];
        NSString *itemType = [command argumentAtIndex:2];
        NSNumber *itemPrice = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagPurchased:itemName itemId:itemId itemType:itemType itemPrice:itemPrice attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagPurchased; 5 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagAddedToCart:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagAddedToCart" withCommand:command];
    if ([command.arguments count] == 5) {
        NSString *itemName = [command argumentAtIndex:0];
        NSString *itemId = [command argumentAtIndex:1];
        NSString *itemType = [command argumentAtIndex:2];
        NSNumber *itemPrice = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagAddedToCart:itemName itemId:itemId itemType:itemType itemPrice:itemPrice attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagAddedToCart; 5 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagStartedCheckout:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagStartedCheckout" withCommand:command];
    if ([command.arguments count] == 3) {
        NSNumber *totalPrice = [command argumentAtIndex:0];
        NSNumber *itemCount = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagStartedCheckout:totalPrice itemCount:itemCount attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagStartedCheckout; 3 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagCompletedCheckout:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagCompletedCheckout" withCommand:command];
    if ([command.arguments count] == 3) {
        NSNumber *totalPrice = [command argumentAtIndex:0];
        NSNumber *itemCount = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagCompletedCheckout:totalPrice itemCount:itemCount attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagCompletedCheckout; 3 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagContentViewed:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagContentViewed" withCommand:command];
    if ([command.arguments count] == 4) {
        NSString *contentName = [command argumentAtIndex:0];
        NSString *contentId = [command argumentAtIndex:1];
        NSString *contentType = [command argumentAtIndex:2];
        NSDictionary *attributes = [command argumentAtIndex:3];
        [Localytics tagContentViewed:contentName contentId:contentId contentType:contentType attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagContentViewed; 4 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagSearched:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagSearched" withCommand:command];
    if ([command.arguments count] == 4) {
        NSString *queryText = [command argumentAtIndex:0];
        NSString *contentType = [command argumentAtIndex:1];
        NSNumber *resultCount = [command argumentAtIndex:2];
        NSDictionary *attributes = [command argumentAtIndex:3];
        [Localytics tagSearched:queryText contentType:contentType resultCount:resultCount attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagSearched; 4 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagShared:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagShared" withCommand:command];
    if ([command.arguments count] == 5) {
        NSString *contentName = [command argumentAtIndex:0];
        NSString *contentId = [command argumentAtIndex:1];
        NSString *contentType = [command argumentAtIndex:2];
        NSString *methodName = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagShared:contentName contentId:contentId contentType:contentType methodName:methodName attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagShared; 5 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagContentRated:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagContentRated" withCommand:command];
    if ([command.arguments count] == 5) {
        NSString *contentName = [command argumentAtIndex:0];
        NSString *contentId = [command argumentAtIndex:1];
        NSString *contentType = [command argumentAtIndex:2];
        NSNumber *rating = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagContentRated:contentName contentId:contentId contentType:contentType rating:rating attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagContentRated; 5 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagCustomerRegistered:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagCustomerRegistered" withCommand:command];
    if ([command.arguments count] == 3) {
        LLCustomer *customer = [self customerFrom:[command argumentAtIndex:0]];
        NSString *methodName = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagCustomerRegistered:customer methodName:methodName attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagCustomerRegistered; 3 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagCustomerLoggedIn:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagCustomerLoggedIn" withCommand:command];
    if ([command.arguments count] == 3) {
        LLCustomer *customer = [self customerFrom:[command argumentAtIndex:0]];
        NSString *methodName = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagCustomerLoggedIn:customer methodName:methodName attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagCustomerLoggedIn; 3 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagCustomerLoggedOut:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagCustomerLoggedOut" withCommand:command];
    NSDictionary *attributes = [command argumentAtIndex:0];
    [Localytics tagCustomerLoggedOut:attributes];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)tagInvited:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagInvited" withCommand:command];
    if ([command.arguments count] == 2) {
        NSString *methodName = [command argumentAtIndex:0];
        NSDictionary *attributes = [command argumentAtIndex:1];
        [Localytics tagInvited:methodName attributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagInvited; 2 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagInAppImpression:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagInAppImpression" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        LLInAppCampaign *campaign = self.inAppCampaignCache[@([campaignId integerValue])];
        if (campaign) {
            NSString *impressionType = [command argumentAtIndex:1];
            if ([@"click" isEqualToString:impressionType]) {
                [Localytics tagImpressionForInAppCampaign:campaign withType:LLImpressionTypeClick];
            } else if ([@"dismiss" isEqualToString:impressionType]) {
                [Localytics tagImpressionForInAppCampaign:campaign withType:LLImpressionTypeDismiss];
            } else {
                [Localytics tagImpressionForInAppCampaign:campaign withCustomAction:impressionType];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to tagInAppImpression; No campaign found matching ID.");
        }
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagInAppImpression; 2 arguments required.");
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)tagInboxImpression:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagInboxImpression" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
        if (campaign) {
            NSString *impressionType = [command argumentAtIndex:1];
            if ([@"click" isEqualToString:impressionType]) {
                [Localytics tagImpressionForInboxCampaign:campaign withType:LLImpressionTypeClick];
            } else if ([@"dismiss" isEqualToString:impressionType]) {
                [Localytics tagImpressionForInboxCampaign:campaign withType:LLImpressionTypeDismiss];
            } else {
                [Localytics tagImpressionForInboxCampaign:campaign withCustomAction:impressionType];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to tagInboxImpression; No campaign found matching ID.");
        }
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagInboxImpression; 2 arguments required.");
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)tagPushToInboxImpression:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagPushToInboxImpression" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        NSNumber *success = [command argumentAtIndex:1];
        LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
        if (campaign && [success isKindOfClass:[NSNumber class]]) {
            [Localytics tagImpressionForPushToInboxCampaign:campaign success:[success boolValue]];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to tagPushToInboxImpression; Campaign not found or success is of incorrect type.");
        }
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagPushToInboxImpression; 2 arguments required.");
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)tagPlacesPushReceived:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagPlacesPushReceived" withCommand:command];
    NSNumber *campaignId = [command argumentAtIndex:0];
    LLPlacesCampaign *campaign = self.placesCampaignCache[@([campaignId integerValue])];
    if (campaign) {
        [Localytics tagPlacesPushReceived:campaign];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagPlacesPushReceived; Campaign not found.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)tagPlacesPushOpened:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagPlacesPushOpened" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        NSString *action = [command argumentAtIndex:1];
        LLPlacesCampaign *campaign = self.placesCampaignCache[@([campaignId integerValue])];
        if (campaign) {
            if (action) {
                [Localytics tagPlacesPushOpened:campaign withActionIdentifier:action];
            } else {
                [Localytics tagPlacesPushOpened:campaign];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to tagPlacesPushOpened; Campaign not found.");
        }
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagPlacesPushOpened; 2 arguments required.");
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)tagScreen:(CDVInvokedUrlCommand *)command {
    [self logInput:@"tagScreen" withCommand:command];
    NSString *screenName = [command argumentAtIndex:0];
    if ([screenName length] > 0) {
        [Localytics tagScreen:screenName];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to tagScreen; Screen name must not be empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setCustomDimension:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomDimension" withCommand:command];
    NSNumber *dimension = [command argumentAtIndex:0];
    NSString *value = [command argumentAtIndex:1];
    if ([dimension isKindOfClass:[NSNumber class]]) {
        [Localytics setValue:value forCustomDimension:[dimension intValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setCustomDimension; dimension must be a Number.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getCustomDimension:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getCustomDimension" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSNumber *dimension = [command argumentAtIndex:0];
        NSString *value = [Localytics valueForCustomDimension: [dimension intValue]];

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setAnalyticsListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setAnalyticsListener" withCommand:command];
    self.analyticsDelegate = [[CDAnalyticsDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                                invokedUrlCommand:command];
    [Localytics setAnalyticsDelegate:self.analyticsDelegate];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeAnalyticsListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"removeAnalyticsListener" withCommand:command];
    self.analyticsDelegate = nil;
    [Localytics setAnalyticsDelegate:nil];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark Profiles

- (void)setProfileAttribute:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setProfileAttribute" withCommand:command];
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSObject<NSCopying> *value = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics setValue:value forProfileAttribute:attribute withScope:scope];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setProfileAttribute; attribute must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)addProfileAttributesToSet:(CDVInvokedUrlCommand *)command {
    [self logInput:@"addProfileAttributesToSet" withCommand:command];
    NSString *attribute = [command argumentAtIndex:0];

    if ([attribute length] > 0) {
        NSArray *values = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics addValues:values toSetForProfileAttribute:attribute withScope:scope];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to addProfileAttributesToSet; attribute must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)removeProfileAttributesFromSet:(CDVInvokedUrlCommand *)command {
    [self logInput:@"removeProfileAttributesFromSet" withCommand:command];
    NSString *attribute = [command argumentAtIndex:0];

    if ([attribute length] > 0) {
        NSArray *values = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics removeValues:values fromSetForProfileAttribute:attribute withScope:scope];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to removeProfileAttributesToSet; attribute must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)incrementProfileAttribute:(CDVInvokedUrlCommand *)command {
    [self logInput:@"incrementProfileAttribute" withCommand:command];
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSInteger value = [[command argumentAtIndex:1 withDefault:0] intValue];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics incrementValueBy:value forProfileAttribute:attribute withScope:scope];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to incrementProfileAttribute; attribute must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}

- (void)decrementProfileAttribute:(CDVInvokedUrlCommand *)command {
    [self logInput:@"decrementProfileAttribute" withCommand:command];
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSInteger value = [[command argumentAtIndex:1 withDefault:0] intValue];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics decrementValueBy:value forProfileAttribute:attribute withScope:scope];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to decrementProfileAttribute; attribute must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)deleteProfileAttribute:(CDVInvokedUrlCommand *)command {
    [self logInput:@"deleteProfileAttribute" withCommand:command];
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:1]];

        [Localytics deleteProfileAttribute:attribute withScope:scope];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to deleteProfileAttribute; attribute must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setCustomerEmail:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomerEmail" withCommand:command];
    NSString *email = [command argumentAtIndex:0];
    [Localytics setCustomerEmail:email];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCustomerFirstName:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomerFirstName" withCommand:command];
    NSString *firstName = [command argumentAtIndex:0];
    [Localytics setCustomerFirstName:firstName];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCustomerLastName:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomerLastName" withCommand:command];
    NSString *lastName = [command argumentAtIndex:0];
    [Localytics setCustomerLastName:lastName];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCustomerFullName:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomerFullName" withCommand:command];
    NSString *fullName = [command argumentAtIndex:0];
    [Localytics setCustomerFullName:fullName];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark Customer Information

- (void)setIdentifier:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setIdentifier" withCommand:command];
    NSString *identifier = [command argumentAtIndex:0];
    NSString *value = [command argumentAtIndex:1];
    if ([identifier length] > 0) {
        [Localytics setValue:value forIdentifier:identifier];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setIdentifier; identifier must be non-empty.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getIdentifier:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getIdentifier" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSString *identifier = [command argumentAtIndex:0];
        NSString *value = [Localytics valueForIdentifier:identifier];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setCustomerId:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomerId" withCommand:command];
    NSString *customerId = [command argumentAtIndex:0];
    [Localytics setCustomerId:customerId];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCustomerIdWithPrivacyOptedOut:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCustomerIdWithPrivacyOptedOut" withCommand:command];
    NSString *customerId = [command argumentAtIndex:0];
    NSNumber *optedOut = [command argumentAtIndex:1];

    [Localytics setCustomerId:customerId privacyOptedOut:[optedOut boolValue]];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getCustomerId:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getCustomerId" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics customerId];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setLocation:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setLocation" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *latitude = [command argumentAtIndex:0];
        NSNumber *longitude = [command argumentAtIndex:1];
        CLLocationCoordinate2D location;
        location.latitude = latitude.doubleValue;
        location.longitude = longitude.doubleValue;
        [Localytics setLocation:location];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setLocation; 2 arguments required.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


#pragma mark Marketing

- (void)registerPush:(CDVInvokedUrlCommand *)command {
    [self logInput:@"registerPush" withCommand:command];
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        NSLog(@"Localytics Cordova wrapper found UserNotifications framework, registering with UserNotifications.");
        UNAuthorizationOptions options = (UNAuthorizationOptionBadge | UNAuthorizationOptionSound |UNAuthorizationOptionAlert);
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options
                                                                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                                                                [Localytics didRequestUserNotificationAuthorizationWithOptions:options
                                                                                                                                       granted:granted];
                                                                            }];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        NSLog(@"Localytics Cordova wrapper couldn't find UserNotifications framework, registering with registerUserNotificationSettings:.");
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setPushToken:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setPushToken" withCommand:command];
    NSString *pushToken = [command argumentAtIndex:0];
    if (pushToken) {
        if (pushToken.length % 2) {
            pushToken = [NSString stringWithFormat:@"0%@", pushToken];
        }
        NSMutableData *deviceToken = [NSMutableData data];
        for (int i = 0; i < pushToken.length; i += 2) {
            unsigned value;
            NSScanner *scanner = [NSScanner scannerWithString:[pushToken substringWithRange:NSMakeRange(i, 2)]];
            [scanner scanHexInt:&value];
            uint8_t byte = value;
            [deviceToken appendBytes:&byte length:1];
        }
        [Localytics setPushToken:deviceToken];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setPushToken; pushToken was nil.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getPushToken:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getPushToken" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics pushToken];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setNotificationsDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)areNotificationsDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setPushMessageConfiguration:(CDVInvokedUrlCommand *)command {
    // No-Op
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setTestModeEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setTestModeEnabled" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setTestModeEnabled:[enabled boolValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setTestModeEnabled; Enabled is of wrong type.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)isTestModeEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"isTestModeEnabled" withCommand:command];
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isTestModeEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setInAppMessageDismissButtonImageWithName:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInAppMessageDismissButtonImageWithName" withCommand:command];
    NSString *imageName = [command argumentAtIndex:0];
    [Localytics setInAppMessageDismissButtonImageWithName:imageName];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setInAppMessageDismissButtonHidden:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInAppMessageDismissButtonHidden" withCommand:command];
    NSNumber *hidden = [command argumentAtIndex:0];
    if ([hidden isKindOfClass:[NSNumber class]]) {
        [Localytics setInAppMessageDismissButtonHidden:[hidden boolValue]];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setInAppMessageDismissButtonHidden; Enabled is of wrong type.");
    }
}

- (void)setInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInAppMessageDismissButtonLocation" withCommand:command];
    NSString *value = [command argumentAtIndex:0];
    if (value) {
        [Localytics setInAppMessageDismissButtonLocation:[self getDismissButtonLocation:value]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setInAppMessageDismissButtonLocation; Argument is nil.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getInAppMessageDismissButtonLocation" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSString *value = [self fromDismissButtonLocation:[Localytics inAppMessageDismissButtonLocation]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)triggerInAppMessage:(CDVInvokedUrlCommand *)command {
    [self logInput:@"triggerInAppMessage" withCommand:command];
    NSString *triggerName = [command argumentAtIndex:0];
    NSDictionary *attributes = [command argumentAtIndex:1];

    if ([triggerName isKindOfClass:[NSString class]] && [triggerName length] > 0) {
        [Localytics triggerInAppMessage:triggerName withAttributes:attributes];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to triggerInAppMessage; the first argument must be a non-empty String.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)triggerInAppMessagesForSessionStart:(CDVInvokedUrlCommand *)command {
    [self logInput:@"triggerInAppMessagesForSessionStart" withCommand:command];
    [Localytics triggerInAppMessagesForSessionStart];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)dismissCurrentInAppMessage:(CDVInvokedUrlCommand *)command {
    [self logInput:@"dismissCurrentInAppMessage" withCommand:command];
    [Localytics dismissCurrentInAppMessage];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setInAppMessageConfiguration:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInAppMessageConfiguration" withCommand:command];
    if (self.messagingDelegate) {
        self.messagingDelegate.inAppConfig = [command argumentAtIndex:0];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received call to setInAppMessageConfiguration but no messaging delegate is initialized.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)isInAppAdIdParameterEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"isInAppAdIdParameterEnabled" withCommand:command];
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isInAppAdIdParameterEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setInAppAdIdParameterEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInAppAdIdParameterEnabled" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setInAppAdIdParameterEnabled:[enabled boolValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received call to setInAppAdIdParameterEnabled but argument is of the wrong type.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)isInboxAdIdParameterEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"isInboxAdIdParameterEnabled" withCommand:command];
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isInboxAdIdParameterEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setInboxAdIdParameterEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInboxAdIdParameterEnabled" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setInboxAdIdParameterEnabled:[enabled boolValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received call to setInboxAdIdParameterEnabled but argument is of the wrong type.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getInboxCampaigns:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getInboxCampaigns" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSArray<LLInboxCampaign *> *inboxCampaigns = [Localytics inboxCampaigns];

        // Cache campaigns
        for (LLInboxCampaign *campaign in inboxCampaigns) {
            [self.inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }

        NSArray *value = [self dictionaryArrayFromInboxCampaigns:inboxCampaigns];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getDisplayableInboxCampaigns:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getDisplayableInboxCampaigns" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSArray<LLInboxCampaign *> *inboxCampaigns = [Localytics displayableInboxCampaigns];

        // Cache campaigns
        for (LLInboxCampaign *campaign in inboxCampaigns) {
            [self.inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }

        NSArray *value = [self dictionaryArrayFromInboxCampaigns:inboxCampaigns];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getAllInboxCampaigns:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getAllInboxCampaigns" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSArray<LLInboxCampaign *> *inboxCampaigns = [Localytics allInboxCampaigns];

        // Cache campaigns
        for (LLInboxCampaign *campaign in inboxCampaigns) {
            [self.inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }

        NSArray *value = [self dictionaryArrayFromInboxCampaigns:inboxCampaigns];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)refreshInboxCampaigns:(CDVInvokedUrlCommand *)command {
    [self logInput:@"refreshInboxCampaigns" withCommand:command];
    [Localytics refreshInboxCampaigns:^(NSArray<LLInboxCampaign *> *inboxCampaigns) {

        // Cache campaigns
        for (LLInboxCampaign *campaign in inboxCampaigns) {
            [self.inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }

        NSArray *value = [self dictionaryArrayFromInboxCampaigns:inboxCampaigns];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)refreshAllInboxCampaigns:(CDVInvokedUrlCommand *)command {
    [self logInput:@"refreshAllInboxCampaigns" withCommand:command];
    [Localytics refreshAllInboxCampaigns:^(NSArray<LLInboxCampaign *> *inboxCampaigns) {

        // Cache campaigns
        for (LLInboxCampaign *campaign in inboxCampaigns) {
            [self.inboxCampaignCache setObject:campaign forKey:@(campaign.campaignId)];
        }

        NSArray *value = [self dictionaryArrayFromInboxCampaigns:inboxCampaigns];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setInboxCampaignRead:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setInboxCampaignRead" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        NSNumber *enabled = [command argumentAtIndex:1];
        if ([enabled isKindOfClass:[NSNumber class]]) {
            LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
            if (campaign) {
                [Localytics setInboxCampaign:campaign asRead:[enabled boolValue]];
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                NSLog(@"Localytics Cordova wrapper received bad input in call to setInboxCampaignRead; Campaign ID didn't map to any campaigns.");
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            [self updateInboxCampaignCache];
            return;
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to setInboxCampaignRead; second argument is of wrong type.");
        }
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to setInboxCampaignRead; 2 arguments expected.");
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)deleteInboxCampaign:(CDVInvokedUrlCommand *)command {
    [self logInput:@"deleteInboxCampaign" withCommand:command];
    if ([command.arguments count] == 1) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
        if (campaign) {
            [Localytics deleteInboxCampaign:campaign];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            NSLog(@"Localytics Cordova wrapper received bad input in call to setInboxCampaignRead; Campaign ID didn't map to any campaigns.");
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
        [self updateInboxCampaignCache];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to deleteInboxCampaign; 1 arguments expected.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getInboxCampaignsUnreadCount:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getInboxCampaignsUnreadCount" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSInteger value = [Localytics inboxCampaignsUnreadCount];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSInteger:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)inboxListItemTapped:(CDVInvokedUrlCommand *)command {
    [self logInput:@"inboxListItemTapped" withCommand:command];
    NSNumber *campaignId = [command argumentAtIndex:0];
    LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
    if (campaign) {
        [Localytics inboxListItemTapped:campaign];
        [self updateInboxCampaignCache];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to inboxListItemTapped; Campaign ID didn't map to any campaigns.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)triggerPlacesNotification:(CDVInvokedUrlCommand *)command {
    [self logInput:@"triggerPlacesNotification" withCommand:command];
    NSNumber *campaignId = [command argumentAtIndex:0];
    LLPlacesCampaign *campaign = self.placesCampaignCache[@([campaignId integerValue])];
    if (campaign) {
        [Localytics triggerPlacesNotificationForCampaign:campaign];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input in call to triggerPlacesNotification; Campaign ID didn't map to any campaigns.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setPlacesMessageConfiguration:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setPlacesMessageConfiguration" withCommand:command];
    if (self.messagingDelegate) {
        self.messagingDelegate.placesConfig = [command argumentAtIndex:0];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received call to setPlacesMessageConfiguration but no messaging delegate is initialized.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setMessagingListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setMessagingListener" withCommand:command];
    self.messagingDelegate = [[CDMessagingDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                                invokedUrlCommand:command
                                                               inAppCampaignCache:self.inAppCampaignCache
                                                              placesCampaignCache:self.placesCampaignCache];
    [Localytics setMessagingDelegate:self.messagingDelegate];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeMessagingListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"removeMessagingListener" withCommand:command];
    self.messagingDelegate = nil;
    [Localytics setMessagingDelegate:nil];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark Location

- (void)setLocationMonitoringEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setLocationMonitoringEnabled" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    NSNumber *persist = [command argumentAtIndex:1];
    if ([persist isKindOfClass:[NSNumber class]]) {
        [Localytics persistLocationMonitoring:persist];
    }
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setLocationMonitoringEnabled:[enabled boolValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input to setLocationMonitoringEnabled; argument is of the wrong type.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)persistLocationMonitoring:(CDVInvokedUrlCommand *)command {
    [self logInput:@"persistLocationMonitoring" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics persistLocationMonitoring:[enabled boolValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input to persistLocationMonitoring; argument is of the wrong type.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getGeofencesToMonitor:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getGeofencesToMonitor" withCommand:command];
    if ([command.arguments count] == 2) {
        NSNumber *latitude = [command argumentAtIndex:0];
        NSNumber *longitude = [command argumentAtIndex:1];
        [self.commandDelegate runInBackground:^{
            NSArray<LLRegion *> *geofences = [Localytics geofencesToMonitor:CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue])];
            NSArray *value = [LocalyticsPlugin dictionaryArrayFromRegions:geofences];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input to getGeofencesToMonitor; expected 2 arguments.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)triggerRegion:(CDVInvokedUrlCommand *)command {
    [self logInput:@"triggerRegion" withCommand:command];
    if ([command.arguments count] >= 2) {
        NSDictionary *region = [command argumentAtIndex:0];
        NSString *event = [command argumentAtIndex:1];
        if ([command argumentAtIndex:2] && [command argumentAtIndex:3]) {
          NSNumber *latitude = [command argumentAtIndex:2];
          NSNumber *longitude = [command argumentAtIndex:3];
          CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue
                                                            longitude:longitude.doubleValue];
          [Localytics triggerRegion:[self regionFromDictionary:region] withEvent:[self eventFrom:event] atLocation:location];
        } else {
          NSLog(@"Localytics Cordova wrapper couldn't determine a location for call to triggerRegion. Defaulting to nil");
          [Localytics triggerRegion:[self regionFromDictionary:region] withEvent:[self eventFrom:event] atLocation:nil];
        }
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input to triggerRegion; expected 2 or 4 arguments.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)triggerRegions:(CDVInvokedUrlCommand *)command {
    [self logInput:@"triggerRegions" withCommand:command];
    if ([command.arguments count] >= 2) {
        NSArray *regions = [command argumentAtIndex:0];
        NSString *event = [command argumentAtIndex:1];
        if ([command argumentAtIndex:2] && [command argumentAtIndex:3]) {
          NSNumber *latitude = [command argumentAtIndex:2];
          NSNumber *longitude = [command argumentAtIndex:3];
          CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue
                                                            longitude:longitude.doubleValue];
          [Localytics triggerRegions:[self regionsFromDictionaryArray:regions] withEvent:[self eventFrom:event] atLocation:location];
        } else {
          NSLog(@"Localytics Cordova wrapper couldn't determine a location for call to triggerRegions. Defaulting to nil");
          [Localytics triggerRegions:[self regionsFromDictionaryArray:regions] withEvent:[self eventFrom:event] atLocation:nil];
        }
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input for call to triggerRegions. expected 2 or 4 arguments");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setLocationListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setLocationListener" withCommand:command];
    self.locationDelegate = [[CDLocationDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                              invokedUrlCommand:command];
    [Localytics setLocationDelegate:self.locationDelegate];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeLocationListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"removeLocationListener" withCommand:command];
    self.locationDelegate = nil;
    [Localytics setLocationDelegate:nil];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCallToActionListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setCallToActionListener" withCommand:command];
    if (!self.ctaDelegate) {
        self.ctaDelegate = [CDCTADelegate new];
        [Localytics setCallToActionDelegate:self.ctaDelegate];
    }
    self.ctaDelegate.commandDelegate = self.commandDelegate;
    self.ctaDelegate.invokedUrlCommand = command;
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeCallToActionListener:(CDVInvokedUrlCommand *)command {
    [self logInput:@"removeCallToActionListener" withCommand:command];
    self.ctaDelegate.commandDelegate = nil;
    self.ctaDelegate.invokedUrlCommand = nil;
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark Developer Options

- (void)setLoggingEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setLoggingEnabled" withCommand:command];
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setLoggingEnabled:[enabled boolValue]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    
}

- (void)enableLiveDeviceLogging:(CDVInvokedUrlCommand *)command {
    [self logInput:@"enableLiveDeviceLogging" withCommand:command];
    [Localytics enableLiveDeviceLogging];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isLoggingEnabled:(CDVInvokedUrlCommand *)command {
    [self logInput:@"isLoggingEnabled" withCommand:command];
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isLoggingEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setOptions:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setOptions" withCommand:command];
    NSDictionary *options = [command argumentAtIndex:0];
    [Localytics setOptions:options];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setOption:(CDVInvokedUrlCommand *)command {
    [self logInput:@"setOption" withCommand:command];
    if ([command.arguments count] == 2) {
        NSString *key = [command argumentAtIndex:0];
        NSObject *value = [command argumentAtIndex:1];
        [Localytics setOptions:@{key: value}];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSLog(@"Localytics Cordova wrapper received bad input to setOption; expected 2 arguments.");
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)redirectLogsToDisk:(CDVInvokedUrlCommand *)command {
    [self logInput:@"redirectLogsToDisk" withCommand:command];
    [Localytics redirectLoggingToDisk];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getInstallId:(CDVInvokedUrlCommand *)command {
    [self logInput:@"getInstallId" withCommand:command];
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics installId];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getAppKey:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics appKey];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getLibraryVersion:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics libraryVersion];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)logInput:(NSString *)call withCommand:(CDVInvokedUrlCommand *)command {
    NSLog(@"Localytics Cordova wrapper invoked with action %@ and arguments %@", call, [command arguments]);
}

@end
