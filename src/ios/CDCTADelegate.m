//
//  CDAnalyticsDelegate.m
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import "CDCTADelegate.h"
#import "LocalyticsPlugin.h"

@interface CDCTADelegate ()

@property (nonatomic, weak) id<CDVCommandDelegate> commandDelegate;
@property (nonatomic, strong) CDVInvokedUrlCommand *invokedUrlCommand;

@end

@implementation CDCTADelegate

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand {
    if (self = [super init]) {
        _commandDelegate = commandDelegate;
        _invokedUrlCommand = invokedUrlCommand;
    }

    return self;
}

- (BOOL)localyticsShouldDeeplink:(nonnull NSURL *)url campaign:(LLCampaignBase *)campaign {
    NSDictionary *params = @{@"url": [url absoluteString], @"campaign": [self dictionaryFromGenericCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsShouldDeeplink", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    return YES;
}

- (void)localyticsDidOptOut:(BOOL)optedOut campaign:(LLCampaignBase *)campaign {
    NSDictionary *params = @{@"optedOut": @(optedOut), @"campaign": [self dictionaryFromGenericCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsDidOptOut", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsDidPrivacyOptOut:(BOOL)privacyOptedOut campaign:(LLCampaignBase *)campaign {
    NSDictionary *params = @{@"privacyOptedOut": @(privacyOptedOut), @"campaign": [self dictionaryFromGenericCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsDidPrivacyOptOut", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (BOOL)localyticsShouldPromptForLocationWhenInUsePermissions:(LLCampaignBase *)campaign {
    NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsShouldPromptForLocationWhenInUsePermissions", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    return YES;
}

- (BOOL)localyticsShouldPromptForLocationAlwaysPermissions:(LLCampaignBase *)campaign {
    NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsShouldPromptForLocationAlwaysPermissions", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    return YES;
}

- (BOOL)localyticsShouldPromptForNotificationPermissions:(LLCampaignBase *)campaign {
    NSDictionary *params = @{@"campaign": [self dictionaryFromGenericCampaign:campaign]};
    NSDictionary *object = @{@"method": @"localyticsShouldPromptForNotificationPermissions", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
    return YES;
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
