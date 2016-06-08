//
//  LocalyticsPlugin.m
//
//  Copyright 2015 Localytics. All rights reserved.
//

#import "AppDelegate.h"
#import "LocalyticsPlugin.h"
#import "Localytics.h"
#import <objc/runtime.h>

#define PROFILE_SCOPE_ORG @"org"
#define PROFILE_SCOPE_APP @"app"

static BOOL localyticsIsAutoIntegrate = NO;
static BOOL localyticsDidReceiveRemoteNotificationSwizzled = NO;
static BOOL localyticsRemoteNotificationSwizzled = NO;
static BOOL localyticsRemoteNotificationErrorSwizzled = NO;
static BOOL localyticsSourceApplicationOpenURLSwizzled = NO;

BOOL MethodSwizzle(Class clazz, SEL originalSelector, SEL overrideSelector)
{
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

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clazz = [self class];

        localyticsDidReceiveRemoteNotificationSwizzled = MethodSwizzle(clazz, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:), @selector(localytics_swizzled_Application:didReceiveRemoteNotification:fetchCompletionHandler:));
        localyticsRemoteNotificationSwizzled = MethodSwizzle(clazz, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), @selector(localytics_swizzled_Application:didRegisterForRemoteNotificationsWithDeviceToken:));
        localyticsRemoteNotificationErrorSwizzled = MethodSwizzle(clazz, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), @selector(localytics_swizzled_Application:didFailToRegisterForRemoteNotificationsWithError:));
        localyticsSourceApplicationOpenURLSwizzled = MethodSwizzle(clazz, @selector(application:openURL:sourceApplication:annotation:), @selector(localytics_swizzled_Application:openURL:sourceApplication:annotation:));
    });
}

- (void) localytics_swizzled_Application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [Localytics handlePushNotificationOpened:userInfo];
    completionHandler(UIBackgroundFetchResultNoData);
    
    if (localyticsDidReceiveRemoteNotificationSwizzled) {
        [self localytics_swizzled_Application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

- (void) localytics_swizzled_Application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
{
    if (!localyticsIsAutoIntegrate) {
        [Localytics setPushToken:deviceToken];
    }
    if (localyticsRemoteNotificationSwizzled) {
        [self localytics_swizzled_Application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void) localytics_swizzled_Application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;
{
    NSLog(@"onRemoteRegisterFail: %@", [error description]);
    if (localyticsRemoteNotificationErrorSwizzled) {
        [self localytics_swizzled_Application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (BOOL) localytics_swizzled_Application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [Localytics handleTestModeURL: url];
    return localyticsSourceApplicationOpenURLSwizzled? [self localytics_swizzled_Application:application openURL:url sourceApplication:sourceApplication annotation:annotation] : YES;
}

@end


@implementation LocalyticsPlugin

#pragma mark Private

static NSDictionary* launchOptions;

+ (void)load {
    // Listen for UIApplicationDidFinishLaunchingNotification to get a hold of launchOptions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification {
    launchOptions = notification.userInfo;
    if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [Localytics handlePushNotificationOpened: launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    }
}

- (NSUInteger)getProfileScope:(NSString*)scope {
    if (scope && [scope caseInsensitiveCompare:PROFILE_SCOPE_ORG] == NSOrderedSame)
        return LLProfileScopeOrganization;
    else
        return LLProfileScopeApplication;
}

- (LLInAppMessageDismissButtonLocation)getDismissButtonLocation:(int)value {
    if (value == 1)
        return LLInAppMessageDismissButtonLocationRight;
    else
        return LLInAppMessageDismissButtonLocationLeft;
}

#pragma mark Integration

- (void)integrate:(CDVInvokedUrlCommand *)command {
    NSString *appKey = nil;

    if ([command argumentAtIndex: 0]) {
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
    if ([command argumentAtIndex: 0]) {
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

- (void)tagEvent:(CDVInvokedUrlCommand *)command {
    if ([command.arguments count] == 3) {
        NSString *eventName = [command argumentAtIndex:0];
        NSDictionary *attributes = [command argumentAtIndex:1];
        NSNumber *customerValueIncrease = [command argumentAtIndex:2];
        
        if (eventName && [eventName isKindOfClass:[NSString class]] && [eventName length] > 0 &&
            customerValueIncrease && [customerValueIncrease isKindOfClass:[NSNumber class]]) {
            [Localytics tagEvent:eventName attributes:attributes customerValueIncrease:customerValueIncrease];
        }
    }
}

- (void)tagScreen:(CDVInvokedUrlCommand *)command {
    NSString *screenName = [command argumentAtIndex:0];
    if (screenName && [screenName length] > 0) {
        [Localytics tagScreen:screenName];
    }
}

- (void)setCustomDimension:(CDVInvokedUrlCommand *)command {
    NSNumber *dimension = [command argumentAtIndex:0];
    NSString *value = [command argumentAtIndex:1];
    if (dimension && [dimension isKindOfClass:[NSNumber class]]) {
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

- (void)setOptedOut:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if (enabled && [enabled isKindOfClass:[NSNumber class]]) {
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


#pragma mark Profiles

- (void)setProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if (attribute && [attribute length] > 0) {
        NSObject<NSCopying> *value = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];
        
        [Localytics setValue:value forProfileAttribute:attribute withScope:scope];
    }
}

- (void)addProfileAttributesToSet:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    
    if (attribute && [attribute length] > 0) {
        NSArray *values = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];
        
        [Localytics addValues:values toSetForProfileAttribute:attribute withScope:scope];
    }
}

- (void)removeProfileAttributesFromSet:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    
    if (attribute && [attribute length] > 0) {
        NSArray *values = [command argumentAtIndex:1];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];
        
        [Localytics removeValues:values fromSetForProfileAttribute:attribute withScope:scope];
    }
}

- (void)incrementProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if (attribute && [attribute length] > 0) {
        NSInteger value = [[command argumentAtIndex:1 withDefault:0] intValue];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];
        
        [Localytics incrementValueBy:value forProfileAttribute:attribute withScope:scope];
    }
    
}

- (void)decrementProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if (attribute && [attribute length] > 0) {
        NSInteger value = [[command argumentAtIndex:1 withDefault:0] intValue];
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:2]];
        
        [Localytics decrementValueBy:value forProfileAttribute:attribute withScope:scope];
    }
}

- (void)deleteProfileAttribute:(CDVInvokedUrlCommand *)command {
    NSString *attribute = [command argumentAtIndex:0];
    if (attribute && [attribute length] > 0) {
        NSUInteger scope = [self getProfileScope:[command argumentAtIndex:1]];
        
        [Localytics deleteProfileAttribute:attribute withScope:scope];
    }
}


#pragma mark Customer Information

- (void)setIdentifier:(CDVInvokedUrlCommand *)command {
    NSString *identifier = [command argumentAtIndex:0];
    NSString *value = [command argumentAtIndex:1];
    if (identifier && [identifier length] > 0) {
        [Localytics setValue:value forIdentifier:identifier];
    }
}

- (void)setCustomerId:(CDVInvokedUrlCommand *)command {
    NSString *customerId = [command argumentAtIndex:0];
    [Localytics setCustomerId:customerId];
}

- (void)setCustomerFullName:(CDVInvokedUrlCommand *)command {
    NSString *fullName = [command argumentAtIndex:0];
    [Localytics setCustomerFullName:fullName];
}

- (void)setCustomerFirstName:(CDVInvokedUrlCommand *)command {
    NSString *firstName = [command argumentAtIndex:0];
    [Localytics setCustomerFirstName:firstName];
}

- (void)setCustomerLastName:(CDVInvokedUrlCommand *)command {
    NSString *lastName = [command argumentAtIndex:0];
    [Localytics setCustomerLastName:lastName];
}

- (void)setCustomerEmail:(CDVInvokedUrlCommand *)command {
    NSString *email = [command argumentAtIndex:0];
    [Localytics setCustomerEmail:email];
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
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
}

- (void)setPushDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
}
- (void)isPushDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
}

- (void)setTestModeEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if (enabled && [enabled isKindOfClass:[NSNumber class]]) {
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

- (void)setInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command {
    NSNumber* value = [command argumentAtIndex:0];
    if (value) {
        [Localytics setInAppMessageDismissButtonLocation: [self getDismissButtonLocation:value.intValue]];
    }
}

- (void)getInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        LLInAppMessageDismissButtonLocation value = [Localytics inAppMessageDismissButtonLocation];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)triggerInAppMessage:(CDVInvokedUrlCommand *)command {
    NSString *triggerName = [command argumentAtIndex:0];
    NSDictionary *attributes = [command argumentAtIndex:1];

    if (triggerName && [triggerName isKindOfClass:[NSString class]] && [triggerName length] > 0) {
        [Localytics triggerInAppMessage:triggerName withAttributes:attributes];
    }
}

- (void)dismissCurrentInAppMessage:(CDVInvokedUrlCommand *)command {
    [Localytics dismissCurrentInAppMessage];
}


#pragma mark Developer Options

- (void)setLoggingEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *enabled = [command argumentAtIndex:0];
    if (enabled && [enabled isKindOfClass:[NSNumber class]]) {
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

- (void)setSessionTimeoutInterval:(CDVInvokedUrlCommand *)command {
    NSNumber *timeout = [command argumentAtIndex:0];
    if (timeout) {
        [Localytics setSessionTimeoutInterval:[timeout doubleValue]];
    }
}

- (void)getSessionTimeoutInterval:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSTimeInterval value = [Localytics sessionTimeoutInterval];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
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