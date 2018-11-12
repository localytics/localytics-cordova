//
//  CDAnalyticsDelegate.m
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import "CDCTADelegate.h"
#import "LocalyticsPlugin.h"

@implementation CDCTADelegate

- (BOOL)localyticsShouldDeeplink:(nonnull NSURL *)url campaign:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"url": [url absoluteString], @"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsShouldDeeplink", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
    return YES;
}

- (void)localyticsDidOptOut:(BOOL)optedOut campaign:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"optedOut": @(optedOut), @"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsDidOptOut", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
}

- (void)localyticsDidPrivacyOptOut:(BOOL)privacyOptedOut campaign:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"privacyOptedOut": @(privacyOptedOut), @"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsDidPrivacyOptOut", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
}

- (BOOL)localyticsShouldPromptForLocationWhenInUsePermissions:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsShouldPromptForLocationWhenInUsePermissions", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
    return YES;
}

- (BOOL)localyticsShouldPromptForLocationAlwaysPermissions:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsShouldPromptForLocationAlwaysPermissions", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
    return YES;
}

- (BOOL)localyticsShouldPromptForNotificationPermissions:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsShouldPromptForNotificationPermissions", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
    return YES;
}

- (BOOL)localyticsShouldDeeplinkToSettings:(LLCampaignBase *)campaign {
    if ([self canTransmitToJS]) {
        NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
        NSDictionary *object = @{@"method": @"localyticsShouldDeeplinkToSettings", @"params": params};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
    return YES;
}

 - (void)requestAlwaysAuthorization:(CLLocationManager *)manager {
    if (self.monitoringDelegate != nil) {
        [self.monitoringDelegate requestAlwaysAuthorization:manager];
    }
    if ([self canTransmitToJS]) {
        NSDictionary *object = @{@"method": @"requestAlwaysAuthorization"};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
}

 - (void)requestWhenInUseAuthorization:(CLLocationManager *)manager {
    if (self.monitoringDelegate != nil) {
        [self.monitoringDelegate requestWhenInUseAuthorization:manager];
    }
    if ([self canTransmitToJS]) {
        NSDictionary *object = @{@"method": @"requestAlwaysAuthorization"};

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    }
}

#pragma mark private methods

- (BOOL)canTransmitToJS {
    return self.commandDelegate != nil && self.invokedUrlCommand != nil;
}

- (NSDictionary<NSString *, NSObject *>  *)dictionaryFromGenericCampaign:(LLCampaignBase *)campaign {
    if ([campaign isKindOfClass:[LLInAppCampaign class]]) {
        return [LocalyticsPlugin dictionaryFromInAppCampaign:(LLInAppCampaign *) campaign];
    } else if ([campaign isKindOfClass:[LLInboxCampaign class]]) {
        return [LocalyticsPlugin dictionaryFromInboxCampaign:(LLInboxCampaign *) campaign];;
    } else if ([campaign isKindOfClass:[LLPlacesCampaign class]]) {
        return [LocalyticsPlugin dictionaryFromPlacesCampaign:(LLPlacesCampaign *) campaign];
    }
    return nil;
}

@end
