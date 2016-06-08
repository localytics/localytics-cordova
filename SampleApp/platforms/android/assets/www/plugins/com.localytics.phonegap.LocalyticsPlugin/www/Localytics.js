cordova.define("com.localytics.phonegap.LocalyticsPlugin.Localytics", function(require, exports, module) {
//
//  Localytics.js
//
//  Copyright 2015 Localytics. All rights reserved.
//

var Localytics = function () {
}

/*******************
 * Integration
 ******************/
// Initializes Localytics without opening a session
// appKey = Localytics App ID as a string
Localytics.prototype.integrate = function (localyticsKey) {
	cordova.exec(null, null, "LocalyticsPlugin", "integrate", [localyticsKey]);
}

// Initiates an upload
// This should typically be called on deviceready, resume, and pause events
Localytics.prototype.upload = function() {
	cordova.exec(null, null, "LocalyticsPlugin", "upload", []);
}

// Initializes Localytics by hooking into the activity lifecycle events of the app
Localytics.prototype.autoIntegrate = function() {
	cordova.exec(null, null, "LocalyticsPlugin", "autoIntegrate", []);
}


/*******************
 * Analytics
 ******************/
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

// Tags an event
// event = Name of the event
// attributes = a hash of key/value pairs containing the event attributes
// customerValueIncrease = customer value increase as an int
Localytics.prototype.tagEvent = function (event, attributes, customerValueIncrease) {
	cordova.exec(null, null, "LocalyticsPlugin", "tagEvent", [event, attributes, customerValueIncrease]);
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
Localytics.prototype.getCustomDimension = function (index, successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getCustomDimension", [index]);
}

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


/*******************
 * Profiles
 ******************/
 Localytics.prototype.setProfileAttribute = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "setProfileAttribute", [name, value, scope]);
}

 Localytics.prototype.addProfileAttributesToSet = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "addProfileAttributesToSet", [name, value, scope]);
}

 Localytics.prototype.removeProfileAttributesFromSet = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "removeProfileAttributesFromSet", [name, value, scope]);
}

 Localytics.prototype.incrementProfileAttribute = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "incrementProfileAttribute", [name, value, scope]);
}

 Localytics.prototype.decrementProfileAttribute = function (name, value, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "decrementProfileAttribute", [name, value, scope]);
}

 Localytics.prototype.deleteProfileAttribute = function (name, scope) {
	cordova.exec(null, null, "LocalyticsPlugin", "deleteProfileAttribute", [name, scope]);
}
 
 
/*******************
 * User Information
 ******************/
// Sets a custom idenitifer
// key = identifier name as a string
// value = identifier value as a string
Localytics.prototype.setIdentifier = function (key, value) {
	cordova.exec(null, null, "LocalyticsPlugin", "setIdentifier", [key, value]);
}

// Set customer ID
// id = unique customer id as a string (ie, "12345")
Localytics.prototype.setCustomerId = function (id) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerId", [id]);
}

// Set customer full name
// fullName = customer full name as a string (ie, "John Doe")
Localytics.prototype.setCustomerFullName = function (fullName) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerFullName", [fullName]);
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

// Set customer email address
// email = customer email as a string (ie, "johndoe@company.com")
Localytics.prototype.setCustomerEmail = function (email) {
	cordova.exec(null, null, "LocalyticsPlugin", "setCustomerEmail", [email]);
}

Localytics.prototype.setLocation = function (latitude, longitude) {
	cordova.exec(null, null, "LocalyticsPlugin", "setLocation", [latitude, longitude]);
}

/*******************
 * Marketing
 ******************/
// Registers for push notifications
// successCallback = callback function for result
Localytics.prototype.registerPush = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "registerPush", []);
}

// Toggles push disabled
// enabled = boolean
Localytics.prototype.setPushDisabled = function (enabled) {
	cordova.exec(null, null, "LocalyticsPlugin", "setPushDisabled", [enabled]);
}

// Gets push status
// successCallback = callback function for result
Localytics.prototype.isPushDisabled = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "isPushDisabled", []);
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

Localytics.prototype.setInAppMessageDismissButtonImageWithName = function (imageName) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppMessageDismissButtonImageWithName", [imageName]);
}

Localytics.prototype.setInAppMessageDismissButtonLocation = function (buttonLocation) {
	cordova.exec(null, null, "LocalyticsPlugin", "setInAppMessageDismissButtonLocation", [buttonLocation]);
}

Localytics.prototype.getInAppMessageDismissButtonLocation = function (successCallback) {
	cordova.exec(successCallback, null, "LocalyticsPlugin", "getInAppMessageDismissButtonLocation", []);
}

Localytics.prototype.triggerInAppMessage = function (triggerName, attributes) {
	cordova.exec(null, null, "LocalyticsPlugin", "triggerInAppMessage", [triggerName, attributes]);
}

Localytics.prototype.dismissCurrentInAppMessage = function () {
	cordova.exec(null, null, "LocalyticsPlugin", "dismissCurrentInAppMessage", []);
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

// Sets session timeout interval
// seconds = timeout interval in seconds
Localytics.prototype.setSessionTimeoutInterval = function (seconds) {
    cordova.exec(null, null, "LocalyticsPlugin", "setSessionTimeoutInterval", [seconds]);
}

// Gets session timeout interval
// successCallback = callback function for result
Localytics.prototype.getSessionTimeoutInterval = function (successCallback) {
    cordova.exec(successCallback, null, "LocalyticsPlugin", "getSessionTimeoutInterval", []);
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

});
