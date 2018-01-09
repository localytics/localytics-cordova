Localytics for PhoneGap/Cordova
========

## Version

This version of the PhoneGap/Cordova SDK wraps v4.5.1 of the Localytics Android and v4.4.1 of the Localytics iOS SDKs.

## Supported Versions

The PhoneGap/Cordova SDK was tested on Cordova v7.1.0 with Android v6.3.0 and iOS v4.5.4.

## Installation

```
cordova plugin add localytics-cordova
```

## Integration

To install Localytics for Phonegap, you'll need to take three basic steps.

1. Set up your app key for each platform.

2. Integrate your app with Localytics.

3. Set up and register for Push notifications, if necessary.


### 1. Set up app keys

App keys allow you to separate data. Create one set of app keys for each app, so you can focus on one app at a time in the Dashboard.

You’ll need an app key for each device platform (iOS and Android). Separate test data from production data by using separate app keys.

When you release your app, make sure your production app key is in it! You can feel free to delete your test app keys and make new ones whenever you want.

#### iOS
In your Info.plist, add the following within \<dict\> node:

```xml
<key>LocalyticsAppKey</key>
<string>YOUR_APP_KEY</string>
```

> Replace YOUR\_APP\_KEY with your Localytics app key.

Next, follow the steps in [configuring test mode](https://docs.localytics.com/dev/ios.html#test-mode-ios) to set up test mode.

#### Android

In AndroidManifest.xml, add the following under \<application\> node:

```xml
<meta-data
	android:name="LOCALYTICS_APP_KEY"
	android:value="YOUR_APP_KEY" />
```

> Replace YOUR\_APP\_KEY with your Localytics app key.

Next, follow the remaining steps in [modifying AndroidManifest.xml](https://docs.localytics.com/dev/android.html#modify-androidmanifest-android) to configure test mode and install referrals.

### 2. Automatic or manual integration?

With automatic integration, the plugin automatically opens, closes, and uploads sessions when the app goes into the background and foreground.

With manual integration, you have full control of open, close, and upload events, but you'll need to listen for pause and resume events and handle opens, closes, and uploading sessions manually.

Regardless of the integration method you choose, start by adding the following listener:

```javascript
document.addEventListener('deviceready', this.onDeviceReady, false);
```

#### Automatic integration

Add the following for automatic integration.

```javascript
onDeviceReady: function() {
	Localytics.autoIntegrate(); // You can include your app key here if you don't want to use the Info.plist or AndroidManifst methods
	Localytics.openSession(); // For Android, we might have missed the call to open a session by the time autoIntegrate is called. Don't worry, calling this will not open a second session.
}
```

#### Manual Integration

Add the following for manual integration.

```javascript
onDeviceReady: function() {
	document.addEventListener("resume", app.onResume, false);
	document.addEventListener("pause", app.onPause, false);
	Localytics.integrate();
	Localytics.openSession();                
	Localytics.upload();
},

onResume: function () {
	Localytics.openSession();
	Localytics.upload();
},

onPause: function () {
	Localytics.closeSession();
	Localytics.upload();
}
```

### 3. Set up and register for push notifications

iOS uses Apple Push Notification (APN) while Android uses Google Cloud Messaging (GCM). Follow the instructions for each respective push notification service to set up the necessary configurations and upload the certificate to the Localytics Dashboard before continuing with these instructions.

#### iOS

[Follow these instructions to set up push notifications for your app.](https://docs.localytics.com/dev/ios.html#enable-background-modes-ios)

Next, [follow these instructions to handle opened notification on iOS 10+](https://docs.localytics.com/dev/ios.html#handle-opened-remote-notifications-ios).

Afterwards, simply call the following when you want to prompt for notifications.

```javascript
Localytics.registerPush();
```

> registerPush relies on "CDVRemoteNotification", "CDVRemoteNotificationError" and "CDVPluginHandleOpenURLNotification" broadcasted by cordova's AppDelegate.m class. If you change the AppDelegate, ensure to rebroadcast these events from the appropriate handlers to ensure correct behavior. Alternatively, you can also integrate manually through native code instead.

#### Android

[Follow these instructions to set up push notifications for your app.](https://docs.localytics.com/dev/android.html#gcm-integration-android)

Next, [follow these instructions to modify your AndroidManifest.xml](https://docs.localytics.com/dev/android.html#gcm-modify-androidmanifest-push-android).

Finally, inside your \<application\> tag, add:

```xml
<meta-data
	android:name="com.localytics.android_push_sender_id"
	android:value="\ YOUR_PUSH_ID" />
```

> replace YOUR_PUSH_ID with your GCM sender ID. **The "\\ " before the push id is intentional (ie. android:value="\ 1234567")**.

Afterwards, simply call the following function after the integration code in the previous step.

```javascript
Localytics.registerPush();
```


After integrating, tagging events and any further instrumentation should be done inside the web app.

## Usage

For full method documentation, see [localytics.js](www/localytics.js)

```javascript
// Integration
Localytics.integrate(); // uses Info.plist or AndroidManifest.xml value
Localytics.integrate("YOUR_APP_KEY");
Localytics.autoIntegrate(); // uses Info.plist or AndroidManifest.xml value
Localytics.autoIntegrate("YOUR_APP_KEY");
Localytics.upload();
Localytics.openSession();
Localytics.closeSession();

// Analytics
Localytics.setOptedOut(true);
Localytics.isOptedOut(
	function success(result) {
		var optedOut = result;
});
Localytics.tagEvent("Team Favorited", {"Team Name": "Celtics"}, 0);
Localytics.tagPurchased("Shirt", "sku-123", "Apparel", 10, {"Key": "Value"});
Localytics.tagAddedToCart("Shirt", "sku-123", "Apparel", 10, {"Key": "Value"});
Localytics.tagStartedCheckout(25, 12, {"Key": "Value"});
Localytics.tagCompletedCheckout(100, 25, {"Key": "Value"});
Localytics.tagContentViewed("Top 10", "e8z7319zbe", "Article", {"Key": "Value"});
Localytics.tagSearched("Celtics", "Sports", 12, {"Key": "Value"});
Localytics.tagShared("Top 10", "e8z7319zbe", "Article", "Facebook", {"Key": "Value"});
Localytics.tagContentRated("Top 10", "e8z7319zbe", "Article", 8, {"Key": "Value"});
Localytics.tagCustomerRegistered({"customerId": "37bdy1pd", "firstName": "Jane", "lastName": "Smith", "fullName": "Jane Smith", "emailAddress": "jasmith@test.com"}, "Twitter", {"Key": "Value"});
Localytics.tagCustomerLoggedIn({"customerId": "37bdy1pd", "firstName": "Jane", "lastName": "Smith", "fullName": "Jane Smith", "emailAddress": "jasmith@test.com"}, "Native", {"Key": "Value"});
Localytics.tagCustomerLoggedOut({"Key": "Value"});
Localytics.tagInvited("SMS", {"Key": "Value"});
Localytics.tagInAppImpression(251361, "click");
Localytics.tagInboxImpression(829371, "dismiss");
Localytics.tagPushToInboxImpression(283913, true); // boolean param only relevant for iOS
Localytics.tagPlacesPushReceived(9361841);
Localytics.tagPlacesPushOpened(279135, "go");
Localytics.tagScreen("Favorites");
Localytics.setCustomDimension(0, "Logged In");
Localytics.getCustomDimension(0,
	function success(result) {
		var loggedIn = result;
});

// Profiles
Localytics.setProfileAttribute("Hometown", "New York", "app");
Localytics.setProfileAttribute("States Visited", ["Arizona", "Virginia"], "org");
Localytics.setProfileAttribute("Age", 25, "app");
Localytics.setProfileAttribute("Favorite Numbers", [20, 9], "org");
Localytics.setProfileAttribute("Last Purchase Date", "2017-06-20", "app");
Localytics.setProfileAttribute("Upcoming Milestone Dates", ["2017-10-20", "2017-11-18"], "org");
Localytics.addProfileAttributesToSet("States Visited", ["Arizona", "Virginia"], "org");
Localytics.addProfileAttributesToSet("Favorite Numbers", [20, 9], "app");
Localytics.addProfileAttributesToSet("Upcoming Milestone Dates", ["2017-10-20", "2017-11-18"], "org");
Localytics.removeProfileAttributesFromSet("States Visited", ["Arizona", "Virginia"], "org");
Localytics.removeProfileAttributesFromSet("Favorite Numbers", [20, 9], "app");
Localytics.removeProfileAttributesFromSet("Upcoming Milestone Dates", ["2017-10-20", "2017-11-18"], "org");
Localytics.incrementProfileAttribute("Age", 1, "org");
Localytics.decrementProfileAttribute("Days Until Graduation", 1, "app");
Localytics.deleteProfileAttribute("States Visited", "org");
Localytics.setCustomerEmail("john@smith.com");
Localytics.setCustomerFirstName("John");
Localytics.setCustomerLastName("Smith");
Localytics.setCustomerFullName("Jonathan Smith, III");

// User Information
Localytics.setIdentifier("Hair Color", "Black");
Localytics.getIdentifier("Hair Color",
	function success(result) {
		var hairColor = result;
});
Localytics.setCustomerId("3neRKTxbNWYKM4NJ");
Localytics.getCustomerId(
	function success(result) {
		var customerId = result;
});
Localytics.setLocation(-120.5, 76.12);

// Marketing
Localytics.registerPush();
Localytics.setPushToken("1bFZo1K3zs0HcBGs1K0-loHOoor0YOgBqm2w9Ttd8ZGPyZ");
Localytics.getPushToken(
	function success(result) {
		var pushToken = result;
});
Localytics.setNotificationsDisabled(true); // Android only
Localytics.areNotificationsDisabled(
	function success(result) {
		var disabled = result;
});  // Android only
Localytics.setDefaultNotificationChannel("Chat", "Chat messages from friends");  // Android only
Localytics.setTestModeEnabled(true);
Localytics.isTestModeEnabled(
	function success(result) {
		var enabled = result;
});
Localytics.setInAppMessageDismissButtonImageWithName("DismissButton"); // iOS only
Localytics.setInAppMessageDismissButtonHidden(true);
Localytics.setInAppMessageDismissButtonLocation("right");
Localytics.getInAppMessageDismissButtonLocation(
	function success(result) {
		var location = result;
});
Localytics.triggerInAppMessage("Item Purchased", {"Item Name": "Stickers"});
Localytics.triggerInAppMessagesForSessionStart();
Localytics.dismissCurrentInAppMessage();
Localytics.setInAppAdIdParameterEnabled(false); // iOS only
Localytics.isInAppAdIdParameterEnabled(
	function success(result) {
		var enabled = result;
}); // iOS only
Localytics.getInboxCampaigns(
	function success(result) {
		var campaigns = result;
});
Localytics.getAllInboxCampaigns(
	function success(result) {
		var campaigns = result;
});
Localytics.refreshInboxCampaigns(
	function success(result) {
		var campaigns = result;
});
Localytics.refreshAllInboxCampaigns(
	function success(result) {
		var campaigns = result;
});
Localytics.setInboxCampaignRead(72613, true);
Localytics.getInboxCampaignsUnreadCount(
	function success(result) {
		var count = result;
});
Localytics.inboxListItemTapped(718351);
Localytics.triggerPlacesNotification(228329);

// Location
Localytics.setLocationMonitoringEnabled(true);
Localytics.getGeofencesToMonitor(-120.72, 76.85,
	function success(result) {
		var geofences = result;
});
Localytics.triggerRegion({"uniqueId" : "office"}, "enter");
Localytics.triggerRegions([{"uniqueId" : "office"}, {"uniqueId" : "home"}], "exit");

// Developer Options
Localytics.setLoggingEnabled(true);
Localytics.isLoggingEnabled(
	function success(result) {
		var enabled = result;
});
Localytics.setOptions({"session_timeout": 30});
Localytics.setOption("session_timeout", 20);
Localytics.redirectLogsToDisk(true); // Android only
Localytics.getInstallId(
	function success(result) {
		var id = result;
});
Localytics.getAppKey(
	function success(result) {
		var key = result;
});
Localytics.getLibraryVersion(
	function success(result) {
		var version = result;
});
```

### Callbacks

When setting a listener, the `success` function will be called multiple times.

```javascript
// Analytics
Localytics.setAnalyticsListener(
	function success(result) {
		// result can be one of:
		// - {"method": "localyticsSessionWillOpen", "params": {"isFirst": false, "isResume": true, "isUpgrade": false}}
		// - {"method": "localyticsSessionDidOpen", "params": {"isFirst": false, "isResume": true, "isUpgrade": false}}
		// - {"method": "localyticsDidTagEvent", "params": {"name": "Item Purchased", "attributes": {"key": "value"}, "customerValueIncrease": 0}}
		// - {"method": "localyticsSessionWillClose"}
});
Localytics.removeAnalyticsListener();

// Messaging
Localytics.setMessagingListener(
	function success(result) {
		// result can be one of:
		// - {"method": "localyticsShouldShowInAppMessage", "params": {"campaign": {...}, "shouldShow": true}}
		// - {"method": "localyticsShouldDelaySessionStartInAppMessages", "params": {"shouldDelay": false}}
		// - {"method": "localyticsWillDisplayInAppMessage", "params": {"campaign": {...}}}
		// - {"method": "localyticsDidDisplayInAppMessage"}
		// - {"method": "localyticsWillDismissInAppMessage"}
		// - {"method": "localyticsDidDismissInAppMessage"}
		// - {"method": "localyticsShouldShowPlacesPushNotification", "params": {"campaign": {...}, "shouldShow": true}}
		// - {"method": "localyticsWillShowPlacesPushNotification", "params": {"campaign": {...}}}
});
Localytics.removeMessagingListener();

// Location
Localytics.setLocationListener(
	function success(result) {
		// result can be one of:
		// - {"method": "localyticsDidUpdateLocation", "params": {"location": {"latitude": -120.2, "longitude": 72.23}}}
		// - {"method": "localyticsDidUpdateMonitoredGeofences", "params": {"added": [...], "removed": [...]}}
		// - {"method": "localyticsDidTriggerRegions", "params": {"regions": [...], "event": "enter"}}
});
Localytics.removeLocationListener();
```

### Messaging Configuration

Global In-App, Places, and Push (for Android) configuration is available. Note: You
must set a MessagingListener before using these APIs.

#### iOS
```javascript
var inAppConfig = {
  "dismissButtonLocation": "right",
  /*"dismissButtonHidden": true,*/
  /*"shouldShow": false, // global suppression */
  /*"diy": true, // Manually handle display and impression tagging. Results in localyticsDiyInAppMessage Messaging callback */
  /*"delaySessionStart": true, // Must be set in AppDelegate as well to handle initial launch */
  /*"dismissButtonImageName": "custom_image", // Must be in app's Bundle */
  "aspectRatio": 0.7,
  "backgroundAlpha": 0.75,
  "offset": 20
};
var placesConfig = {
  "alertAction": "Tap Here",
  "alertTitle": "My Places App",
  "hasAction": true,
  /*"alertLaunchImage": "custom_image", // Must be in app's Bundle */
  /*"category": "some_category", */
  /*"soundName": "alert.mp3", // Must be in app's Bundle */
  /*"shouldShow": false, // global suppression */
  /*"diy": true, // Manually handle display and impression tagging. Results in localyticsDiyPlacesPushNotification Messaging callback */
  "applicationIconBadgeNumber": 5
};
var placesUserNotificationConfig = {
  "title": "My Places App",
  "subtitle": "My Places App Subtitle",
  /*"launchImageName": "custom_image", // Must be in app's Bundle */
  /*"sound": "alert.mp3", // Must be in app's Bundle */
  /*"shouldShow": false, // global suppression */
  /*"diy": true, // Manually handle display and impression tagging. Results in localyticsDiyPlacesPushNotification Messaging callback */
  "badge": "10"
};
Localytics.setInAppMessageConfiguration(inAppConfig);
Localytics.setPlacesMessageConfiguration(placesConfig);
// If iOS 10+, use:
Localytics.setPlacesMessageConfiguration(placesUserNotificationConfig);
```

#### Android
```javascript
var inAppConfig = {
  "dismissButtonLocation": "right",
  /*"dismissButtonHidden": true,*/
  /*"shouldShow": false, // global suppression */
  /*"diy": true, // Manually handle display and impression tagging. Results in localyticsDiyInAppMessage Messaging callback */
  /*"delaySessionStart": true, // Must be set in MainApplication.java as well to handle initial launch */
  "aspectRatio": 0.7,
  "backgroundAlpha": 0.75,
  "bannerOffsetDps": 20
};
var pushConfig = {
  "category": "social", // from android.app.Notification.CATEGORY_SOCIAL
  "color": -16711936, // from android.graphics.Color.GREEN
  "contentInfo": "10",
  "contentTitle": "My App",
  "defaults": ["sound", "lights"], // valid values: "all" or combination of "sound", "lights", "vibrate"
  /*"sound": "android.resource://com.my.app/notif.mp3", // sound URI. ignored if "sound" used in defaults */
  /*"vibrate": [0, 100, 200, 300], // vibration pattern. ignored if "vibrate" used in defaults */
  /*"shouldShow": false, // global suppression */
  "priority": 0 // from android.support.v4.app.NotificationCompat.PRIORITY_DEFAULT
};
var placesConfig = {
  "category": "promo", // from android.app.Notification.CATEGORY_PROMO
  "color": -16776961, // from android.graphics.Color.BLUE
  "contentInfo": "5",
  "contentTitle": "My Places App",
  "defaults": ["all"], // valid values: "all" or combination of "sound", "lights", "vibrate"
  /*"sound": "android.resource://com.my.app/notif.mp3", // sound URI. ignored if "sound" used in defaults */
  /*"vibrate": [0, 100, 200, 300], // vibration pattern. ignored if "vibrate" used in defaults */
  /*"shouldShow": false, // global suppression */
  /*"diy": true, // Manually handle display and impression tagging. Results in localyticsDiyPlacesPushNotification Messaging callback */
  "priority": 1 // from android.support.v4.app.NotificationCompat.PRIORITY_HIGH
};
Localytics.setInAppMessageConfiguration(inAppConfig);
Localytics.setPushMessageConfiguration(pushConfig);
Localytics.setPlacesMessageConfiguration(placesConfig);
```

## Sample App

A sample template app is available at [https://github.com/localytics/cordova-template-app](https://github.com/localytics/cordova-template-app).
