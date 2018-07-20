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

import com.localytics.android.InAppCampaign;
import com.localytics.android.InboxCampaign;
import com.localytics.android.PlacesCampaign;
import com.localytics.android.PushCampaign;
import com.localytics.android.Campaign;
import com.localytics.android.CallToActionListener;

public class CDCTAListener implements CallToActionListener {

    private CallbackContext callbackContext;

    public CDCTAListener(CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
    }

    
    @Override
    public boolean localyticsShouldDeeplink(String url, Campaign campaign) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsShouldDeeplink");

            JSONObject params = new JSONObject();
            params.put("url", url);
            params.put("campaign", getJSONFromGenericCampaign(campaign));
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
        return true;
    }

    @Override
    public void localyticsDidOptOut(boolean optOut, Campaign campaign) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidOptOut");

            JSONObject params = new JSONObject();
            params.put("optedOut", optOut);
            params.put("campaign", getJSONFromGenericCampaign(campaign));
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsDidPrivacyOptOut(boolean optOut, Campaign campaign) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidPrivacyOptOut");

            JSONObject params = new JSONObject();
            params.put("privacyOptedOut", optOut);
            params.put("campaign", getJSONFromGenericCampaign(campaign));
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public boolean localyticsShouldPromptForLocationPermissions(Campaign campaign) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsShouldPromptForLocationPermissions");

            JSONObject params = new JSONObject();
            params.put("campaign", getJSONFromGenericCampaign(campaign));
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
        return true;
    }

    private final JSONObject getJSONFromGenericCampaign(Campaign campaign) throws JSONException {
        if (campaign instanceof PlacesCampaign) {
          return LocalyticsPlugin.toPlacesJSON((PlacesCampaign) campaign);
        } else if (campaign instanceof InboxCampaign) {
          return LocalyticsPlugin.toInboxJSON((InboxCampaign) campaign);
        } else if (campaign instanceof InAppCampaign) {
          return LocalyticsPlugin.toInAppJSON((InAppCampaign) campaign);
        } else if (campaign instanceof PushCampaign) {
          return LocalyticsPlugin.toPushJSON((PushCampaign) campaign);
        }
        return null; //should never happen.

    }
}
