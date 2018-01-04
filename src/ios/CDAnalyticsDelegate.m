//
//  CDAnalyticsDelegate.m
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import "CDAnalyticsDelegate.h"
#import "LocalyticsPlugin.h"

@interface CDAnalyticsDelegate ()

@property (nonatomic, weak) id<CDVCommandDelegate> commandDelegate;
@property (nonatomic, strong) CDVInvokedUrlCommand *invokedUrlCommand;

@end

@implementation CDAnalyticsDelegate

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand {
    if (self = [super init]) {
        _commandDelegate = commandDelegate;
        _invokedUrlCommand = invokedUrlCommand;
    }

    return self;
}

- (void)localyticsSessionWillOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume {
    NSDictionary *params = @{@"isFirst": @(isFirst), @"isUpgrade": @(isUpgrade), @"isResume": @(isResume)};
    NSDictionary *object = @{@"method": @"localyticsSessionWillOpen", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsSessionDidOpen:(BOOL)isFirst isUpgrade:(BOOL)isUpgrade isResume:(BOOL)isResume {
    NSDictionary *params = @{@"isFirst": @(isFirst), @"isUpgrade": @(isUpgrade), @"isResume": @(isResume)};
    NSDictionary *object = @{@"method": @"localyticsSessionDidOpen", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsDidTagEvent:(NSString *)eventName attributes:(NSDictionary<NSString *,NSString *> *)attributes customerValueIncrease:(NSNumber *)customerValueIncrease {
    NSDictionary *params = @{@"name": eventName, @"attributes": attributes ?: [NSNull null], @"customerValueIncrease": customerValueIncrease ?: [NSNull null]};
    NSDictionary *object = @{@"method": @"localyticsDidTagEvent", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsSessionWillClose {
    NSDictionary *object = @{@"method": @"localyticsSessionWillClose"};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

@end
