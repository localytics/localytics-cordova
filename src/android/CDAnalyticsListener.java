//
//  CDAnalyticsListener.java
//
//  Copyright 2018 Localytics. All rights reserved.
//

package com.localytics.phonegap;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

public class CDAnalyticsListener implements com.localytics.android.AnalyticsListener {

    private CallbackContext callbackContext;

    public CDAnalyticsListener(CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
    }

    @Override
    public void localyticsSessionWillOpen(final boolean isFirst, final boolean isUpgrade, final boolean isResume) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsSessionWillOpen");

            JSONObject params = new JSONObject();
            params.put("isFirst", isFirst);
            params.put("isUpgrade", isUpgrade);
            params.put("isResume", isResume);
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsSessionDidOpen(final boolean isFirst, final boolean isUpgrade, final boolean isResume) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsSessionDidOpen");

            JSONObject params = new JSONObject();
            params.put("isFirst", isFirst);
            params.put("isUpgrade", isUpgrade);
            params.put("isResume", isResume);
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsSessionWillClose() {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsSessionWillClose");
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsDidTagEvent(final String eventName, final Map<String, String> attributes, final long customerValueIncrease) {
        JSONObject object = new JSONObject();
        try {
          object.put("method", "localyticsDidTagEvent");

          JSONObject params = new JSONObject();
          params.put("name", eventName);
          params.put("attributes", LocalyticsPlugin.toMapJSON(attributes));
          params.put("customerValueIncrease", customerValueIncrease);
          object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

}
