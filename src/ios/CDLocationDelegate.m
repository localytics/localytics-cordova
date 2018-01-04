//
//  CDLocationDelegate.m
//
//  Copyright 2018 Localytics. All rights reserved.
//

#import "CDLocationDelegate.h"
#import "LocalyticsPlugin.h"

@interface CDLocationDelegate ()

@property (nonatomic, weak) id<CDVCommandDelegate> commandDelegate;
@property (nonatomic, strong) CDVInvokedUrlCommand *invokedUrlCommand;

@end

@implementation CDLocationDelegate

- (instancetype)initWithCommandDelegate:(id<CDVCommandDelegate>)commandDelegate
                      invokedUrlCommand:(CDVInvokedUrlCommand *)invokedUrlCommand {
    if (self = [super init]) {
        _commandDelegate = commandDelegate;
        _invokedUrlCommand = invokedUrlCommand;
    }

    return self;
}

- (void)localyticsDidUpdateLocation:(CLLocation *)location {
    NSDictionary *params = @{@"location": @{@"latitude": @(location.coordinate.latitude), @"longitude": @(location.coordinate.longitude)}};
    NSDictionary *object = @{@"method": @"localyticsDidUpdateLocation", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsDidUpdateMonitoredRegions:(NSArray<LLRegion *> *)addedRegions removeRegions:(NSArray<LLRegion *> *)removedRegions {
    NSDictionary *params = @{
        @"added": [LocalyticsPlugin dictionaryArrayFromRegions:addedRegions],
        @"removed": [LocalyticsPlugin dictionaryArrayFromRegions:removedRegions]
    };
    NSDictionary *object = @{@"method": @"localyticsDidUpdateMonitoredGeofences", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

- (void)localyticsDidTriggerRegions:(NSArray<LLRegion *> *)regions withEvent:(LLRegionEvent)event {
    NSDictionary *params = @{
        @"regions": [LocalyticsPlugin dictionaryArrayFromRegions:regions],
        @"event": event == LLRegionEventEnter ? @"enter": @"exit"
    };
    NSDictionary *object = @{@"method": @"localyticsDidTriggerRegions", @"params": params};

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:object];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.invokedUrlCommand.callbackId];
}

@end
