//
//  Localytics.js
//
//  Copyright 2017 Localytics. All rights reserved.
//

var Localytics = function () {
}

/*******************
 * Integration
 ******************/

// Initializes Localytics without opening a session
// localyticsKey = Localytics App ID as a string
Localytics.prototype.integrate = function (localyticsKey) {
	cordova.exec(null, null, "LocalyticsPlugin", "integrate", [localyticsKey]);
}

// Initializes Localytics by hooking into the activity lifecycle events of the app
// localyticsKey = Localytics App ID as a string
Localytics.prototype.autoIntegrate = function(localyticsKey) {
	cordova.exec(null, null, "LocalyticsPlugin", "autoIntegrate", [localyticsKey]);
}

// Initiates an upload
// This should typically be called on deviceready, resume, and pause events
Localytics.prototype.upload = function() {
	cordova.exec(null, null, "LocalyticsPlugin", "upload", []);
}

// Opens a session
// This should typically be called on deviceready and resume events
Localytics.prototype.openSession = function() {
	cordova.exec(null, null, "LocalyticsPlugin", "openSession", []);
}

// Closes a session
// This should typically be called on pause events
Localytics.prototype.closeSession = function() {
	cordova.exec(null, null, "LocalyticsPlugin", "closeSession", []);
}

/*******************
 * Analytics
 ******************/

// Sets opted out
// enabled = boolean
Localytics.prototype.setOptedOut = function (enabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setOptedOut", [enabled]);
}

// Gets opted out status
// successCallback = callback function for result
Localytics.prototype.isOptedOut = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "isOptedOut", []);
}

// Tags an event
// event = Name of the event
// attributes = a hash of key/value pairs containing the event attributes
// customerValueIncrease = customer value increase as an int
Localytics.prototype.tagEvent = function (event, attributes, customerValueIncrease) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagEvent", [event, attributes, customerValueIncrease]);
}

// A standard event to tag a single item purchase event (after the action has occurred)
// itemName = The name of the item purchased (optional, can be null)
// itemId = A unique identifier of the item being purchased, such as a SKU (optional, can be null)
// itemType = The type of item (optional, can be null)
// itemPrice = The price of the item (optional, can be null). Will be added to customer lifetime value. Try to use lowest possible unit, such as cents for US currency.
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagPurchased = function (itemName, itemId, itemType, itemPrice, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagPurchased", [itemName, itemId, itemType, itemPrice, attributes]);
}

// A standard event to tag the addition of a single item to a cart (after the action has occurred)
// itemName = The name of the item purchased (optional, can be null)
// itemId = A unique identifier of the item being purchased, such as a SKU (optional, can be null)
// itemType = The type of item (optional, can be null)
// itemPrice = The price of the item (optional, can be null). Will be added to customer lifetime value. Try to use lowest possible unit, such as cents for US currency.
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagAddedToCart = function (itemName, itemId, itemType, itemPrice, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagAddedToCart", [itemName, itemId, itemType, itemPrice, attributes]);
}

// A standard event to tag the start of the checkout process (after the action has occurred)
// totalPrice = The total price of all the items in the cart (optional, can be null). Will NOT be added to customer lifetime value.
// itemCount = Total count of items in the cart (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagStartedCheckout = function (totalPrice, itemCount, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagStartedCheckout", [totalPrice, itemCount, attributes]);
}

// A standard event to tag the conclusions of the checkout process (after the action has occurred)
// totalPrice = The total price of all the items in the cart (optional, can be null). Will be added to customer lifetime value. Try to use lowest possible unit, such as cents for US currency.
// itemCount = Total count of items in the cart (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagCompletedCheckout = function (totalPrice, itemCount, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagCompletedCheckout", [totalPrice, itemCount, attributes]);
}

// A standard event to tag the viewing of content (after the action has occurred)
// contentName = The name of the content being viewed (such as article name) (optional, can be null)
// contentId = A unique identifier of the content being viewed (optional, can be null)
// contentType = The type of content (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagContentViewed = function (contentName, contentId, contentType, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagContentViewed", [contentName, contentId, contentType, attributes]);
}

// A standard event to tag a search event (after the action has occurred)
// queryText = The query user for the search (optional, can be null)
// contentType = The type of content (optional, can be null)
// resultCount = The number of results returned by the query (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagSearched = function (queryText, contentType, resultCount, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagSearched", [queryText, contentType, resultCount, attributes]);
}

// A standard event to tag a share event (after the action has occurred)
// contentName = The name of the content being viewed (such as article name) (optional, can be null)
// contentId = A unique identifier of the content being viewed (optional, can be null)
// contentType = The type of content (optional, can be null)
// methodName = The method by which the content was shared such as Twitter, Facebook, Native (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagShared = function (contentName, contentId, contentType, methodName, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagShared", [contentName, contentId, contentType, methodName, attributes]);
}

// A standard event to tag the rating of content (after the action has occurred)
// contentName = The name of the content being viewed (such as article name) (optional, can be null)
// contentId = A unique identifier of the content being viewed (optional, can be null)
// contentType = The type of content (optional, can be null)
// rating = A rating of the content (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagContentRated = function (contentName, contentId, contentType, rating, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagContentRated", [contentName, contentId, contentType, rating, attributes]);
}

// A standard event to tag the registration of a user (after the action has occurred)
// customer = An object providing information about the customer that registered (optional, can be null)
// methodName = The method by which the user was registered such as Twitter, Facebook, Native (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagCustomerRegistered = function (customer, methodName, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagCustomerRegistered", [customer, methodName, attributes]);
}

// A standard event to tag the logging in of a user (after the action has occurred)
// customer = An object providing information about the customer that registered (optional, can be null)
// methodName = The method by which the user was registered such as Twitter, Facebook, Native (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagCustomerLoggedIn = function (customer, methodName, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagCustomerLoggedIn", [customer, methodName, attributes]);
}

// A standard event to tag the logging out of a user (after the action has occurred)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagCustomerLoggedOut = function (attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagCustomerLoggedOut", [attributes]);
}

// A standard event to tag the invitation of a user (after the action has occured)
// methodName = The method by which the user was invited such as Twitter, Facebook, Native (optional, can be null)
// attributes = Any additional attributes to attach to this event (optional, can be null)
Localytics.prototype.tagInvited = function (methodName, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagInvited", [methodName, attributes]);
}

// A standard event to tag an In-App impression
// campaignId = The In-App campaign ID for which to tag an impression
// impressionType = "click", "dismiss", or a custom action
Localytics.prototype.tagInAppImpression = function (campaignId, action) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagInAppImpression", [campaignId, action]);
}

// A standard event to tag an Inbox impression
// campaignId = The Inbox campaign ID for which to tag an impression
// impressionType = "click", "dismiss", or a custom action
Localytics.prototype.tagInboxImpression = function (campaignId, action) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagInboxImpression", [campaignId, action]);
}

// A standard event to tag a Push to Inbox impression
// campaignId = The Inbox campaign ID for which to tag an impression
// success = Whether or not the deep link was successful (iOS only)
Localytics.prototype.tagPushToInboxImpression = function (campaignId, success) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagPushToInboxImpression", [campaignId, success]);
}

// A standard event to tag a Places Push Received
// campaignId = The Places campaign ID for which to tag an event
Localytics.prototype.tagPlacesPushReceived = function (campaignId) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagPlacesPushReceived", [campaignId]);
}

// A standard event to tag a Places Push Opened
// campaignId = The Places campaign ID for which to tag an event
// action = The title of the button that was pressed. This property will be passed
// as the value of the 'Action' attribute ('Click' will be used if null).
Localytics.prototype.tagPlacesPushOpened = function (campaignId, action) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagPlacesPushOpened", [campaignId, action]);
}

// Tags a screen
// Call this when a screen is displayed
// screen = screen name as a string
Localytics.prototype.tagScreen = function (screen) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagScreen", [screen]);
}

// Sets a custom dimension
// index = dimension index as an int
// value = dimension value as a string
Localytics.prototype.setCustomDimension = function (index, value) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomDimension", [index, value]);
}

// Gets a custom dimension
// index = dimension index as an int
// successCallback = callback function for result
Localytics.prototype.getCustomDimension = function (index, successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getCustomDimension", [index]);
}

// Set a listener that will be notified of certain analytics callbacks:
// successCallback = callback function for result
Localytics.prototype.setAnalyticsListener = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "setAnalyticsListener", []);
}

// Remove the listener and no longer be notified of certain analytics callbacks:
Localytics.prototype.removeAnalyticsListener = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "removeAnalyticsListener", []);
}

/*******************
 * Profiles
 ******************/

// Set a customer profile attribute
// name = The attribute name
// value = The attribute value (cannot be null)
// scope = The scope of the attribute (app or org)
Localytics.prototype.setProfileAttribute = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "setProfileAttribute", [name, value, scope]);
}

// Add a set of values to a customer profile attribute
// name = The attribute name
// value = The attribute value array (cannot be null)
// scope = The scope of the attribute (app or org)
Localytics.prototype.addProfileAttributesToSet = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "addProfileAttributesToSet", [name, value, scope]);
}

// Remove a set of values to a customer profile attribute
// name = The attribute name
// value = The attribute value array (cannot be null)
// scope = The scope of the attribute (app or org)
Localytics.prototype.removeProfileAttributesFromSet = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "removeProfileAttributesFromSet", [name, value, scope]);
}

// Increment the value of a customer profile attribute by a specified amount
// name = The attribute name
// value = The amount by which to increment the value
// scope = The scope of the attribute (app or org)
Localytics.prototype.incrementProfileAttribute = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "incrementProfileAttribute", [name, value, scope]);
}

// Decrement the value of a customer profile attribute by a specified amount
// name = The attribute name
// value = The amount by which to decrement the value
// scope = The scope of the attribute (app or org)
Localytics.prototype.decrementProfileAttribute = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "decrementProfileAttribute", [name, value, scope]);
}

// Delete a customer profile attribute
// name = The attribute name
// scope = The scope of the attribute (app or org)
Localytics.prototype.deleteProfileAttribute = function (name, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "deleteProfileAttribute", [name, scope]);
}

// Set customer email address
// email = customer email as a string (ie, "johndoe@company.com")
Localytics.prototype.setCustomerEmail = function (email) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerEmail", [email]);
}

// Set customer first name
// firstName = customer first name as a string (ie, "John")
Localytics.prototype.setCustomerFirstName = function (firstName) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerFirstName", [firstName]);
}

// Set customer last name
// lastName = customer last name as a string (ie, "Doe")
Localytics.prototype.setCustomerLastName = function (lastName) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerLastName", [lastName]);
}

// Set customer full name
// fullName = customer full name as a string (ie, "John Doe")
Localytics.prototype.setCustomerFullName = function (fullName) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerFullName", [fullName]);
}

/*******************
 * User Information
 ******************/

// Gets a custom idenitifer
// key = identifier name as a string
// value = identifier value as a string
// successCallback = callback function for result
Localytics.prototype.getIdentifier = function (key, successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getIdentifier", [key]);
}

// Sets a custom idenitifer
// key = identifier name as a string
// value = identifier value as a string
Localytics.prototype.setIdentifier = function (key, value) {
	cordova.exec(null, null, "LocalyticsPlugin", "setIdentifier", [key, value]);
}

// Get customer ID
// successCallback = callback function for result
Localytics.prototype.getCustomerId = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getCustomerId", []);
}

// Set customer ID
// id = unique customer id as a string (ie, "12345")
Localytics.prototype.setCustomerId = function (id) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerId", [id]);
}

// Set a user's location
// latitude = The latitude value
// longitude = The longitude value
Localytics.prototype.setLocation = function (latitude, longitude) {
	cordova.exec(null, null, "LocalyticsPlugin", "setLocation", [latitude, longitude]);
}

/*******************
 * Marketing
 ******************/

// Registers for push notifications
Localytics.prototype.registerPush = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "registerPush", []);
}

// Sets the push token
// pushToken = push token as a string
Localytics.prototype.setPushToken = function (pushToken) {
	cordova.exec(null, null, "LocalyticsPlugin", "setPushToken", [pushToken]);
}

// Gets the push token
// successCallback = allback function for result
Localytics.prototype.getPushToken = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getPushToken", []);
}

// Android only: Toggles push disabled
// enabled = boolean
Localytics.prototype.setNotificationsDisabled = function (disabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setNotificationsDisabled", [disabled]);
}

// Android only: Gets push status
// successCallback = callback function for result
Localytics.prototype.areNotificationsDisabled = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "areNotificationsDisabled", []);
}

// Android only: Set the default Localytics notification channel and description
// name = The name of the default notification channel
// description = The description of the default notification channel
Localytics.prototype.setDefaultNotificationChannel = function (name, description) {
	cordova.exec(null, null, "LocalyticsPlugin", "setDefaultNotificationChannel", [name, description]);
}

// Set a configuration object for push message display
// config = The JSON config object
Localytics.prototype.setPushMessageConfiguration = function (config) {
	cordova.exec(null, null, "LocalyticsPlugin", "setPushMessageConfiguration", [config]);
}

// Enables or disables Localytics test mode (disabled by default)
// enabled = boolean
Localytics.prototype.setTestModeEnabled = function (enabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setTestModeEnabled", [enabled]);
}

// Gets test mode status
// successCallback = callback function for result
Localytics.prototype.isTestModeEnabled = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "isTestModeEnabled", []);
}

// iOS only: Set the image name to use for the In-App dismiss button
// imageName = The named of the image in your app's Bundle
Localytics.prototype.setInAppMessageDismissButtonImageWithName = function (imageName) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppMessageDismissButtonImageWithName", [imageName]);
}

// Set the visibility of the dismiss button
// hidden = This visibility state of the dimiss button
Localytics.prototype.setInAppMessageDismissButtonHidden = function (hidden) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppMessageDismissButtonHidden", [hidden]);
}

// Set the relative position of the in-app message dismiss button
// buttonLocation = The button location ("left" or "right")
Localytics.prototype.setInAppMessageDismissButtonLocation = function (buttonLocation) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppMessageDismissButtonLocation", [buttonLocation]);
}

// Get the relative position of the in-app message dismiss button
// successCallback = callback function for result
Localytics.prototype.getInAppMessageDismissButtonLocation = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getInAppMessageDismissButtonLocation", []);
}

// Trigger an in-app message
// triggerName = The name of the in-app message trigger
// attributes = The attributes associated with the in-app triggering event
Localytics.prototype.triggerInAppMessage = function (triggerName, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "triggerInAppMessage", [triggerName, attributes]);
}

// Trigger campaigns as if a Session Start event had just occurred.
Localytics.prototype.triggerInAppMessagesForSessionStart = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "triggerInAppMessagesForSessionStart", []);
}

// If an in-app message is currently displayed, dismiss it. Is a no-op otherwise
Localytics.prototype.dismissCurrentInAppMessage = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "dismissCurrentInAppMessage", []);
}

// Set a configuration object for in-app message display
// config = The JSON config object
Localytics.prototype.setInAppMessageConfiguration = function (config) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppMessageConfiguration", [config]);
}

// iOS only: Returns whether the ADID parameter is added to In-App call to action URLs
// successCallback = callback function for result
Localytics.prototype.isInAppAdIdParameterEnabled = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "isInAppAdIdParameterEnabled", []);
}

// iOS only: Set whether ADID parameter is added to In-App call to action URLs. By default
// the ADID parameter will be added to call to action URLs.
// enabled = true to enable the ADID parameter or false to disable it
Localytics.prototype.setInAppAdIdParameterEnabled = function (enabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppAdIdParameterEnabled", [enabled]);
}

// Get all Inbox campaigns that can be displayed
// successCallback = callback function for result
Localytics.prototype.getInboxCampaigns = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getInboxCampaigns", []);
}

// Get all Inbox campaigns. The return value will include Inbox campaigns with no listing title,
// and thus no visible UI element.
// successCallback = callback function for result
Localytics.prototype.getAllInboxCampaigns = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getAllInboxCampaigns", []);
}

// Refresh all Inbox campaigns that can be displayed from the Localytics server
// successCallback = callback function for result
Localytics.prototype.refreshInboxCampaigns = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "refreshInboxCampaigns", []);
}

// Refresh all Inbox campaigns from the Localytics server. The return value will include Inbox
// campaigns with no listing title, and thus no visible UI element.
// successCallback = callback function for result
Localytics.prototype.refreshAllInboxCampaigns = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "refreshAllInboxCampaigns", []);
}

// Set an inbox campaign as read. Read state can be used to display opened inbox campaigns
// campaigns differently (e.g. an unread indicator). Not guaranteed to work with push to inbox
// campaigns.
// campaignId = the campaign Id of the Inbox campaign
// read = true to mark the campaign as read, false to mark it as unread
Localytics.prototype.setInboxCampaignRead = function (campaignId, read) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInboxCampaignRead", [campaignId, read]);
}

// Get the count of unread inbox messages
// successCallback = callback function for result
Localytics.prototype.getInboxCampaignsUnreadCount = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getInboxCampaignsUnreadCount", []);
}

// Tell the Localytics SDK that an Inbox campaign was tapped in the list view
// campaignId = the campaign Id of the Inbox campaign
Localytics.prototype.inboxListItemTapped = function (campaignId) {
	cordova.exec(null, null, "LocalyticsPlugin", "inboxListItemTapped", [campaignId]);
}

// Trigger a places notification for the given campaign
// campaignId = the Places campaign ID for which to trigger a notification
Localytics.prototype.triggerPlacesNotification = function (campaignId) {
	cordova.exec(null, null, "LocalyticsPlugin", "triggerPlacesNotification", [campaignId]);
}

// Set a configuration object for places push message display
// config = The JSON config object
Localytics.prototype.setPlacesMessageConfiguration = function (config) {
	cordova.exec(null, null, "LocalyticsPlugin", "setPlacesMessageConfiguration", [config]);
}

// Set a listener that will be notified of certain messaging callbacks:
// successCallback = callback function for result
Localytics.prototype.setMessagingListener = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "setMessagingListener", []);
}

// Remove the listener and no longer be notified of certain location callbacks:
Localytics.prototype.removeMessagingListener = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "removeMessagingListener", []);
}

/*******************
 * Location
 ******************/

// Enable or disable location monitoring for geofence monitoring
// enabled = Flag to indicate whether the monitoring should be enabled or disabled
Localytics.prototype.setLocationMonitoringEnabled = function (enabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setLocationMonitoringEnabled", [enabled]);
}

// Get a list of geofences to monitor for enter/exit events
// latitude = The user's current location latitude value
// longitude = The user's current location longitude value
// successCallback = callback function for result
Localytics.prototype.getGeofencesToMonitor = function (latitude, longitude, successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getGeofencesToMonitor", [latitude, longitude]);
}

// Trigger a region with a certain event
// region = The region that was triggered
// event = The event that triggered the region ("enter" or "exit")
Localytics.prototype.triggerRegion = function (region, event) {
	cordova.exec(null, null, "LocalyticsPlugin", "triggerRegion", [region, event]);
}

// Trigger a list of regions with a certain event
// regions = A list of regions that were triggered
// event = The event that triggered the region ("enter" or "exit")
Localytics.prototype.triggerRegions = function (regions, event) {
	cordova.exec(null, null, "LocalyticsPlugin", "triggerRegions", [regions, event]);
}

// Set a listener that will be notified of certain location callbacks:
// successCallback = callback function for result
Localytics.prototype.setLocationListener = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "setLocationListener", []);
}

// Remove the listener and no longer be notified of certain location callbacks:
Localytics.prototype.removeLocationListener = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "removeLocationListener", []);
}

/*******************
 * Developer Options
 ******************/

// Enables or disables Localytics logging (disabled by default)
// enabled = boolean
Localytics.prototype.setLoggingEnabled = function (enabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setLoggingEnabled", [enabled]);
}

// Gets logging status
// successCallback = callback function for result
Localytics.prototype.isLoggingEnabled = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "isLoggingEnabled", []);
}

// Customize the behavior of the SDK by setting custom values for various options.
// In each entry, the key specifies the option to modify, and the value specifies what value
// to set the option to. Options can be restored to default by passing in a value of null,
// or an empty string for values with type String.
// options = The object of options and values to modify
Localytics.prototype.setOptions = function (options) {
	cordova.exec(null, null, "LocalyticsPlugin", "setOptions", [options]);
}

// Customize the behavior of the SDK by setting custom values for various options.
// In each entry, the key specifies the option to modify, and the value specifies what value
// to set the option to. Options can be restored to default by passing in a value of null,
// or an empty string for values with type String.
// key = The key of the option
// value = The value of the option or null to restore the default
Localytics.prototype.setOption = function (key, value) {
	cordova.exec(null, null, "LocalyticsPlugin", "setOption", [key, value]);
}

// Android only: No production builds should call this method.
// Enable/Disable log rerouting to a file on disk.  Calling this method will allow logs to be
// copied later. The method allows two options:
//   * writeExternally set to true will write the logs to files/console.log within the app's directory
//   * writeExternally set to false will write the logs to console.log in the app's external
//     storage directory. This option requires requesting WRITE_EXTERNAL_STORAGE permissions from
//     the user. On Android less than 2.3 this additionally requires requesting the READ_LOGS
//     permission.
// writeExternally = a boolean value to indicate where to write the logs.
Localytics.prototype.redirectLogsToDisk = function (writeExternally) {
	cordova.exec(null, null, "LocalyticsPlugin", "redirectLogsToDisk", [writeExternally]);
}

// Gets install id
// successCallback = callback function for result
Localytics.prototype.getInstallId = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getInstallId", []);
}

// Gets app key
// successCallback = callback function for result
Localytics.prototype.getAppKey = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getAppKey", []);
}

// Gets library version
// successCallback = callback function for result
Localytics.prototype.getLibraryVersion = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getLibraryVersion", []);
}


module.exports = new Localytics();
