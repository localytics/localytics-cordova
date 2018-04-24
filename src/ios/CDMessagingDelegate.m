//
//  CDMessagingDelegate.m
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import "CDMessagingDelegate.h"
#import "LocalyticsPlugin.h"

@import UserNotifications;

@interface CDMessagingDelegate ()

@property (nonatomic, weak) id<CDVCommandDelegate> commandDelegate;
@property (nonatomic, strong) CDVInvokedUrlCommand *invokedUrlCommand;
@property (nonatomic, strong) NSMutableDictionary *inAppCampaignCache;
@property (nonatomic, strong) NSMutableDictionary *placesCampaignCache;

@end

@implementation CDMessagingDelegate

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand
                     inAppCampaignCache:(NSMutableDictionary *)inAppCampaignCache
                    placesCampaignCache:(NSMutableDictionary *)placesCampaignCache {
    if (self = [super init]) {
        _commandDelegate = commandDelegate;
        _invokedUrlCommand = invokedUrlCommand;
        _inAppCampaignCache = inAppCampaignCache;
        _placesCampaignCache = placesCampaignCache;
    }

    return self;
}

- (BOOL)localyticsShouldShowInAppMessage:(nonnull LLInAppCampaign *)campaign {
    // Cache campaign
    [self.inAppCampaignCache setObject:campaign forKey:@(campaign.campaignId)];

    BOOL shouldShow = YES;
    if (self.inAppConfig) {

        // Global Suppression
        if (self.inAppConfig[@"shouldShow"]) {
            shouldShow = [self.inAppConfig[@"shouldShow"] boolValue];
        }

        // DIY In-App. This callback will suppress the in-app and emit an event
        // for manually handling
        if (self.inAppConfig[@"diy"] && [self.inAppConfig[@"diy"] boolValue]) {
            NSDictionary *params = @{@"campaign": [LocalyticsPlugin dictionaryFromInAppCampaign:campaign]};
            NSDictionary *object = @{@"method": @"localyticsDiyInAppMessage", @"params": params};

            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

            return NO;
        }
    }

    NSDictionary *params = @{
        @"campaign": [LocalyticsPlugin dictionaryFromInAppCampaign:campaign],
        @"shouldShow": @(shouldShow)
    };
    NSDictionary *object = @{@"method": @"localyticsShouldShowInAppMessage", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

    return shouldShow;
}

- (BOOL)localyticsShouldDelaySessionStartInAppMessages {
    BOOL shouldDelay = NO;
    if (self.inAppConfig && self.inAppConfig[@"delaySessionStart"]) {
        shouldDelay = [self.inAppConfig[@"delaySessionStart"] boolValue];
    }

    NSDictionary *params = @{@"shouldDelay": @(shouldDelay)};
    NSDictionary *object = @{@"method": @"localyticsShouldDelaySessionStartInAppMessages", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

    return shouldDelay;
}

- (nonnull LLInAppConfiguration *)localyticsWillDisplayInAppMessage:(nonnull LLInAppCampaign *)campaign withConfiguration:(nonnull LLInAppConfiguration *)configuration {
    if (self.inAppConfig) {
        if (self.inAppConfig[@"dismissButtonLocation"]) {
            configuration.dismissButtonLocation = [LocalyticsPlugin locationFrom:self.inAppConfig[@"dismissButtonLocation"]];
        }
        if (self.inAppConfig[@"dismissButtonHidden"]) {
            configuration.dismissButtonHidden = [self.inAppConfig[@"dismissButtonHidden"] boolValue];
        }
        if (self.inAppConfig[@"dismissButtonImageName"]) {
            [configuration setDismissButtonImageWithName:self.inAppConfig[@"dismissButtonImageName"]];
        }
        if (self.inAppConfig[@"aspectRatio"]) {
            configuration.aspectRatio = [self.inAppConfig[@"aspectRatio"] floatValue];
        }
        if (self.inAppConfig[@"offset"]) {
            configuration.offset = [self.inAppConfig[@"offset"] floatValue];
        }
        if (self.inAppConfig[@"backgroundAlpha"]) {
            configuration.backgroundAlpha = [self.inAppConfig[@"backgroundAlpha"] floatValue];
        }
    }

    NSDictionary *params = @{@"campaign": [LocalyticsPlugin dictionaryFromInAppCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsWillDisplayInAppMessage", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

    return configuration;
}

- (BOOL)localyticsShouldDeeplink {
    // As of now unimplemented
    return YES;
}

- (void)localyticsWillDismissInAppMessage {
    NSDictionary *object = @{@"method": @"localyticsWillDismissInAppMessage"};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsDidDismissInAppMessage {
    NSDictionary *object = @{@"method": @"localyticsDidDismissInAppMessage"};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (BOOL)localyticsShouldDisplayPlacesCampaign:(nonnull LLPlacesCampaign *)campaign {
    // Cache campaign
    [self.placesCampaignCache setObject:campaign forKey:@(campaign.campaignId)];

    BOOL shouldShow = YES;
    if (self.placesConfig) {

        // Global Suppression
        if (self.placesConfig[@"shouldShow"]) {
            shouldShow = [self.placesConfig[@"shouldShow"] boolValue];
        }

        // DIY Places. This callback will suppress the Places push and emit an event
        // for manually handling
        if (self.placesConfig[@"diy"] && [self.placesConfig[@"diy"] boolValue]) {
            NSDictionary *params = @{@"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign]};
            NSDictionary *object = @{@"method": @"localyticsDiyPlacesPushNotification", @"params": params};

            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

            return NO;
        }
    }

    NSDictionary *params = @{
        @"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign],
        @"shouldShow": @(shouldShow)
    };
    NSDictionary *object = @{@"method": @"localyticsShouldShowPlacesPushNotification", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

    return shouldShow;
}

- (nonnull UILocalNotification *)localyticsWillDisplayNotification:(nonnull UILocalNotification *)notification forPlacesCampaign:(nonnull LLPlacesCampaign *)campaign {
    if (self.placesConfig) {
        if (self.placesConfig[@"alertAction"]) {
            notification.alertAction = self.placesConfig[@"alertAction"];
        }
        if (self.placesConfig[@"alertTitle"]) {
            notification.alertTitle = self.placesConfig[@"alertTitle"];
        }
        if (self.placesConfig[@"hasAction"]) {
            notification.hasAction = [self.placesConfig[@"hasAction"] boolValue];
        }
        if (self.placesConfig[@"alertLaunchImage"]) {
            notification.alertLaunchImage = self.placesConfig[@"alertLaunchImage"];
        }
        if (self.placesConfig[@"category"]) {
            notification.category = self.placesConfig[@"category"];
        }
        if (self.placesConfig[@"applicationIconBadgeNumber"]) {
            notification.applicationIconBadgeNumber = [self.placesConfig[@"applicationIconBadgeNumber"] integerValue];
        }
        if (self.placesConfig[@"soundName"]) {
            notification.soundName = self.placesConfig[@"soundName"];
        }
    }

    NSDictionary *params = @{@"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsWillShowPlacesPushNotification", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

    return notification;
}

- (nonnull UNMutableNotificationContent *)localyticsWillDisplayNotificationContent:(nonnull UNMutableNotificationContent *)notification forPlacesCampaign:(nonnull LLPlacesCampaign *)campaign {
    if (self.placesConfig) {
        if (self.placesConfig[@"title"]) {
            notification.title = self.placesConfig[@"title"];
        }
        if (self.placesConfig[@"subtitle"]) {
            notification.subtitle = self.placesConfig[@"subtitle"];
        }
        if (self.placesConfig[@"badge"]) {
            notification.badge = @([self.placesConfig[@"badge"] integerValue]);
        }
        if (self.placesConfig[@"sound"]) {
            notification.sound = [UNNotificationSound soundNamed:self.placesConfig[@"sound"]];
        }
        if (self.placesConfig[@"launchImageName"]) {
            notification.launchImageName = self.placesConfig[@"launchImageName"];
        }
    }

    NSDictionary *params = @{@"campaign": [LocalyticsPlugin dictionaryFromPlacesCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsWillShowPlacesPushNotification", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];

    return notification;
}

@end
