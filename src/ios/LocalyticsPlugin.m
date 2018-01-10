//
//  LocalyticsPlugin.m
//  Copyright (C) 2015 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.
//

#import <UserNotifications/UNUserNotificationCenter.h>
#import "AppDelegate.h"
#import "LocalyticsPlugin.h"
#import <Localytics/Localytics.h>
#import <objc/runtime.h>
#import "Branch.h"
#import <WebKit/WebKit.h>

#define PROFILE_SCOPE_ORG @"org"
#define PROFILE_SCOPE_APP @"app"

static BOOL localyticsIsAutoIntegrate = NO;
static BOOL localyticsDidReceiveRemoteNotificationSwizzled = NO;
static BOOL localyticsRemoteNotificationSwizzled = NO;
static BOOL localyticsRemoteNotificationErrorSwizzled = NO;
static BOOL localyticsSourceApplicationOpenURLSwizzled = NO;
static BOOL localyticsSourceApplicationOpenURLSwizzled3 = NO;

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
        
        localyticsSourceApplicationOpenURLSwizzled3 = MethodSwizzle(clazz, @selector(application:didRegisterUserNotificationSettings:), @selector(localytics_swizzled_Application:didRegisterUserNotificationSettings:));
        
        
    });
}




- (void)localytics_swizzled_Application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    NSLog(@"%@", notificationSettings);
    [Localytics didRegisterUserNotificationSettings:notificationSettings];
}

- (void)registerForBackground {
    NSLog(@"registered task");
    
    if (self.backgroundTask == UIBackgroundTaskInvalid) {
        self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self endBackgroundTask];
        }];
    }
}

- (void)endBackgroundTask {
    NSLog(@"endBackgroundTask");
    
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}

- (void) localytics_swizzled_Application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self registerForBackground];
    NSLog(@"FIRED NOTIFICATIONS");
    NSString *ministryId = userInfo[@"ministryId"];
    WKWebView *webView = (WKWebView *)self.viewController.webView;
    [webView evaluateJavaScript:[NSString stringWithFormat:@"window.Localytics.notoficationReceived(\"%@\")", ministryId] completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
            NSLog(@"%@", result);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@", error.localizedDescription);
        }
    }];
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
    [self setCategoryButton];
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
    return [Localytics handleTestModeURL: url];
}

-(void)setCategoryButton{
    UNNotificationAction *subscribe = [UNNotificationAction actionWithIdentifier:@"subscribe" title:@"Subscribe" options:UNNotificationActionOptionForeground];
    UNNotificationAction *listen = [UNNotificationAction actionWithIdentifier:@"listen" title:@"Listen Now" options:UNNotificationActionOptionForeground];
    UNNotificationCategory *podcastAction = [UNNotificationCategory categoryWithIdentifier:@"podcastAction" actions:@[subscribe, listen] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    UNNotificationCategory *subscribedPodcast = [UNNotificationCategory categoryWithIdentifier:@"subscribedPodcast" actions:@[listen] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    UNNotificationAction *more = [UNNotificationAction actionWithIdentifier:@"more" title:@"More like this" options:UNNotificationActionOptionForeground];
    UNNotificationAction *less = [UNNotificationAction actionWithIdentifier:@"less" title:@"Less like this" options:UNNotificationActionOptionForeground];
    UNNotificationCategory *notificationAction = [UNNotificationCategory categoryWithIdentifier:@"notificationAction" actions:@[more, less] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    UNNotificationAction *listening = [UNNotificationAction actionWithIdentifier:@"listening" title:@"Yes,Keep Listening" options:UNNotificationActionOptionForeground];
    UNNotificationAction *nextPlay = [UNNotificationAction actionWithIdentifier:@"nextPlay" title:@"Play next" options:UNNotificationActionOptionForeground];
    UNNotificationCategory *localNotificationAction = [UNNotificationCategory categoryWithIdentifier:@"localNotificationAction" actions:@[listening, nextPlay] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    NSSet *categories = [NSSet setWithArray:@[podcastAction,subscribedPodcast, notificationAction,localNotificationAction]];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(callSubscribe:) name:@"callSubscribe" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(localNotificationHandler:) name:@"localNotificationHandler" object:nil];
}

-(void)callSubscribe:(NSNotification *)notification{
    NSString *type = notification.userInfo[@"type"];
    NSString *ministryId = notification.userInfo[@"ministryId"];
    NSString *ministryName = notification.userInfo[@"ministryName"];
    NSString *feedId = notification.userInfo[@"feedId"];
    NSString *title = notification.userInfo[@"title"];
    NSString *body = notification.userInfo[@"body"];
    NSString *campingId = notification.userInfo[@"campingId"];
    WKWebView *webView = (WKWebView *)self.viewController.webView;
    [webView evaluateJavaScript:[NSString stringWithFormat:@"window.Localytics.notoficationActionReceived(\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\")", ministryId,feedId,ministryName,type,campingId,title,body] completionHandler:nil];
}

-(void)localNotificationHandler:(NSNotification *)notification{
    NSString *type = notification.userInfo[@"type"];
    NSString *clipId = notification.userInfo[@"clipId"];
    NSString *feedId = notification.userInfo[@"feedId"];
    WKWebView *webView = (WKWebView *)self.viewController.webView;
    [webView evaluateJavaScript:[NSString stringWithFormat:@"window.Localytics.localNotoficationActionReceived(\"%@\",\"%@\",\"%@\")", clipId,feedId,type] completionHandler:nil];
}


@end

@interface LocalyticsPlugin ()

@property (strong, nonatomic) UNUserNotificationCenter* center;
@property (strong, nonatomic) NSDictionary *pendingNotification;

@end

@implementation LocalyticsPlugin

#pragma mark Private

static NSDictionary* launchOptions;
/**
 * Registers obervers after plugin was initialized.
 */
- (void) pluginInitialize
{
    _center    = [UNUserNotificationCenter currentNotificationCenter];
    _center.delegate = self;
}


+ (void)load {
    // Listen for UIApplicationDidFinishLaunchingNotification to get a hold of launchOptions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    // Listen to re-broadcast events from Cordova's AppDelegate
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidRegisterForRemoteNotificationWithDeviceToken:) name:CDVRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFailToRegisterForRemoteNotificationsWithError:) name:CDVRemoteNotificationError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHandleOpenURLNotification:) name:CDVPluginHandleOpenURLNotification object:nil];
}

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification {
    launchOptions = notification.userInfo;
    if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [Localytics handleNotification: launchOptions];
    }
    
    
    
    [Localytics handleNotification: launchOptions];
}

+ (void)onDidRegisterForRemoteNotificationWithDeviceToken:(NSNotification *)notification {
    NSLog(@"onRemoteRegister: %@", notification.object);
    [Localytics setPushToken:notification.object];
}

+ (void)onDidFailToRegisterForRemoteNotificationsWithError:(NSNotification *)notification {
    //Log Failures
    NSLog(@"onRemoteRegisterFail: %@", notification.object);
}

+ (void)onHandleOpenURLNotification:(NSNotification *)notification {
    [Localytics handleTestModeURL: notification.object];
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
        if(_pendingNotification){
            [Localytics didReceiveNotificationResponseWithUserInfo:_pendingNotification];
            _pendingNotification = nil;
        }
        
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

#pragma mark Analytics - Standard events
- (void)tagCustomerRegistered: (CDVInvokedUrlCommand *)command {
    NSDictionary *customer = [command argumentAtIndex:0];
    NSString *method = [command argumentAtIndex:1];
    NSDictionary *attributes = [command argumentAtIndex:2];
    
    [Localytics tagCustomerRegistered:[LLCustomer customerWithBlock:^(LLCustomerBuilder *builder) {
        builder.customerId = [customer valueForKey: @"customerId"];
        builder.firstName = [customer valueForKey: @"firstName"];
        builder.lastName = [customer valueForKey: @"lastName"];
        builder.fullName = [customer valueForKey: @"fullName"];
        builder.emailAddress = [customer valueForKey: @"emailAddress"];
    }] methodName: method attributes: attributes];
}

- (void)tagCustomerLoggedIn: (CDVInvokedUrlCommand *)command {
    NSDictionary *customer = [command argumentAtIndex:0];
    NSString *method = [command argumentAtIndex:1];
    NSDictionary *attributes = [command argumentAtIndex:2];
    
    // [Localytics tagCustomerRegistered:[LLCustomer customerWithBlock:^(LLCustomerBuilder *builder) {
    [Localytics tagCustomerLoggedIn:[LLCustomer customerWithBlock:^(LLCustomerBuilder *builder) {
        builder.customerId = [customer valueForKey: @"customerId"];
        builder.firstName = [customer valueForKey: @"firstName"];
        builder.lastName = [customer valueForKey: @"lastName"];
        builder.fullName = [customer valueForKey: @"fullName"];
        builder.emailAddress = [customer valueForKey: @"emailAddress"];
    }] methodName: method attributes: attributes];
}

- (void)tagCustomerLoggedOut: (CDVInvokedUrlCommand *)command {
    NSDictionary *attributes = [command argumentAtIndex:0];
    [Localytics tagCustomerLoggedOut:attributes];
}

- (void)tagContentViewed: (CDVInvokedUrlCommand *)command {
    NSString *contentName = [command argumentAtIndex:0];
    NSString *contentId = [command argumentAtIndex:1];
    NSString *contentType = [command argumentAtIndex:2];
    NSDictionary *attributes = [command argumentAtIndex:3];
    
    [Localytics tagContentViewed:contentName
                       contentId:contentId
                     contentType:contentType
                      attributes:attributes];
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

- (void)getIdentifier:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSNumber *identifier = [command argumentAtIndex:0];
        NSString *value = [Localytics valueForIdentifier:identifier];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getCustomerId:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        NSString *value = [Localytics customerId];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:value];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

#pragma mark Marketing

- (void)registerPush:(CDVInvokedUrlCommand *)command {
    if (NSClassFromString(@"UNUserNotificationCenter"))
    {
        UNAuthorizationOptions options = (UNAuthorizationOptionBadge | UNAuthorizationOptionSound |UNAuthorizationOptionAlert);
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:options
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  [[UIApplication sharedApplication] registerForRemoteNotifications];
                                  [Localytics didRequestUserNotificationAuthorizationWithOptions:options
                                                                                         granted:granted];
                              }];
        
    }
    else if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
    
    
}

/**
 * Set the badge number.
 */
- (void) setBadgeCount:(CDVInvokedUrlCommand *)command {
    NSArray* args = [command arguments];
    int number    = [[args objectAtIndex:0] intValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        [ [UIApplication sharedApplication] setApplicationIconBadgeNumber:number];
    });
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSLog( @"Handle push from foreground" );
    completionHandler(UNNotificationPresentationOptionAlert);
    // custom code to handle push while app is in the foreground
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler{
    
    if(![Localytics appKey]){
        _pendingNotification = response.notification.request.content.userInfo;
    }else{
        // do work in the UI thread here
        [Localytics didReceiveNotificationResponseWithUserInfo:response.notification.request.content.userInfo];
    }
    
    //    if (![@"less" isEqualToString:response.actionIdentifier]) {
    //        [Localytics didReceiveNotificationResponseWithUserInfo:response.notification.request.content.userInfo];
    //        completionHandler();
    //    }
    
    if ([@"subscribe" isEqualToString:response.actionIdentifier]) {
        NSString *ministryId = response.notification.request.content.userInfo[@"ministryId"];
        NSString *ministryName = response.notification.request.content.userInfo[@"ministryName"];
        NSMutableDictionary *notificationData = [[NSMutableDictionary alloc] init];
        if(ministryId != nil){
            [notificationData setValue:ministryId forKey:@"ministryId"];
        }
        [notificationData setValue:ministryName forKey:@"ministryName"];
        [notificationData setValue:@"subscribe" forKey:@"type"];
        double delayInSeconds =  [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive? 2.0:0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[NSNotificationCenter defaultCenter]postNotificationName:@"callSubscribe" object:nil userInfo:notificationData];
        });
    } else if ([@"listen" isEqualToString:response.actionIdentifier]) {
        NSString *ministryId = response.notification.request.content.userInfo[@"ministryId"];
        NSString *feedId = response.notification.request.content.userInfo[@"feedId"];
        NSString *ministryName = response.notification.request.content.userInfo[@"ministryName"];
        NSMutableDictionary *notificationData = [[NSMutableDictionary alloc] init];
        if(feedId != nil){
            [notificationData setValue:feedId forKey:@"feedId"];
        }
        if(ministryId != nil){
            [notificationData setValue:ministryId forKey:@"ministryId"];
        }
        [notificationData setValue:ministryName forKey:@"ministryName"];
        [notificationData setValue:@"listen" forKey:@"type"];
        double delayInSeconds =  [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive? 2.0:0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[NSNotificationCenter defaultCenter]postNotificationName:@"callSubscribe" object:nil userInfo:notificationData];
        });
    }else if ([@"more" isEqualToString:response.actionIdentifier]){
        NSDictionary *localyticsData = response.notification.request.content.userInfo[@"ll"];
        NSString *campingId = localyticsData[@"ca"];
        NSDictionary *aps = response.notification.request.content.userInfo[@"aps"];
        NSDictionary *alertData = aps[@"alert"];
        NSString *title = alertData[@"title"];
        NSString *body = alertData[@"body"];
        NSDictionary *notificationData = [[NSDictionary alloc]initWithObjectsAndKeys:campingId,@"campingId",title,@"title",body,@"body",@"more",@"type", nil];
        double delayInSeconds =  [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive? 2.0:0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[NSNotificationCenter defaultCenter]postNotificationName:@"callSubscribe" object:nil userInfo:notificationData];
        });
    }else if ([@"less" isEqualToString:response.actionIdentifier]){
        NSDictionary *localyticsData = response.notification.request.content.userInfo[@"ll"];
        NSDictionary *aps = response.notification.request.content.userInfo[@"aps"];
        NSDictionary *alertData = aps[@"alert"];
        NSString *title = alertData[@"title"];
        NSString *body = alertData[@"body"];
        NSString *campingId = localyticsData[@"ca"];
        NSDictionary *notificationData = [[NSDictionary alloc]initWithObjectsAndKeys:campingId,@"campingId",title,@"title",body,@"body",@"less",@"type", nil];
        double delayInSeconds =  [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive? 2.0:0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[NSNotificationCenter defaultCenter]postNotificationName:@"callSubscribe" object:nil userInfo:notificationData];
        });
    }else if ([@"listening" isEqualToString:response.actionIdentifier]){
        NSString *dataStr = response.notification.request.content.userInfo[@"data"];
        NSData *dataObj = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:dataObj options:0 error:nil];
        NSLog(@"%@",data);
        NSDictionary *notificationData = [[NSDictionary alloc]initWithObjectsAndKeys:data[@"clipId"],@"clipId",data[@"feedId"],@"feedId",@"Keep Listening",@"type", nil];
        double delayInSeconds =  [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive? 2.0:0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[NSNotificationCenter defaultCenter]postNotificationName:@"localNotificationHandler" object:nil userInfo:notificationData];
        });
    }else if ([@"nextPlay" isEqualToString:response.actionIdentifier]){
        NSString *dataStr = response.notification.request.content.userInfo[@"data"];
        NSData *dataObj = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:dataObj options:0 error:nil];
        NSLog(@"%@",data);
        NSDictionary *notificationData = [[NSDictionary alloc]initWithObjectsAndKeys:data[@"clipId"],@"clipId",data[@"feedId"],@"feedId",@"Play next",@"type", nil];
        double delayInSeconds =  [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive? 2.0:0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[NSNotificationCenter defaultCenter]postNotificationName:@"localNotificationHandler" object:nil userInfo:notificationData];
        });
    }else{
        NSLog( @"Handle push from background or closed" );
        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
        NSLog(@"%@", response.notification.request.content.userInfo);
        [[Branch getInstance] handlePushNotification:response.notification.request.content.userInfo];
    }
    
    completionHandler();
}

- (void)setPushDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
}
- (void)isPushDisabled:(CDVInvokedUrlCommand *)command {
    // No-Op
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
        [Localytics setOptions:@{@"session_timeout": timeout}];
    }
}

- (void)getSessionTimeoutInterval:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        // FIXME: There is no way to get session timeout interval
        NSTimeInterval value = 30;
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
