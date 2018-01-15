//
//  LocalyticsPlugin.java
//
//  Copyright 2018 Localytics. All rights reserved.
//

package com.localytics.phonegap;

import android.app.Application;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.location.Location;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.SparseArray;
import android.view.View;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import com.localytics.android.CircularRegion;
import com.localytics.android.Customer;
import com.localytics.android.InAppCampaign;
import com.localytics.android.InboxCampaign;
import com.localytics.android.InboxRefreshListener;
import com.localytics.android.Localytics;
import com.localytics.android.PlacesCampaign;
import com.localytics.android.PushCampaign;
import com.localytics.android.Region;

/**
 * This class echoes a string called from JavaScript.
 */
public class LocalyticsPlugin extends CordovaPlugin {

    private static final String PROP_SENDER_ID = "com.localytics.android_push_sender_id";
    private static final String ERROR_UNSUPPORTED_TYPE = "Unsupported type for attribute value.";
    private static final String ERROR_INVALID_ARRAY = "Invalid array type for attribute value.";

    private final SparseArray<InboxCampaign> inboxCampaignCache = new SparseArray<InboxCampaign>();
    private final SparseArray<InAppCampaign> inAppCampaignCache = new SparseArray<InAppCampaign>();
    private final SparseArray<PushCampaign> pushCampaignCache = new SparseArray<PushCampaign>();
    private final SparseArray<PlacesCampaign> placesCampaignCache = new SparseArray<PlacesCampaign>();

    private CDAnalyticsListener analyticsListener;
    private CDLocationListener locationListener;
    private CDMessagingListener messagingListener;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("integrate")) {
            String localyticsKey = optString(args, 0);
            Localytics.integrate(cordova.getActivity().getApplicationContext(), localyticsKey);
            Localytics.setInAppMessageDisplayActivity(cordova.getActivity());
            callbackContext.success();
            return true;
        } else if (action.equals("autoIntegrate")) {
            String localyticsKey = optString(args, 0);
            Localytics.autoIntegrate(cordova.getActivity().getApplication(), localyticsKey);
            Localytics.setInAppMessageDisplayActivity(cordova.getActivity());
            callbackContext.success();
            return true;
        } else if (action.equals("upload")) {
            Localytics.upload();
            callbackContext.success();
            return true;
        } else if (action.equals("openSession")) {
            Localytics.openSession();
            callbackContext.success();
            return true;
        } else if (action.equals("closeSession")) {
            Localytics.closeSession();
            callbackContext.success();
            return true;
        } else if (action.equals("setOptedOut")) {
            boolean enabled = args.getBoolean(0);
            Localytics.setOptedOut(enabled);
            callbackContext.success();
            return true;
        } else if (action.equals("isOptedOut")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    boolean enabled = Localytics.isOptedOut();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, enabled));
                }
            });
            return true;
        } else if (action.equals("tagEvent")) {
            if (args.length() == 3) {
                String name = args.getString(0);
                if (!TextUtils.isEmpty(name)) {
                    HashMap<String, String> attributes = optStringMap(args, 1);
                    int customerValueIncrease = args.getInt(2);
                    Localytics.tagEvent(name, attributes, customerValueIncrease);
                    callbackContext.success();
                } else {
                    callbackContext.error("Expected non-empty name argument.");
                }
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("tagPurchased")) {
            if (args.length() == 5) {
                String itemName = optString(args, 0);
                String itemId = optString(args, 1);
                String itemType = optString(args, 2);
                Long itemPrice = optLong(args, 3);
                HashMap<String, String> attributes = optStringMap(args, 4);
                Localytics.tagPurchased(itemName, itemId, itemType, itemPrice, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected five arguments.");
            }
            return true;
        } else if (action.equals("tagAddedToCart")) {
            if (args.length() == 5) {
                String itemName = optString(args, 0);
                String itemId = optString(args, 1);
                String itemType = optString(args, 2);
                Long itemPrice = optLong(args, 3);
                HashMap<String, String> attributes = optStringMap(args, 4);
                Localytics.tagAddedToCart(itemName, itemId, itemType, itemPrice, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected five arguments.");
            }
            return true;
        } else if (action.equals("tagStartedCheckout")) {
            if (args.length() == 3) {
                Long totalPrice = optLong(args, 0);
                Long itemCount = optLong(args, 1);
                HashMap<String, String> attributes = optStringMap(args, 2);
                Localytics.tagStartedCheckout(totalPrice, itemCount, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("tagCompletedCheckout")) {
            if (args.length() == 3) {
                Long totalPrice = optLong(args, 0);
                Long itemCount = optLong(args, 1);
                HashMap<String, String> attributes = optStringMap(args, 2);
                Localytics.tagCompletedCheckout(totalPrice, itemCount, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("tagContentViewed")) {
            if (args.length() == 4) {
                String contentName = optString(args, 0);
                String contentId = optString(args, 1);
                String contentType = optString(args, 2);
                HashMap<String, String> attributes = optStringMap(args, 3);
                Localytics.tagContentViewed(contentName, contentId, contentType, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected four arguments.");
            }
            return true;
        } else if (action.equals("tagSearched")) {
            if (args.length() == 4) {
                String queryText = optString(args, 0);
                String contentType = optString(args, 1);
                Long resultCount = optLong(args, 2);
                HashMap<String, String> attributes = optStringMap(args, 3);
                Localytics.tagSearched(queryText, contentType, resultCount, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected four arguments.");
            }
            return true;
        } else if (action.equals("tagShared")) {
            if (args.length() == 5) {
                String contentName = optString(args, 0);
                String contentId = optString(args, 1);
                String contentType = optString(args, 2);
                String methodName = optString(args, 3);
                HashMap<String, String> attributes = optStringMap(args, 4);
                Localytics.tagShared(contentName, contentId, contentType, methodName, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected five arguments.");
            }
            return true;
        } else if (action.equals("tagContentRated")) {
            if (args.length() == 5) {
                String contentName = optString(args, 0);
                String contentId = optString(args, 1);
                String contentType = optString(args, 2);
                Long rating = optLong(args, 3);
                HashMap<String, String> attributes = optStringMap(args, 4);
                Localytics.tagContentRated(contentName, contentId, contentType, rating, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected five arguments.");
            }
            return true;
        } else if (action.equals("tagCustomerRegistered")) {
            if (args.length() == 3) {
                Customer customer = optCustomer(args, 0);
                String methodName = optString(args, 1);
                HashMap<String, String> attributes = optStringMap(args, 2);
                Localytics.tagCustomerRegistered(customer, methodName, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("tagCustomerLoggedIn")) {
            if (args.length() == 3) {
                Customer customer = optCustomer(args, 0);
                String methodName = optString(args, 1);
                HashMap<String, String> attributes = optStringMap(args, 2);
                Localytics.tagCustomerLoggedIn(customer, methodName, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("tagCustomerLoggedOut")) {
            if (args.length() == 1) {
                HashMap<String, String> attributes = optStringMap(args, 0);
                Localytics.tagCustomerLoggedOut(attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected one argument.");
            }
            return true;
        } else if (action.equals("tagInvited")) {
            if (args.length() == 2) {
                String methodName = optString(args, 0);
                HashMap<String, String> attributes = optStringMap(args, 1);
                Localytics.tagInvited(methodName, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("tagInAppImpression")) {
            if (args.length() == 2) {
                int campaignId = args.getInt(0);
                InAppCampaign campaign = inAppCampaignCache.get(campaignId);
                if (campaign != null) {
                    String impressionType = args.getString(1);
                    if ("click".equalsIgnoreCase(impressionType)) {
                        Localytics.tagInAppImpression(campaign, Localytics.ImpressionType.CLICK);
                    } else if ("dismiss".equalsIgnoreCase(impressionType)) {
                        Localytics.tagInAppImpression(campaign, Localytics.ImpressionType.DISMISS);
                    } else {
                        Localytics.tagInAppImpression(campaign, impressionType);
                    }
                    callbackContext.success();
                } else {
                    callbackContext.error("Campaign not cached. Use setMessagingListener to ensure caching.");
                }
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("tagInboxImpression")) {
            if (args.length() == 2) {
                int campaignId = args.getInt(0);
                InboxCampaign campaign = inboxCampaignCache.get(campaignId);
                if (campaign != null) {
                    String impressionType = args.getString(1);
                    if ("click".equalsIgnoreCase(impressionType)) {
                        Localytics.tagInboxImpression(campaign, Localytics.ImpressionType.CLICK);
                    } else if ("dismiss".equalsIgnoreCase(impressionType)) {
                        Localytics.tagInboxImpression(campaign, Localytics.ImpressionType.DISMISS);
                    } else {
                        Localytics.tagInboxImpression(campaign, impressionType);
                    }
                    callbackContext.success();
                } else {
                    callbackContext.error("Campaign not cached. Use setMessagingListener to ensure caching.");
                }
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("tagPushToInboxImpression")) {
            int campaignId = args.getInt(0);
            InboxCampaign campaign = inboxCampaignCache.get(campaignId);
            if (campaign != null) {
                Localytics.tagPushToInboxImpression(campaign);
                callbackContext.success();
            } else {
                callbackContext.error("Campaign not cached. Use setMessagingListener to ensure caching.");
            }
            return true;
        } else if (action.equals("tagPlacesPushReceived")) {
            int campaignId = args.getInt(0);
            PlacesCampaign campaign = placesCampaignCache.get(campaignId);
            if (campaign != null) {
                Localytics.tagPlacesPushReceived(campaign);
                callbackContext.success();
            } else {
                callbackContext.error("Campaign not cached. Use setMessagingListener to ensure caching.");
            }
            return true;
        } else if (action.equals("tagPlacesPushOpened")) {
            if (args.length() == 2) {
                int campaignId = args.getInt(0);
                String impressionType = optString(args, 1);
                PlacesCampaign campaign = placesCampaignCache.get(campaignId);
                if (campaign != null) {
                    Localytics.tagPlacesPushOpened(campaign, impressionType);
                    callbackContext.success();
                } else {
                    callbackContext.error("Campaign not cached. Use setMessagingListener to ensure caching.");
                }
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("tagScreen")) {
            String name = args.getString(0);
            if (!TextUtils.isEmpty(name)) {
                Localytics.tagScreen(name);
                callbackContext.success();
            } else {
                callbackContext.error("Expected non-empty name argument.");
            }
            return true;
        } else if (action.equals("setCustomDimension")) {
            if (args.length() == 2) {
                int index = args.getInt(0);
                String value = optString(args, 1);
                Localytics.setCustomDimension(index, value);
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("getCustomDimension")) {
            final int index = args.getInt(0);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String value = Localytics.getCustomDimension(index);
                    callbackContext.success(value);
                }
            });
            return true;
        } else if (action.equals("setAnalyticsListener")) {
            analyticsListener = new CDAnalyticsListener(callbackContext);
            Localytics.setAnalyticsListener(analyticsListener);
            return true;
        } else if (action.equals("removeAnalyticsListener")) {
            analyticsListener = null;
            Localytics.setAnalyticsListener(null);
            callbackContext.success();
            return true;
        } else if (action.equals("setProfileAttribute")) {
            if (args.length() == 3) {
                String errorString = null;

                String attributeName = args.getString(0);
                Object attributeValue = args.get(1);
                String scope = args.getString(2);

                if (attributeValue instanceof Integer) {
                    Localytics.setProfileAttribute(attributeName, (Integer) attributeValue, getProfileScope(scope));
                } else if (attributeValue instanceof String) {
                    Localytics.setProfileAttribute(attributeName, (String) attributeValue, getProfileScope(scope));
                } else if (attributeValue instanceof Date) {
                    Localytics.setProfileAttribute(attributeName, (Date) attributeValue, getProfileScope(scope));
                } else if (attributeValue instanceof JSONArray) {
                    JSONArray array = (JSONArray) attributeValue;
                    Object item = getInitialItem(array);
                    if (item instanceof Integer) {
                        long[] longs = buildLongArray(array);
                        if (longs != null) {
                            Localytics.setProfileAttribute(attributeName, longs, getProfileScope(scope));
                        } else {
                            errorString = ERROR_INVALID_ARRAY;
                        }
                    } else if (item instanceof String) {
                        if (parseISO8601Date((String) item) != null) {
                            Date[] dates = buildDateArray(array);
                            if (dates != null) {
                                Localytics.addProfileAttributesToSet(attributeName, dates, getProfileScope(scope));
                            } else {
                                errorString = ERROR_INVALID_ARRAY;
                            }
                        } else {
                            String[] strings = buildStringArray(array);
                            if (strings != null) {
                                Localytics.addProfileAttributesToSet(attributeName, strings, getProfileScope(scope));
                            } else {
                                errorString = ERROR_INVALID_ARRAY;
                            }
                        }
                    }
                } else {
                    errorString = ERROR_UNSUPPORTED_TYPE;
                }

                if (errorString != null) {
                    callbackContext.error(errorString);
                } else {
                    callbackContext.success();
                }
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("addProfileAttributesToSet")) {
            if (args.length() == 3) {
                String errorString = null;

                String attributeName = args.getString(0);
                Object attributeValue = args.get(1);
                String scope = args.getString(2);

                if (attributeValue instanceof JSONArray) {
                    JSONArray array = (JSONArray) attributeValue;
                    Object item = getInitialItem(array);
                    if (item instanceof Integer) {
                        long[] longs = buildLongArray(array);
                        if (longs != null) {
                            Localytics.addProfileAttributesToSet(attributeName, longs, getProfileScope(scope));
                        } else {
                            errorString = ERROR_INVALID_ARRAY;
                        }
                    } else if (item instanceof String) {
                        // Check if date string first
                        if (parseISO8601Date((String)item) != null) {
                            Date[] dates = buildDateArray(array);
                            if (dates != null) {
                                Localytics.addProfileAttributesToSet(attributeName, dates, getProfileScope(scope));
                            } else {
                                errorString = ERROR_INVALID_ARRAY;
                            }
                        } else {
                            String[] strings = buildStringArray(array);
                            if (strings != null) {
                                Localytics.addProfileAttributesToSet(attributeName, strings, getProfileScope(scope));
                            } else {
                                errorString = ERROR_INVALID_ARRAY;
                            }
                        }
                    }
                } else {
                    errorString = ERROR_UNSUPPORTED_TYPE;
                }

                if (errorString != null) {
                    callbackContext.error(errorString);
                } else {
                    callbackContext.success();
                }
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("removeProfileAttributesFromSet")) {
            if (args.length() == 3) {
                String errorString = null;

                String attributeName = args.getString(0);
                Object attributeValue = args.get(1);
                String scope = args.getString(2);
                if (attributeValue instanceof JSONArray) {
                    JSONArray array = (JSONArray) attributeValue;
                    Object item = getInitialItem(array);
                    if (item instanceof Integer) {
                        long[] longs = buildLongArray(array);
                        if (longs != null) {
                            Localytics.removeProfileAttributesFromSet(attributeName, longs, getProfileScope(scope));
                        } else {
                            errorString = ERROR_INVALID_ARRAY;
                        }
                    } else if (item instanceof String) {
                        if (parseISO8601Date((String)item) != null) {
                            Date[] dates = buildDateArray(array);
                            if (dates != null) {
                                Localytics.removeProfileAttributesFromSet(attributeName, dates, getProfileScope(scope));
                            } else {
                                errorString = ERROR_INVALID_ARRAY;
                            }
                        } else {
                            String[] strings = buildStringArray(array);
                            if (strings != null) {
                                Localytics.removeProfileAttributesFromSet(attributeName, strings, getProfileScope(scope));
                            } else {
                                errorString = ERROR_INVALID_ARRAY;
                            }
                        }
                    }
                } else {
                    errorString = ERROR_UNSUPPORTED_TYPE;
                }

                if (errorString != null) {
                    callbackContext.error(errorString);
                } else {
                    callbackContext.success();
                }
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("incrementProfileAttribute")) {
            if (args.length() == 3) {
                String attributeName = args.getString(0);
                long incrementValue = args.getLong(1);
                String scope = args.getString(2);

                Localytics.incrementProfileAttribute(attributeName, incrementValue, getProfileScope(scope));
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("decrementProfileAttribute")) {
            if (args.length() == 3) {
                String attributeName = args.getString(0);
                long decrementValue = args.getLong(1);
                String scope = args.getString(2);

                Localytics.decrementProfileAttribute(attributeName, decrementValue, getProfileScope(scope));
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("deleteProfileAttribute")) {
            if (args.length() == 2) {
                String attributeName = args.getString(0);
                String scope = args.getString(1);

                Localytics.deleteProfileAttribute(attributeName, getProfileScope(scope));
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("setCustomerEmail")) {
            String email = optString(args, 0);
            Localytics.setCustomerEmail(email);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerFirstName")) {
            String firstName = optString(args, 0);
            Localytics.setCustomerFirstName(firstName);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerLastName")) {
            String lastName = optString(args, 0);
            Localytics.setCustomerLastName(lastName);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerFullName")) {
            String fullName = optString(args, 0);
            Localytics.setCustomerFullName(fullName);
            callbackContext.success();
            return true;
        } else if (action.equals("setIdentifier")) {
            if (args.length() == 2) {
                String key = args.getString(0);
                if (!TextUtils.isEmpty(key)) {
                    String value = optString(args, 1);
                    Localytics.setIdentifier(key, value);
                    callbackContext.success();
                } else {
                    callbackContext.error("Expected non-empty key argument.");
                }
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("getIdentifier")) {
            final String key = args.getString(0);
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String value = Localytics.getIdentifier(key);
                    callbackContext.success(value);
                }
            });
            return true;
        } else if (action.equals("setCustomerId")) {
            String id = optString(args, 0);
            Localytics.setCustomerId(id);
            callbackContext.success();
            return true;
        } else if (action.equals("getCustomerId")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String customerId = Localytics.getCustomerId();
                    callbackContext.success(customerId);
                }
            });
            return true;
        } else if (action.equals("setLocation")) {
            if (args.length() == 2) {
                Location location = new Location("");
                location.setLatitude(args.getDouble(0));
                location.setLongitude(args.getDouble(1));

                Localytics.setLocation(location);
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("registerPush")) {
            String senderId = null;

            try {
                PackageManager pm = cordova.getActivity().getPackageManager();
                ApplicationInfo ai = pm.getApplicationInfo(cordova.getActivity().getPackageName(), PackageManager.GET_META_DATA);
                Bundle metaData = ai.metaData;
                senderId = metaData.getString(PROP_SENDER_ID);
            } catch (PackageManager.NameNotFoundException e) {
                //No-op
            }

            Localytics.registerPush(senderId);
            callbackContext.success();
            return true;
        } else if (action.equals("setPushToken")) {
            String registrationId = null;
            if (!args.isNull(0)) {
                registrationId = args.getString(0);
            }
            Localytics.setPushRegistrationId(registrationId);
            callbackContext.success();
            return true;
        } else if (action.equals("getPushToken")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String result = Localytics.getPushRegistrationId();
                    callbackContext.success(result);
                }
            });
            return true;
        } else if (action.equals("setNotificationsDisabled")) {
            boolean disabled = args.getBoolean(0);
            Localytics.setNotificationsDisabled(disabled);
            callbackContext.success();
            return true;
        } else if (action.equals("areNotificationsDisabled")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    boolean disabled = Localytics.areNotificationsDisabled();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, disabled));
                }
            });
            return true;
        } else if (action.equals("setDefaultNotificationChannel")) {
            if (args.length() == 2) {
                String name = args.getString(0);
                String description = optString(args, 1);
                Localytics.setDefaultNotificationChannel(name, description);
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("setPushMessageConfiguration")) {
            if (messagingListener != null) {
                messagingListener.setPushConfiguration(args.getJSONObject(0));
            } else {
                callbackContext.error("Call setMessagingListener before setting configuration.");
            }
            return true;
        } else if (action.equals("setTestModeEnabled")) {
            boolean enabled = args.getBoolean(0);
            Localytics.setTestModeEnabled(enabled);
            callbackContext.success();
            return true;
        } else if (action.equals("isTestModeEnabled")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    boolean enabled = Localytics.isTestModeEnabled();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, enabled));
                }
            });
            return true;
        } else if (action.equals("setInAppMessageDismissButtonImageWithName")) {
            //No-op (iOS only)
            return true;
        } else if (action.equals("setInAppMessageDismissButtonLocation")) {
            String location = args.getString(0);
            Localytics.setInAppMessageDismissButtonLocation(toLocation(location));
            callbackContext.success();
            return true;
        } else if (action.equals("getInAppMessageDismissButtonLocation")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    Localytics.InAppMessageDismissButtonLocation location = Localytics.getInAppMessageDismissButtonLocation();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, fromLocation(location)));
                }
            });
            return true;
        } else if (action.equals("setInAppMessageDismissButtonHidden")) {
            boolean hidden = args.getBoolean(0);
            Localytics.setInAppMessageDismissButtonVisibility(hidden ? View.GONE : View.VISIBLE);
            callbackContext.success();
            return true;
        } else if (action.equals("triggerInAppMessage")) {
            if (args.length() == 2) {
                String triggerName = args.getString(0);
                HashMap<String, String> attributes = optStringMap(args, 1);
                Localytics.triggerInAppMessage(triggerName, attributes);
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("triggerInAppMessagesForSessionStart")) {
            Localytics.triggerInAppMessagesForSessionStart();
            callbackContext.success();
            return true;
        } else if (action.equals("dismissCurrentInAppMessage")) {
            Localytics.dismissCurrentInAppMessage();
            callbackContext.success();
            return true;
        } else if (action.equals("setInAppMessageConfiguration")) {
            if (messagingListener != null) {
                messagingListener.setInAppConfiguration(args.getJSONObject(0));
            } else {
                callbackContext.error("Call setMessagingListener before setting configuration.");
            }
            return true;
        } else if (action.equals("isInAppAdIdParameterEnabled")) {
            //No-op (iOS only)
            return true;
        } else if (action.equals("setInAppAdIdParameterEnabled")) {
            //No-op (iOS only)
            return true;
        } else if (action.equals("getInboxCampaigns")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        List<InboxCampaign> campaigns = Localytics.getInboxCampaigns();

                        // Cache campaigns
                        for (InboxCampaign campaign : campaigns) {
                            inboxCampaignCache.put((int) campaign.getCampaignId(), campaign);
                        }

                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, toInboxJSON(campaigns)));
                    } catch (JSONException e) {
                        callbackContext.error("JSONException while converting campaigns.");
                    }
                }
            });
            return true;
        } else if (action.equals("getAllInboxCampaigns")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    try {
                        List<InboxCampaign> campaigns = Localytics.getAllInboxCampaigns();

                        // Cache campaigns
                        for (InboxCampaign campaign : campaigns) {
                            inboxCampaignCache.put((int) campaign.getCampaignId(), campaign);
                        }

                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, toInboxJSON(campaigns)));
                    } catch (JSONException e) {
                        callbackContext.error("JSONException while converting campaigns.");
                    }
                }
            });
            return true;
        } else if (action.equals("refreshInboxCampaigns")) {
            Localytics.refreshInboxCampaigns(new InboxRefreshListener() {
                @Override
                public void localyticsRefreshedInboxCampaigns(List<InboxCampaign> campaigns) {
                    try {
                        // Cache campaigns
                        for (InboxCampaign campaign : campaigns) {
                            inboxCampaignCache.put((int) campaign.getCampaignId(), campaign);
                        }

                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, toInboxJSON(campaigns)));
                    } catch (JSONException e) {
                        callbackContext.error("JSONException while converting campaigns.");
                    }
                }
            });
            return true;
        } else if (action.equals("refreshAllInboxCampaigns")) {
            Localytics.refreshAllInboxCampaigns(new InboxRefreshListener() {
                @Override
                public void localyticsRefreshedInboxCampaigns(List<InboxCampaign> campaigns) {
                    try {
                        // Cache campaigns
                        for (InboxCampaign campaign : campaigns) {
                            inboxCampaignCache.put((int) campaign.getCampaignId(), campaign);
                        }

                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, toInboxJSON(campaigns)));
                    } catch (JSONException e) {
                        callbackContext.error("JSONException while converting campaigns.");
                    }
                }
            });
            return true;
        } else if (action.equals("getInboxCampaignsUnreadCount")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    int count = Localytics.getInboxCampaignsUnreadCount();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, count));
                }
            });
            return true;
        } else if (action.equals("setInboxCampaignRead")) {
            if (args.length() == 2) {
                int campaignId = args.getInt(0);
                boolean read = args.getBoolean(1);
                InboxCampaign campaign = inboxCampaignCache.get(campaignId);
                if (campaign != null) {
                    Localytics.setInboxCampaignRead(campaign, read);
                } else {
                    Localytics.setInboxCampaignRead(campaignId, read);
                }
                callbackContext.success();
                updateInboxCampaignCache();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("inboxListItemTapped")) {
            int campaignId = args.getInt(0);
            InboxCampaign campaign = inboxCampaignCache.get(campaignId);
            if (campaign != null) {
                Localytics.inboxListItemTapped(campaign);
                updateInboxCampaignCache();
                callbackContext.success();
            } else {
                callbackContext.error("Campaign not cached. Call getInboxCampaigns or getAllInboxCampaigns before this method.");
            }
            return true;
        } else if (action.equals("triggerPlacesNotification")) {
            int campaignId = args.getInt(0);
            PlacesCampaign campaign = placesCampaignCache.get(campaignId);
            if (campaign != null) {
                Localytics.triggerPlacesNotification(campaign);
                callbackContext.success();
            } else {
                callbackContext.error("Campaign not cached. Use setMessagingListener to ensure caching.");
            }
            return true;
        } else if (action.equals("setPlacesMessageConfiguration")) {
            if (messagingListener != null) {
                messagingListener.setPlacesConfiguration(args.getJSONObject(0));
            } else {
                callbackContext.error("Call setMessagingListener before setting configuration.");
            }
            return true;
        } else if (action.equals("setMessagingListener")) {
            messagingListener = new CDMessagingListener(callbackContext, inAppCampaignCache, pushCampaignCache, placesCampaignCache);
            Localytics.setMessagingListener(messagingListener);
            return true;
        } else if (action.equals("removeMessagingListener")) {
            messagingListener = null;
            Localytics.setMessagingListener(null);
            callbackContext.success();
            return true;
        } else if (action.equals("setLocationMonitoringEnabled")) {
            boolean enabled = args.getBoolean(0);
            Localytics.setLocationMonitoringEnabled(enabled);
        } else if (action.equals("getGeofencesToMonitor")) {
            if (args.length() == 2) {
                final double latitude = args.getDouble(0);
                final double longitude = args.getDouble(1);
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        try {
                            List<CircularRegion> circularRegions = Localytics.getGeofencesToMonitor(latitude, longitude);
                            JSONArray result = toCircularRegionJSON(circularRegions);
                            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, result));
                        } catch (JSONException e) {
                            callbackContext.error("JSONException while converting regions.");
                        }
                    }
                });
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("triggerRegion")) {
            if (args.length() == 2) {
                JSONObject region = args.getJSONObject(0);
                String event = args.getString(1);
                Localytics.triggerRegion(toCircularRegion(region), toEvent(event));
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("triggerRegions")) {
            if (args.length() == 2) {
                JSONArray regions = args.getJSONArray(0);
                String event = args.getString(1);
                Localytics.triggerRegions(toCircularRegions(regions), toEvent(event));
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("setLocationListener")) {
            locationListener = new CDLocationListener(callbackContext);
            Localytics.setLocationListener(locationListener);
            return true;
        } else if (action.equals("removeLocationListener")) {
            locationListener = null;
            Localytics.setLocationListener(null);
            callbackContext.success();
            return true;
        } else if (action.equals("setLoggingEnabled")) {
            boolean enabled = args.getBoolean(0);
            Localytics.setLoggingEnabled(enabled);
            callbackContext.success();
            return true;
        } else if (action.equals("isLoggingEnabled")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    boolean enabled = Localytics.isLoggingEnabled();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, enabled));
                }
            });
            return true;
        } else if (action.equals("setOptions")) {
            HashMap<String, Object> options = optObjectMap(args, 0);
            Localytics.setOptions(options);
            callbackContext.success();
            return true;
        } else if (action.equals("setOption")) {
            if (args.length() == 2) {
                String key = args.getString(0);
                Object value = args.get(1);
                Localytics.setOption(key, value);
                callbackContext.success();
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("redirectLogsToDisk")) {
            boolean writeExternally = args.getBoolean(0);
            Localytics.redirectLogsToDisk(writeExternally, cordova.getActivity());
            callbackContext.success();
            return true;
        } else if (action.equals("getInstallId")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String result = Localytics.getInstallId();
                    callbackContext.success(result);
                }
            });
            return true;
        } else if (action.equals("getAppKey")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String result = Localytics.getAppKey();
                    callbackContext.success(result);
                }
            });

            return true;
        } else if (action.equals("getLibraryVersion")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    String result = Localytics.getLibraryVersion();
                    callbackContext.success(result);
                }
            });
            return true;
        }
        return false;
    }

    @Override
    public void onNewIntent(Intent intent) {
        Localytics.onNewIntent(cordova.getActivity(), intent);
    }

    /*******************
     * Private Methods
     ******************/
    private boolean isNotNull(JSONArray jsonArray, int index) throws JSONException {
        return jsonArray != null && jsonArray.length() > index && !jsonArray.isNull(index);
    }

    private String optString(JSONArray jsonArray, int index) throws JSONException {
        if (isNotNull(jsonArray, index)) {
            return jsonArray.getString(index);
        }

        return null;
    }

    private Long optLong(JSONArray jsonArray, int index) throws JSONException {
        if (isNotNull(jsonArray, index)) {
            return jsonArray.getLong(index);
        }

        return null;
    }

    private HashMap<String, String> optStringMap(JSONArray jsonArray, int index) throws JSONException {
        if (isNotNull(jsonArray, index)) {
            return convertToStringMap(jsonArray.getJSONObject(index));
        }

        return null;
    }

    private HashMap<String, Object> optObjectMap(JSONArray jsonArray, int index) throws JSONException {
        if (isNotNull(jsonArray, index)) {
            return convertToObjectMap(jsonArray.getJSONObject(index));
        }

        return null;
    }

    private List<HashMap<String, Object>> optMapObjectList(JSONArray jsonArray, int index) throws JSONException {
        if (isNotNull(jsonArray, index)) {
            return convertToMapObjectList(jsonArray.getJSONArray(index));
        }

        return null;
    }

    private HashMap<String, String> convertToStringMap(JSONObject jsonObject) throws JSONException {
        HashMap<String, String> map = null;
        if (jsonObject != null && jsonObject.length() > 0) {
            map = new HashMap<String, String>();
            Iterator<?> keys = jsonObject.keys();
            while (keys.hasNext()) {
                String key = (String) keys.next();
                String value = jsonObject.getString(key);
                map.put(key, value);
            }
        }

        return map;
    }

    private HashMap<String, Object> convertToObjectMap(JSONObject jsonObject) throws JSONException {
        HashMap<String, Object> map = null;
        if (jsonObject != null && jsonObject.length() > 0) {
            map = new HashMap<String, Object>();
            Iterator<?> keys = jsonObject.keys();
            while (keys.hasNext()) {
                String key = (String) keys.next();
                Object value = jsonObject.get(key);
                map.put(key, value);
            }
        }

        return map;
    }

    private List<HashMap<String, Object>> convertToMapObjectList(JSONArray array) throws JSONException {
        List<HashMap<String, Object>> list = new ArrayList<HashMap<String, Object>>();
        for (int i = 0; i < array.length(); i++) {
            list.add(convertToObjectMap(array.getJSONObject(i)));
        }
        return list;
    }

    private Customer optCustomer(JSONArray jsonArray, int index) throws JSONException {
        Customer customer = null;
        if (isNotNull(jsonArray, index)) {
            JSONObject jsonObject = jsonArray.getJSONObject(index);
            return new Customer.Builder()
                .setCustomerId(jsonObject.optString("customerId"))
                .setFirstName(jsonObject.optString("firstName"))
                .setLastName(jsonObject.optString("lastName"))
                .setFullName(jsonObject.optString("fullName"))
                .setEmailAddress(jsonObject.optString("emailAddress"))
                .build();
        }

        return customer;
    }

    private Localytics.ProfileScope getProfileScope(String scope) {
        if (scope == null || scope.equals("app")) {
            return Localytics.ProfileScope.APPLICATION;
        } else if (scope.equals("org")) {
            return Localytics.ProfileScope.ORGANIZATION;
        } else {
            throw new IllegalArgumentException("Profile scope must be either 'org' or 'app'.");
        }
    }

    private Object getInitialItem(JSONArray array) {
        try {
            return (array != null && array.length() > 0)? array.get(0) : null;
        } catch (JSONException e) {
            return null;
        }
    }

    private String[] buildStringArray(JSONArray array) {
        if (array == null) {
            return null;
        }
        int length = array.length();
        String[] strings = new String[length];
        try {
            for (int i = 0; i < length; i++) {
                if (array.get(i) instanceof String) {
                    strings[i] = array.getString(i);
                } else {
                    // Return null for entire array to prevent multi-type arrays
                    return null;
                }
            }
        }catch (JSONException e) {
            return null;
        }
        return strings;
    }

    private long[] buildLongArray(JSONArray array) {
        if (array == null) {
            return null;
        }
        int length = array.length();
        long[] longs = new long[length];
        try {
            for (int i = 0; i < length; i++) {
                if (array.get(i) instanceof Integer) {
                    longs[i] = array.getInt(i);
                } else {
                    // Return null for entire array to prevent multi-type arrays
                    return null;
                }
            }
        } catch (JSONException e) {
            return null;
        }
        return longs;
    }

    private Date[] buildDateArray(JSONArray array) {
        if (array == null) {
            return null;
        }
        int length = array.length();
        Date[] dates = new Date[length];
        try {
            for (int i = 0; i < length; i++) {
                Date d = parseISO8601Date(array.getString(i));
                if (d != null) {
                    dates[i] = d;
                } else {
                    // Return null for entire array to prevent multi-type arrays
                    return null;
                }
            }
        } catch (JSONException e) {
            return null;
        }
        return dates;
    }

    private static SimpleDateFormat iso8601Format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

    private Date parseISO8601Date(String dateStr) {
        try {
            // Add more formats as needed.
            return iso8601Format.parse(dateStr);
        } catch (ParseException e) {
            return null;
        }
    }

    static JSONArray toRegionJSON(List<Region> regions) throws JSONException {
        JSONArray json = new JSONArray();
        for (Region region : regions) {
            if (region instanceof CircularRegion) {
                json.put(toCircularRegionJSON((CircularRegion) region));
            }
        }
        return json;
    }

    static JSONArray toCircularRegionJSON(List<CircularRegion> regions) throws JSONException {
        JSONArray json = new JSONArray();
        for (CircularRegion region : regions) {
            json.put(toCircularRegionJSON(region));
        }
        return json;
    }

    static JSONObject toCircularRegionJSON(CircularRegion region) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("uniqueId", region.getUniqueId());
        json.put("latitude", region.getLatitude());
        json.put("longitude", region.getLongitude());
        json.put("name", region.getName());
        json.put("type", region.getType());
        json.put("attributes", toMapJSON(region.getAttributes()));
        return json;
    }

    static JSONObject toMapJSON(Map<String, String> map) throws JSONException {
        JSONObject json = new JSONObject();
        for (Map.Entry<String, String> entry : map.entrySet()) {
            json.put(entry.getKey(), entry.getValue());
        }
        return json;
    }

    static JSONArray toInboxJSON(List<InboxCampaign> campaigns) throws JSONException {
        JSONArray json = new JSONArray();
        for (InboxCampaign campaign : campaigns) {
            json.put(toInboxJSON(campaign));
        }
        return json;
    }

    static JSONObject toInboxJSON(InboxCampaign campaign) throws JSONException {
        JSONObject json = new JSONObject();

        // Campaign
        json.put("campaignId", (int) campaign.getCampaignId());
        json.put("name", campaign.getName());
        json.put("attributes", toMapJSON(campaign.getAttributes()));

        // WebViewCampaign
        Uri creativeFilePath = campaign.getCreativeFilePath();
        json.put("creativeFilePath", creativeFilePath != null ? creativeFilePath.toString() : "");

        // InboxCampaign
        json.put("read", campaign.isRead());
        json.put("title", campaign.getTitle());
        json.put("sortOrder", (int) campaign.getSortOrder());
        json.put("receivedDate", (int) (campaign.getReceivedDate().getTime() / 1000));
        json.put("summary", campaign.getSummary());
        Uri thumbnailUri = campaign.getThumbnailUri();
        json.put("thumbnailUrl", thumbnailUri != null ? thumbnailUri.toString() : "");
        json.put("hasCreative", campaign.hasCreative());

        return json;
    }

    static JSONObject toInAppJSON(InAppCampaign campaign) throws JSONException {
        JSONObject json = new JSONObject();

        // Campaign
        json.put("campaignId", (int) campaign.getCampaignId());
        json.put("name", campaign.getName());
        json.put("attributes", toMapJSON(campaign.getAttributes()));

        // WebViewCampaign
        Uri creativeFilePath = campaign.getCreativeFilePath();
        json.put("creativeFilePath", creativeFilePath != null ? creativeFilePath.toString() : "");

        // InAppCampaign
        json.put("aspectRatio", campaign.getAspectRatio());
        json.put("bannerOffsetDps", campaign.getOffset());
        json.put("backgroundAlpha", campaign.getBackgroundAlpha());
        json.put("displayLocation", campaign.getDisplayLocation());
        json.put("dismissButtonHidden", campaign.isDismissButtonHidden());
        if (Localytics.InAppMessageDismissButtonLocation.RIGHT.equals(campaign.getDismissButtonLocation())) {
          json.put("dismissButtonLocation", "right");
        } else {
          json.put("dismissButtonLocation", "left");
        }
        json.put("eventName", campaign.getEventName());
        json.put("eventAttributes", toMapJSON(campaign.getEventAttributes()));

        return json;
    }

    static JSONObject toPushJSON(PushCampaign campaign) throws JSONException {
        JSONObject json = new JSONObject();

        // Campaign
        json.put("campaignId", (int) campaign.getCampaignId());
        json.put("name", campaign.getName());
        json.put("attributes", toMapJSON(campaign.getAttributes()));

        // PushCampaign
        json.put("creativeId", (int) campaign.getCreativeId());
        json.put("creativeType", campaign.getCreativeType());
        json.put("message", campaign.getMessage());
        json.put("soundFilename", campaign.getSoundFilename());
        json.put("attachmentUrl", campaign.getAttachmentUrl());

        return json;
    }

    static JSONObject toPlacesJSON(PlacesCampaign campaign) throws JSONException {
        JSONObject json = new JSONObject();

        // Campaign
        json.put("campaignId", (int) campaign.getCampaignId());
        json.put("name", campaign.getName());
        json.put("attributes", toMapJSON(campaign.getAttributes()));

        // PlacesCampaign
        json.put("creativeId", (int) campaign.getCreativeId());
        json.put("creativeType", campaign.getCreativeType());
        json.put("message", campaign.getMessage());
        json.put("soundFilename", campaign.getSoundFilename());
        json.put("attachmentUrl", campaign.getAttachmentUrl());
        json.put("region", toCircularRegionJSON((CircularRegion) campaign.getRegion()));
        if (Region.Event.ENTER.equals(campaign.getTriggerEvent())) {
          json.put("triggerEvent", "enter");
        } else {
          json.put("triggerEvent", "exit");
        }

        return json;
    }

    static CircularRegion toCircularRegion(JSONObject jsonObject) throws JSONException {
        return new CircularRegion.Builder()
            .setUniqueId(jsonObject.optString("uniqueId"))
            .build();
    }

    static List<Region> toCircularRegions(JSONArray array) throws JSONException {
        List<Region> regions = new ArrayList<Region>();
        for (int i = 0; i < array.length(); i++) {
            regions.add(toCircularRegion(array.getJSONObject(i)));
        }
        return regions;
    }

    static Region.Event toEvent(String event) {
        if ("enter".equalsIgnoreCase(event)) {
            return Region.Event.ENTER;
        } else {
            return Region.Event.EXIT;
        }
    }

    static Localytics.InAppMessageDismissButtonLocation toLocation(String location) {
        if ("left".equalsIgnoreCase(location)) {
            return Localytics.InAppMessageDismissButtonLocation.LEFT;
        } else {
            return Localytics.InAppMessageDismissButtonLocation.RIGHT;
        }
    }

    static String fromLocation(Localytics.InAppMessageDismissButtonLocation location) {
        switch(location) {
            case LEFT:
              return "left";
            default:
              return "right";
        }
    }

    static List<String> toStringList(JSONArray array) {
        List<String> result = new ArrayList<String>();
        for (int i = 0; i < array.length(); i++) {
          result.add(array.optString(i));
        }

        return result;
    }

    private void updateInboxCampaignCache() {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                for (InboxCampaign campaign : Localytics.getAllInboxCampaigns()) {
                    inboxCampaignCache.put((int) campaign.getCampaignId(), campaign);
                }
            }
        });
    }
}
