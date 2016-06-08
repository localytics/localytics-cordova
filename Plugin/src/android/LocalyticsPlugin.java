//
//  LocalyticsPlugin.java
//
//  Copyright 2015 Localytics. All rights reserved.
//

package com.localytics.phonegap;

import android.app.Application;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Bundle;

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
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;

import com.localytics.android.Localytics;
import com.localytics.android.LocalyticsActivityLifecycleCallbacks;

/**
 * This class echoes a string called from JavaScript.
 */
public class LocalyticsPlugin extends CordovaPlugin {
    private static final String PROP_SENDER_ID = "com.localytics.android_push_sender_id";
    private static final String ERROR_UNSUPPORTED_TYPE = "Unsupported type for attribute value.";
    private static final String ERROR_INVALID_ARRAY = "Invalid array type for attribute value.";

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
    }

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("integrate")) {
            String localyticsKey = (args.length() == 1 && !args.isNull(0)? args.getString(0) : null);
            Localytics.integrate(cordova.getActivity().getApplicationContext(), localyticsKey);
            callbackContext.success();
            return true;
        } else if (action.equals("upload")) {
            Localytics.upload();
            callbackContext.success();
            return true;
        } else if (action.equals("autoIntegrate")) {
            /* App-key is read from meta-data LOCALYTICS_APP_KEY in AndroidManifest */
            Application app = cordova.getActivity().getApplication();
            app.registerActivityLifecycleCallbacks(new LocalyticsActivityLifecycleCallbacks(app.getApplicationContext()));
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
        } else if (action.equals("tagEvent")) {
            if (args.length() == 3) {
                String name = args.getString(0);
                if (name != null && name.length() > 0) {
                    JSONObject attributes = null;
                    if (!args.isNull(1)) {
                        attributes = args.getJSONObject(1);
                    }
                    HashMap<String, String> a = null;
                    if (attributes != null && attributes.length() > 0) {
                        a = new HashMap<String, String>();
                        Iterator<?> keys = attributes.keys();
                        while (keys.hasNext()) {
                            String key = (String)keys.next();
                            String value = attributes.getString(key);
                            a.put(key, value);
                        }
                    }
                    int customerValueIncrease = args.getInt(2);
                    Localytics.tagEvent(name, a, customerValueIncrease);
                    callbackContext.success();
                } else {
                    callbackContext.error("Expected non-empty name argument.");
                }
            } else {
                callbackContext.error("Expected three arguments.");
            }
            return true;
        } else if (action.equals("tagScreen")) {
            String name = args.getString(0);
            if (name != null && name.length() > 0) {
                Localytics.tagScreen(name);
                callbackContext.success();
            } else {
                callbackContext.error("Expected non-empty name argument.");
            }
            return true;
        } else if (action.equals("setCustomDimension")) {
            if (args.length() == 2) {
                int index = args.getInt(0);
                String value = null;
                if (!args.isNull(1)) {
                    value = args.getString(1);
                }
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
        } else if (action.equals("setIdentifier")) {
            if (args.length() == 2) {
                String key = args.getString(0);
                if (key != null && key.length() > 0) {
                    String value = null;
                    if (!args.isNull(1)) {
                        value = args.getString(1);
                    }
                    Localytics.setIdentifier(key, value);
                    callbackContext.success();
                } else {
                    callbackContext.error("Expected non-empty key argument.");
                }
            } else {
                callbackContext.error("Expected two arguments.");
            }
            return true;
        } else if (action.equals("setCustomerId")) {
            String id = null;
            if (!args.isNull(0)) {
                id = args.getString(0);
            }
            Localytics.setCustomerId(id);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerFullName")) {
            String fullName = null;
            if (!args.isNull(0)) {
                fullName = args.getString(0);
            }
            Localytics.setCustomerFullName(fullName);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerFirstName")) {
            String firstName = null;
            if (!args.isNull(0)) {
                firstName = args.getString(0);
            }
            Localytics.setCustomerFirstName(firstName);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerLastName")) {
            String lastName = null;
            if (!args.isNull(0)) {
                lastName = args.getString(0);
            }
            Localytics.setCustomerLastName(lastName);
            callbackContext.success();
            return true;
        } else if (action.equals("setCustomerEmail")) {
            String email = null;
            if (!args.isNull(0)) {
                email = args.getString(0);
            }
            Localytics.setCustomerEmail(email);
            callbackContext.success();
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
        } else if (action.equals("setPushDisabled")) {
            boolean enabled = args.getBoolean(0);
            Localytics.setPushDisabled(enabled);
            callbackContext.success();
            return true;
        } else if (action.equals("isPushDisabled")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    boolean enabled = Localytics.isPushDisabled();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, enabled));
                }
            });
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
            //No-op
            return true;
        } else if (action.equals("setInAppMessageDismissButtonLocation")) {
            //No-op
            return true;
        } else if (action.equals("getInAppMessageDismissButtonLocation")) {
            //No-op
            return true;
        } else if (action.equals("triggerInAppMessage")) {
            //No-op
            return true;
        } else if (action.equals("dismissCurrentInAppMessage")) {
            //No-op
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
        } else if (action.equals("setSessionTimeoutInterval")) {
            int seconds = args.getInt(0);
            Localytics.setSessionTimeoutInterval(seconds);
            callbackContext.success();
            return true;
        } else if (action.equals("getSessionTimeoutInterval")) {
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    long timeout = Localytics.getSessionTimeoutInterval();
                    callbackContext.success(Long.valueOf(timeout).toString());
                }
            });
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


    /*******************
     * Private Methods
     ******************/
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

    private Date parseISO8601Date(String dateStr) {
        try {
            // Add more formats as needed.
            return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(dateStr);
        } catch (ParseException e) {
            return null;
        }
    }
}