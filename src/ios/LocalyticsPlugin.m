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

@import UserNotifications;
@import Localytics;

#define PROFILE_SCOPE_ORG @"org"
#define PROFILE_SCOPE_APP @"app"

static BOOL localyticsIsAutoIntegrate = NO;
static BOOL localyticsDidReceiveRemoteNotificationSwizzled = NO;
static BOOL localyticsDidReceiveRemoteNotificationFetchCompletionHandlerSwizzled = NO;
static BOOL localyticsDidRegisterForRemoteNotificationsWithDeviceTokenSwizzled = NO;
static BOOL localyticsDidFailToRegisterForRemoteNotificationWithErrorSwizzled = NO;
static BOOL localyticsHandleOpenURLSwizzled = NO;
static BOOL localyticsOpenURLSourceApplicationAnnotationSwizzled = NO;
static BOOL localyticsOpenURLOptionsSwizzled = NO;
static BOOL localyticsHandleActionWithIdentifierForRemoteNotificationCompletionHandlerSwizzled = NO;
static BOOL localyticsHandleActionWithIdentifierForRemoteNotificationWithResponseInfoCompletionHandlerSwizzled = NO;
static BOOL localyticsHandleActionWithIdentifierForLocalNotificationCompletionHandlerSwizzled = NO;
static BOOL localyticsHandleActionWithIdentifierForLocalNotificationWithResponseInfoCompletionHandlerSwizzled = NO;
static BOOL localyticsDidReceiveLocalNotificationSwizzled = NO;
static BOOL localyticsDidRegisterUserNotificationSettingsSwizzled = NO;

BOOL MethodSwizzle(Class clazz, SEL originalSelector, SEL overrideSelector) {
    // Code by example from http://nshipster.com/method-swizzling/
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method overrideMethod = class_getInstanceMethod(clazz, overrideSelector);

    if (class_addMethod(clazz, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(clazz, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        return NO;
    } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
    return YES;
}


#pragma mark AppDelegate+LLPushNotification implementation

@implementation AppDelegate (LLPushNotification)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = [self class];

        localyticsDidReceiveRemoteNotificationSwizzled = MethodSwizzle(clazz, @selector(application:didReceiveRemoteNotification:), @selector(localytics_swizzled_Application:didReceiveRemoteNotification:));
        localyticsDidReceiveRemoteNotificationFetchCompletionHandlerSwizzled = MethodSwizzle(clazz, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:), @selector(localytics_swizzled_Application:didReceiveRemoteNotification:fetchCompletionHandler:));
        localyticsDidRegisterForRemoteNotificationsWithDeviceTokenSwizzled = MethodSwizzle(clazz, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), @selector(localytics_swizzled_Application:didRegisterForRemoteNotificationsWithDeviceToken:));
        localyticsDidFailToRegisterForRemoteNotificationWithErrorSwizzled = MethodSwizzle(clazz, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), @selector(localytics_swizzled_Application:didFailToRegisterForRemoteNotificationsWithError:));
        localyticsDidRegisterUserNotificationSettingsSwizzled = MethodSwizzle(clazz, @selector(application:didRegisterUserNotificationSettings:), @selector(localytics_swizzled_Application:didRegisterUserNotificationSettings:));
        localyticsHandleOpenURLSwizzled = MethodSwizzle(clazz, @selector(application:handleOpenURL:), @selector(localytics_swizzled_Application:handleOpenURL:));
        localyticsOpenURLSourceApplicationAnnotationSwizzled = MethodSwizzle(clazz, @selector(application:openURL:sourceApplication:annotation:), @selector(localytics_swizzled_Application:openURL:sourceApplication:annotation:));
        localyticsOpenURLOptionsSwizzled = MethodSwizzle(clazz, @selector(application:openURL:options:), @selector(localytics_swizzled_Application:openURL:options:));
        localyticsHandleActionWithIdentifierForRemoteNotificationCompletionHandlerSwizzled = MethodSwizzle(clazz, @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:), @selector(localytics_swizzled_Application:handleActionWithIdentifier:forRemoteNotification:completionHandler:));
        localyticsHandleActionWithIdentifierForRemoteNotificationWithResponseInfoCompletionHandlerSwizzled = MethodSwizzle(clazz, @selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:), @selector(localytics_swizzled_Application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:));
        localyticsHandleActionWithIdentifierForLocalNotificationCompletionHandlerSwizzled = MethodSwizzle(clazz, @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:), @selector(localytics_swizzled_Application:handleActionWithIdentifier:forLocalNotification:completionHandler:));
        localyticsHandleActionWithIdentifierForLocalNotificationWithResponseInfoCompletionHandlerSwizzled = MethodSwizzle(clazz, @selector(application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:), @selector(localytics_swizzled_Application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:));
        localyticsDidReceiveLocalNotificationSwizzled = MethodSwizzle(clazz, @selector(application:didReceiveLocalNotification:), @selector(localytics_swizzled_Application:didReceiveLocalNotification:));
    });
}

- (void)localytics_swizzled_Application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [Localytics handleNotification:userInfo];

    if (localyticsDidReceiveRemoteNotificationSwizzled) {
        [self localytics_swizzled_Application:application didReceiveRemoteNotification:userInfo];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [Localytics handleNotification:userInfo];
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }

    if (localyticsDidReceiveRemoteNotificationFetchCompletionHandlerSwizzled) {
        [self localytics_swizzled_Application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    [Localytics handleNotification:userInfo withActionIdentifier:identifier];
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }

    if (localyticsHandleActionWithIdentifierForRemoteNotificationCompletionHandlerSwizzled) {
        [self localytics_swizzled_Application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    [Localytics handleNotification:userInfo withActionIdentifier:identifier];
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }

    if (localyticsHandleActionWithIdentifierForRemoteNotificationWithResponseInfoCompletionHandlerSwizzled) {
        [self localytics_swizzled_Application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    [Localytics handleNotification:notification.userInfo withActionIdentifier:identifier];
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }

    if (localyticsHandleActionWithIdentifierForLocalNotificationCompletionHandlerSwizzled) {
        [self localytics_swizzled_Application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    [Localytics handleNotification:notification.userInfo withActionIdentifier:identifier];
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }

    if (localyticsHandleActionWithIdentifierForLocalNotificationWithResponseInfoCompletionHandlerSwizzled) {
        [self localytics_swizzled_Application:application handleActionWithIdentifier:identifier forLocalNotification:notification withResponseInfo:responseInfo completionHandler:completionHandler];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [Localytics handleNotification:notification.userInfo];

    if (localyticsDidReceiveLocalNotificationSwizzled) {
        [self localytics_swizzled_Application:application didReceiveLocalNotification:notification];
    }
}

- (void)localytics_swizzled_Application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    if (!localyticsIsAutoIntegrate) {
        [Localytics setPushToken:deviceToken];
    }
    if (localyticsDidRegisterForRemoteNotificationsWithDeviceTokenSwizzled) {
        [self localytics_swizzled_Application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)localytics_swizzled_Application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    NSLog(@"onRemoteRegisterFail: %@", [error description]);
    if (localyticsDidFailToRegisterForRemoteNotificationWithErrorSwizzled) {
        [self localytics_swizzled_Application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void)localytics_swizzled_Application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [Localytics didRegisterUserNotificationSettings:notificationSettings];

    if (localyticsDidRegisterUserNotificationSettingsSwizzled) {
        [self localytics_swizzled_Application:application didRegisterUserNotificationSettings:notificationSettings];
    }
}

- (BOOL)localytics_swizzled_Application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [Localytics handleTestModeURL:url];
    return localyticsHandleOpenURLSwizzled ? [self localytics_swizzled_Application:application handleOpenURL:url] : YES;
}

- (BOOL)localytics_swizzled_Application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [Localytics handleTestModeURL:url];
    return localyticsOpenURLSourceApplicationAnnotationSwizzled ? [self localytics_swizzled_Application:application openURL:url sourceApplication:sourceApplication annotation:annotation] : YES;
}

- (BOOL)localytics_swizzled_Application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options {
    [Localytics handleTestModeURL:url];
    return localyticsOpenURLOptionsSwizzled ? [self localytics_swizzled_Application:application openURL:url options:options] : YES;
}

@end

@interface LocalyticsPlugin ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLInAppCampaign *> *inAppCampaignCache;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLInboxCampaign *> *inboxCampaignCache;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LLPlacesCampaign *> *placesCampaignCache;

@property (nonatomic, strong) CDAnalyticsDelegate *analyticsDelegate;
@property (nonatomic, strong) CDLocationDelegate *locationDelegate;
@property (nonatomic, strong) CDMessagingDelegate *messagingDelegate;

@end

@implementation LocalyticsPlugin

#pragma mark Private

static NSDictionary *launchOptions;

+ (void)load {
    // Listen for UIApplicationDidFinishLaunchingNotification to get a hold of launchOptions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification {
    launchOptions = notification.userInfo;
    if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [Localytics handleNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    }
}

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
        [array addObject:[self dictionaryFromInboxCampaign:campaign]];
    }

    return [array copy];
}

- (NSDictionary<NSString *, NSObject *> *)dictionaryFromInboxCampaign:(LLInboxCampaign *)campaign {
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
        @"receivedDate": @(campaign.receivedDate)
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
    NSString *appKey = nil;

    if ([command argumentAtIndex:0]) {
        appKey = [command argumentAtIndex:0];
    } else {
        appKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LocalyticsAppKey"];
    }

    if (appKey) {
        [Localytics integrate:appKey];
        launchOptions = nil; // Clear launchOptions on integrate
    }
}

- (void)autoIntegrate:(CDVInvokedUrlCommand *)command {
    NSString *appKey = nil;
    if ([command argumentAtIndex:0]) {
        appKey = [command argumentAtIndex:0];
    } else {
        appKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LocalyticsAppKey"];
    }

    if (appKey) {
        localyticsIsAutoIntegrate = YES;
        [Localytics autoIntegrate:appKey launchOptions: launchOptions];
        launchOptions = nil; // Clear launchOptions on integrate
    }
}

- (void)openSession:(CDVInvokedUrlCommand *)command {
    [Localytics openSession];
}

- (void)closeSession:(CDVInvokedUrlCommand *)command {
    [Localytics closeSession];
}

- (void)upload:(CDVInvokedUrlCommand *)command {
    [Localytics upload];
}


#pragma mark Analytics

- (void)setOptedOut:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setOptedOut:[enabled boolValue]];
    }
}

- (void)isOptedOut:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isOptedOut];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)tagEvent:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 3) {
        NSString *eventName = [command argumentAtIndex:0];
        NSDictionary *attributes = [command argumentAtIndex:1];
        NSNumber *customerValueIncrease = [command argumentAtIndex:2];

        if ([eventName isKindOfClass:[NSString class]] && eventName.length > 0) {
            [Localytics tagEvent:eventName attributes:attributes customerValueIncrease:customerValueIncrease];
        }
    }
}

- (void)tagPurchased:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 5) {
        NSString *itemName = [command argumentAtIndex:0];
        NSString *itemId = [command argumentAtIndex:1];
        NSString *itemType = [command argumentAtIndex:2];
        NSNumber *itemPrice = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagPurchased:itemName itemId:itemId itemType:itemType itemPrice:itemPrice attributes:attributes];
    }
}

- (void)tagAddedToCart:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 5) {
        NSString *itemName = [command argumentAtIndex:0];
        NSString *itemId = [command argumentAtIndex:1];
        NSString *itemType = [command argumentAtIndex:2];
        NSNumber *itemPrice = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagAddedToCart:itemName itemId:itemId itemType:itemType itemPrice:itemPrice attributes:attributes];
    }
}

- (void)tagStartedCheckout:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 3) {
        NSNumber *totalPrice = [command argumentAtIndex:0];
        NSNumber *itemCount = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagStartedCheckout:totalPrice itemCount:itemCount attributes:attributes];
    }
}

- (void)tagCompletedCheckout:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 3) {
        NSNumber *totalPrice = [command argumentAtIndex:0];
        NSNumber *itemCount = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagCompletedCheckout:totalPrice itemCount:itemCount attributes:attributes];
    }
}

- (void)tagContentViewed:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 4) {
        NSString *contentName = [command argumentAtIndex:0];
        NSString *contentId = [command argumentAtIndex:1];
        NSString *contentType = [command argumentAtIndex:2];
        NSDictionary *attributes = [command argumentAtIndex:3];
        [Localytics tagContentViewed:contentName contentId:contentId contentType:contentType attributes:attributes];
    }
}

- (void)tagSearched:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 4) {
        NSString *queryText = [command argumentAtIndex:0];
        NSString *contentType = [command argumentAtIndex:1];
        NSNumber *resultCount = [command argumentAtIndex:2];
        NSDictionary *attributes = [command argumentAtIndex:3];
        [Localytics tagSearched:queryText contentType:contentType resultCount:resultCount attributes:attributes];
    }
}

- (void)tagShared:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 5) {
        NSString *contentName = [command argumentAtIndex:0];
        NSString *contentId = [command argumentAtIndex:1];
        NSString *contentType = [command argumentAtIndex:2];
        NSString *methodName = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagShared:contentName contentId:contentId contentType:contentType methodName:methodName attributes:attributes];
    }
}

- (void)tagContentRated:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 5) {
        NSString *contentName = [command argumentAtIndex:0];
        NSString *contentId = [command argumentAtIndex:1];
        NSString *contentType = [command argumentAtIndex:2];
        NSNumber *rating = [command argumentAtIndex:3];
        NSDictionary *attributes = [command argumentAtIndex:4];
        [Localytics tagContentRated:contentName contentId:contentId contentType:contentType rating:rating attributes:attributes];
    }
}

- (void)tagCustomerRegistered:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 3) {
        LLCustomer *customer = [self customerFrom:[command argumentAtIndex:0]];
        NSString *methodName = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagCustomerRegistered:customer methodName:methodName attributes:attributes];
    }
}

- (void)tagCustomerLoggedIn:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 3) {
        LLCustomer *customer = [self customerFrom:[command argumentAtIndex:0]];
        NSString *methodName = [command argumentAtIndex:1];
        NSDictionary *attributes = [command argumentAtIndex:2];
        [Localytics tagCustomerLoggedIn:customer methodName:methodName attributes:attributes];
    }
}

- (void)tagCustomerLoggedOut:(CDVInvokedUrlCommand *)command {
    NSDictionary *attributes = [command argumentAtIndex:0];
    [Localytics tagCustomerLoggedOut:attributes];
}

- (void)tagInvited:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSString *methodName = [command argumentAtIndex:0];
        NSDictionary *attributes = [command argumentAtIndex:1];
        [Localytics tagInvited:methodName attributes:attributes];
    }
}

- (void)tagInAppImpression:(CDVInvokedUrlCommand *)command {
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
        }
    }
}

- (void)tagInboxImpression:(CDVInvokedUrlCommand *)command {
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
        }
    }
}

- (void)tagPushToInboxImpression:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        NSNumber *success = [command argumentAtIndex:1];
        LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
        if (campaign && [success isKindOfClass:[NSNumber class]]) {
            [Localytics tagImpressionForPushToInboxCampaign:campaign success:[success boolValue]];
        }
    }
}

- (void)tagPlacesPushReceived:(CDVInvokedUrlCommand *)command {
    NSNumber *campaignId = [command argumentAtIndex:0];
    LLPlacesCampaign *campaign = self.placesCampaignCache[@([campaignId integerValue])];
    if (campaign) {
        [Localytics tagPlacesPushReceived:campaign];
    }
}

- (void)tagPlacesPushOpened:(CDVInvokedUrlCommand *)command {
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
        }
    }
}

- (void)tagScreen:(CDVInvokedUrlCommand *)command {
    NSString *screenName = [command argumentAtIndex:0];
    if ([screenName length] > 0) {
        [Localytics tagScreen:screenName];
    }
}

- (void)setCustomDimension:(CDVInvokedUrlCommand *)command {
    NSNumber *dimension = [command argumentAtIndex:0];
    NSString *value = [command argumentAtIndex:1];
    if ([dimension isKindOfClass:[NSNumber class]]) {
        [Localytics setValue:value forCustomDimension:[dimension intValue]];
    }
}

- (void)getCustomDimension:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSNumber *dimension = [command argumentAtIndex:0];
        NSString *value = [Localytics valueForCustomDimension: [dimension intValue]];

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setAnalyticsListener:(CDVInvokedUrlCommand *)command {
    self.analyticsDelegate = [[CDAnalyticsDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                                invokedUrlCommand:command];
    [Localytics setAnalyticsDelegate:self.analyticsDelegate];
}

- (void)removeAnalyticsListener:(CDVInvokedUrlCommand *)command {
    self.analyticsDelegate = nil;
    [Localytics setAnalyticsDelegate:nil];
}

#pragma mark Profiles

- (void)setProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSObject<NSCopying> *value = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics setValue:value forProfileAttribute:attribute withScope:scope];
    }
}

- (void)addProfileAttributesToSet:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];

    if ([attribute length] > 0) {
        NSArray *values = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics addValues:values toSetForProfileAttribute:attribute withScope:scope];
    }
}

- (void)removeProfileAttributesFromSet:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];

    if ([attribute length] > 0) {
        NSArray *values = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics removeValues:values fromSetForProfileAttribute:attribute withScope:scope];
    }
}

- (void)incrementProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSInteger value = [[command argumentAtIndex:1 withDefault:0] intValue];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics incrementValueBy:value forProfileAttribute:attribute withScope:scope];
    }

}

- (void)decrementProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSInteger value = [[command argumentAtIndex:1 withDefault:0] intValue];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];

        [Localytics decrementValueBy:value forProfileAttribute:attribute withScope:scope];
    }
}

- (void)deleteProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if ([attribute length] > 0) {
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:1]];

        [Localytics deleteProfileAttribute:attribute withScope:scope];
    }
}

- (void)setCustomerEmail:(CDVInvokedUrlCommand *)command {
    NSString *email = [command argumentAtIndex:0];
    [Localytics setCustomerEmail:email];
}

- (void)setCustomerFirstName:(CDVInvokedUrlCommand *)command {
    NSString *firstName = [command argumentAtIndex:0];
    [Localytics setCustomerFirstName:firstName];
}

- (void)setCustomerLastName:(CDVInvokedUrlCommand *)command {
    NSString *lastName = [command argumentAtIndex:0];
    [Localytics setCustomerLastName:lastName];
}

- (void)setCustomerFullName:(CDVInvokedUrlCommand *)command {
    NSString *fullName = [command argumentAtIndex:0];
    [Localytics setCustomerFullName:fullName];
}

#pragma mark Customer Information

- (void)setIdentifier:(CDVInvokedUrlCommand *)command {
    NSString *identifier = [command argumentAtIndex:0];
    NSString *value = [command argumentAtIndex:1];
    if ([identifier length] > 0) {
        [Localytics setValue:value forIdentifier:identifier];
    }
}

- (void)getIdentifier:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *identifier = [command argumentAtIndex:0];
        NSString *value = [Localytics valueForIdentifier:identifier];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setCustomerId:(CDVInvokedUrlCommand *)command {
    NSString *customerId = [command argumentAtIndex:0];
    [Localytics setCustomerId:customerId];
}

- (void)getCustomerId:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics customerId];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setLocation:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSNumber *latitude = [command argumentAtIndex:0];
        NSNumber *longitude = [command argumentAtIndex:1];
        CLLocationCoordinate2D location;
        location.latitude = latitude.doubleValue;
        location.longitude = longitude.doubleValue;
        [Localytics setLocation:location];
    }
}


#pragma mark Marketing

- (void)registerPush:(CDVInvokedUrlCommand *)command {
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        UNAuthorizationOptions options = (UNAuthorizationOptionBadge | UNAuthorizationOptionSound |UNAuthorizationOptionAlert);
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options
                                                                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                                                                [Localytics didRequestUserNotificationAuthorizationWithOptions:options
                                                                                                                                       granted:granted];
                                                                            }];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
}

- (void)setPushToken:(CDVInvokedUrlCommand *)command {
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
    }
}

- (void)getPushToken:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics pushToken];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setNotificationsDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
}
- (void)areNotificationsDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
}

- (void)setDefaultNotificationChannel:(CDVInvokedUrlCommand *)command {
    // No-Op
}

- (void)setPushMessageConfiguration:(CDVInvokedUrlCommand *)command {
    // No-Op
}

- (void)setTestModeEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setTestModeEnabled:[enabled boolValue]];
    }
}

- (void)isTestModeEnabled:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isTestModeEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setInAppMessageDismissButtonImageWithName:(CDVInvokedUrlCommand *)command {
    NSString *imageName = [command argumentAtIndex:0];
    [Localytics setInAppMessageDismissButtonImageWithName:imageName];
}

- (void)setInAppMessageDismissButtonHidden:(CDVInvokedUrlCommand *)command {
    BOOL hidden = [[command argumentAtIndex:0] boolValue];
    [Localytics setInAppMessageDismissButtonHidden:hidden];
}

- (void)setInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command {
    NSString *value = [command argumentAtIndex:0];
    if (value) {
        [Localytics setInAppMessageDismissButtonLocation:[self getDismissButtonLocation:value]];
    }
}

- (void)getInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *value = [self fromDismissButtonLocation:[Localytics inAppMessageDismissButtonLocation]];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)triggerInAppMessage:(CDVInvokedUrlCommand *)command {
    NSString *triggerName = [command argumentAtIndex:0];
    NSDictionary *attributes = [command argumentAtIndex:1];

    if ([triggerName isKindOfClass:[NSString class]] && [triggerName length] > 0) {
        [Localytics triggerInAppMessage:triggerName withAttributes:attributes];
    }
}

- (void)triggerInAppMessagesForSessionStart:(CDVInvokedUrlCommand *)command {
    [Localytics triggerInAppMessagesForSessionStart];
}

- (void)dismissCurrentInAppMessage:(CDVInvokedUrlCommand *)command {
    [Localytics dismissCurrentInAppMessage];
}

- (void)setInAppMessageConfiguration:(CDVInvokedUrlCommand *)command {
    if (self.messagingDelegate) {
        self.messagingDelegate.inAppConfig = [command argumentAtIndex:0];
    }
}

- (void)isInAppAdIdParameterEnabled:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isInAppAdIdParameterEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setInAppAdIdParameterEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setInAppAdIdParameterEnabled:[enabled boolValue]];
    }
}

- (void)getInboxCampaigns:(CDVInvokedUrlCommand *)command {
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

- (void)getAllInboxCampaigns:(CDVInvokedUrlCommand *)command {
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
    if ([command.arguments count] == 2) {
        NSNumber *campaignId = [command argumentAtIndex:0];
        NSNumber *enabled = [command argumentAtIndex:1];
        if ([enabled isKindOfClass:[NSNumber class]]) {
            LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
            if (campaign) {
                [Localytics setInboxCampaign:campaign asRead:[enabled boolValue]];
            } else {
                [Localytics setInboxCampaignId:[campaignId integerValue] asRead:[enabled boolValue]];
            }
            [self updateInboxCampaignCache];
        }
    }
}

- (void)getInboxCampaignsUnreadCount:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSInteger value = [Localytics inboxCampaignsUnreadCount];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSInteger:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)inboxListItemTapped:(CDVInvokedUrlCommand *)command {
    NSNumber *campaignId = [command argumentAtIndex:0];
    LLInboxCampaign *campaign = self.inboxCampaignCache[@([campaignId integerValue])];
    if (campaign) {
        [Localytics inboxListItemTapped:campaign];
        [self updateInboxCampaignCache];
    }
}

- (void)triggerPlacesNotification:(CDVInvokedUrlCommand *)command {
    NSNumber *campaignId = [command argumentAtIndex:0];
    LLPlacesCampaign *campaign = self.placesCampaignCache[@([campaignId integerValue])];
    if (campaign) {
        [Localytics triggerPlacesNotificationForCampaign:campaign];
    }
}

- (void)setPlacesMessageConfiguration:(CDVInvokedUrlCommand *)command {
    if (self.messagingDelegate) {
        self.messagingDelegate.placesConfig = [command argumentAtIndex:0];
    }
}

- (void)setMessagingListener:(CDVInvokedUrlCommand *)command {
    self.messagingDelegate = [[CDMessagingDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                                invokedUrlCommand:command
                                                               inAppCampaignCache:self.inAppCampaignCache
                                                              placesCampaignCache:self.placesCampaignCache];
    [Localytics setMessagingDelegate:self.messagingDelegate];
}

- (void)removeMessagingListener:(CDVInvokedUrlCommand *)command {
    self.messagingDelegate = nil;
    [Localytics setMessagingDelegate:nil];
}

#pragma mark Location

- (void)setLocationMonitoringEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setLocationMonitoringEnabled:[enabled boolValue]];
    }
}

- (void)getGeofencesToMonitor:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSNumber *latitude = [command argumentAtIndex:0];
        NSNumber *longitude = [command argumentAtIndex:1];
        [self.commandDelegate runInBackground:^{
            NSArray<LLRegion *> *geofences = [Localytics geofencesToMonitor:CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue])];
            NSArray *value = [LocalyticsPlugin dictionaryArrayFromRegions:geofences];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:value];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
}

- (void)triggerRegion:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSDictionary *region = [command argumentAtIndex:0];
        NSString *event = [command argumentAtIndex:1];
        [Localytics triggerRegion:[self regionFromDictionary:region] withEvent:[self eventFrom:event]];
    }
}

- (void)triggerRegions:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSArray *regions = [command argumentAtIndex:0];
        NSString *event = [command argumentAtIndex:1];
        [Localytics triggerRegions:[self regionsFromDictionaryArray:regions] withEvent:[self eventFrom:event]];
    }
}

- (void)setLocationListener:(CDVInvokedUrlCommand *)command {
    self.locationDelegate = [[CDLocationDelegate alloc] initWithCommandDelegate:self.commandDelegate
                                                              invokedUrlCommand:command];
    [Localytics setLocationDelegate:self.locationDelegate];
}

- (void)removeLocationListener:(CDVInvokedUrlCommand *)command {
    self.locationDelegate = nil;
    [Localytics setLocationDelegate:nil];
}

#pragma mark Developer Options

- (void)setLoggingEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        [Localytics setLoggingEnabled:[enabled boolValue]];
    }
}

- (void)isLoggingEnabled:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        BOOL value = [Localytics isLoggingEnabled];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)setOptions:(CDVInvokedUrlCommand *)command {
    NSDictionary *options = [command argumentAtIndex:0];
    [Localytics setOptions:options];
}

- (void)setOption:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 2) {
        NSString *key = [command argumentAtIndex:0];
        NSObject *value = [command argumentAtIndex:1];
        [Localytics setOptions:@{key: value}];
    }
}

- (void)redirectLogsToDisk:(CDVInvokedUrlCommand *)command {
    // No-Op
}

- (void)getInstallId:(CDVInvokedUrlCommand *)command {
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

@end
