//
//  LocalyticsPlugin.h
//
//  Copyright 2015 Localytics. All rights reserved.
//

#import <Cordova/CDVPlugin.h>

@class LLRegion;
@class LLGeofence;
@class LLInAppCampaign;
@class LLPlacesCampaign;

typedef NS_ENUM(NSUInteger, LLInAppMessageDismissButtonLocation);

@interface LocalyticsPlugin : CDVPlugin

- (void)integrate:(CDVInvokedUrlCommand *)command;
- (void)autoIntegrate:(CDVInvokedUrlCommand *)command;
- (void)openSession:(CDVInvokedUrlCommand *)command;
- (void)closeSession:(CDVInvokedUrlCommand *)command;
- (void)upload:(CDVInvokedUrlCommand *)command;

- (void)setOptedOut:(CDVInvokedUrlCommand *)command;
- (void)isOptedOut:(CDVInvokedUrlCommand *)command;
- (void)tagEvent:(CDVInvokedUrlCommand *)command;
- (void)tagPurchased:(CDVInvokedUrlCommand *)command;
- (void)tagAddedToCart:(CDVInvokedUrlCommand *)command;
- (void)tagStartedCheckout:(CDVInvokedUrlCommand *)command;
- (void)tagCompletedCheckout:(CDVInvokedUrlCommand *)command;
- (void)tagContentViewed:(CDVInvokedUrlCommand *)command;
- (void)tagSearched:(CDVInvokedUrlCommand *)command;
- (void)tagShared:(CDVInvokedUrlCommand *)command;
- (void)tagContentRated:(CDVInvokedUrlCommand *)command;
- (void)tagCustomerRegistered:(CDVInvokedUrlCommand *)command;
- (void)tagCustomerLoggedIn:(CDVInvokedUrlCommand *)command;
- (void)tagCustomerLoggedOut:(CDVInvokedUrlCommand *)command;
- (void)tagInvited:(CDVInvokedUrlCommand *)command;
- (void)tagInAppImpression:(CDVInvokedUrlCommand *)command;
- (void)tagInboxImpression:(CDVInvokedUrlCommand *)command;
- (void)tagPushToInboxImpression:(CDVInvokedUrlCommand *)command;
- (void)tagPlacesPushReceived:(CDVInvokedUrlCommand *)command;
- (void)tagPlacesPushOpened:(CDVInvokedUrlCommand *)command;
- (void)tagScreen:(CDVInvokedUrlCommand *)command;
- (void)setCustomDimension:(CDVInvokedUrlCommand *)command;
- (void)getCustomDimension:(CDVInvokedUrlCommand *)command;
- (void)setAnalyticsListener:(CDVInvokedUrlCommand *)command;
- (void)removeAnalyticsListener:(CDVInvokedUrlCommand *)command;

- (void)setProfileAttribute:(CDVInvokedUrlCommand *)command;
- (void)addProfileAttributesToSet:(CDVInvokedUrlCommand *)command;
- (void)removeProfileAttributesFromSet:(CDVInvokedUrlCommand *)command;
- (void)incrementProfileAttribute:(CDVInvokedUrlCommand *)command;
- (void)decrementProfileAttribute:(CDVInvokedUrlCommand *)command;
- (void)deleteProfileAttribute:(CDVInvokedUrlCommand *)command;
- (void)setCustomerEmail:(CDVInvokedUrlCommand *)command;
- (void)setCustomerFirstName:(CDVInvokedUrlCommand *)command;
- (void)setCustomerLastName:(CDVInvokedUrlCommand *)command;
- (void)setCustomerFullName:(CDVInvokedUrlCommand *)command;

- (void)setIdentifier:(CDVInvokedUrlCommand *)command;
- (void)getIdentifier:(CDVInvokedUrlCommand *)command;
- (void)setCustomerId:(CDVInvokedUrlCommand *)command;
- (void)getCustomerId:(CDVInvokedUrlCommand *)command;
- (void)setLocation:(CDVInvokedUrlCommand *)command;

- (void)registerPush:(CDVInvokedUrlCommand *)command;
- (void)setPushToken:(CDVInvokedUrlCommand *)command;
- (void)getPushToken:(CDVInvokedUrlCommand *)command;
- (void)setNotificationsDisabled:(CDVInvokedUrlCommand *)command;
- (void)areNotificationsDisabled:(CDVInvokedUrlCommand *)command;
- (void)setDefaultNotificationChannel:(CDVInvokedUrlCommand *)command;
- (void)setPushMessageConfiguration:(CDVInvokedUrlCommand *)command;
- (void)setTestModeEnabled:(CDVInvokedUrlCommand *)command;
- (void)isTestModeEnabled:(CDVInvokedUrlCommand *)command;
- (void)setInAppMessageDismissButtonImageWithName:(CDVInvokedUrlCommand *)command;
- (void)setInAppMessageDismissButtonHidden:(CDVInvokedUrlCommand *)command;
- (void)setInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command;
- (void)getInAppMessageDismissButtonLocation:(CDVInvokedUrlCommand *)command;
- (void)triggerInAppMessage:(CDVInvokedUrlCommand *)command;
- (void)triggerInAppMessagesForSessionStart:(CDVInvokedUrlCommand *)command;
- (void)dismissCurrentInAppMessage:(CDVInvokedUrlCommand *)command;
- (void)setInAppMessageConfiguration:(CDVInvokedUrlCommand *)command;
- (void)isInAppAdIdParameterEnabled:(CDVInvokedUrlCommand *)command;
- (void)setInAppAdIdParameterEnabled:(CDVInvokedUrlCommand *)command;
- (void)getInboxCampaigns:(CDVInvokedUrlCommand *)command;
- (void)getAllInboxCampaigns:(CDVInvokedUrlCommand *)command;
- (void)refreshInboxCampaigns:(CDVInvokedUrlCommand *)command;
- (void)refreshAllInboxCampaigns:(CDVInvokedUrlCommand *)command;
- (void)setInboxCampaignRead:(CDVInvokedUrlCommand *)command;
- (void)getInboxCampaignsUnreadCount:(CDVInvokedUrlCommand *)command;
- (void)inboxListItemTapped:(CDVInvokedUrlCommand *)command;
- (void)triggerPlacesNotification:(CDVInvokedUrlCommand *)command;
- (void)setPlacesMessageConfiguration:(CDVInvokedUrlCommand *)command;
- (void)setMessagingListener:(CDVInvokedUrlCommand *)command;
- (void)removeMessagingListener:(CDVInvokedUrlCommand *)command;

- (void)setLocationMonitoringEnabled:(CDVInvokedUrlCommand *)command;
- (void)getGeofencesToMonitor:(CDVInvokedUrlCommand *)command;
- (void)triggerRegion:(CDVInvokedUrlCommand *)command;
- (void)triggerRegions:(CDVInvokedUrlCommand *)command;
- (void)setLocationListener:(CDVInvokedUrlCommand *)command;
- (void)removeLocationListener:(CDVInvokedUrlCommand *)command;

- (void)setLoggingEnabled:(CDVInvokedUrlCommand *)command;
- (void)isLoggingEnabled:(CDVInvokedUrlCommand *)command;
- (void)setOptions:(CDVInvokedUrlCommand *)command;
- (void)setOption:(CDVInvokedUrlCommand *)command;
- (void)redirectLogsToDisk:(CDVInvokedUrlCommand *)command;
- (void)getInstallId:(CDVInvokedUrlCommand *)command;
- (void)getAppKey:(CDVInvokedUrlCommand *)command;
- (void)getLibraryVersion:(CDVInvokedUrlCommand *)command;

+ (NSArray<NSDictionary<NSString *, NSObject *> *> *)dictionaryArrayFromRegions:(NSArray<LLRegion *> *)regions;
+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromGeofence:(LLGeofence *)geofence;
+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromInAppCampaign:(LLInAppCampaign *)campaign;
+ (NSDictionary<NSString *, NSObject *> *)dictionaryFromPlacesCampaign:(LLPlacesCampaign *)campaign;
+ (LLInAppMessageDismissButtonLocation)locationFrom:(NSString *)location;

@end
