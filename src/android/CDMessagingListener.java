//
//  CDMessagingListener.java
//
//  Copyright 2018 Localytics. All rights reserved.
//

package com.localytics.phonegap;

import android.app.Notification;
import android.location.Location;
import android.net.Uri;
import android.support.v4.app.NotificationCompat;
import android.util.SparseArray;
import android.view.View;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

import com.localytics.android.InAppCampaign;
import com.localytics.android.InAppConfiguration;
import com.localytics.android.PlacesCampaign;
import com.localytics.android.PushCampaign;

public class CDMessagingListener implements com.localytics.android.MessagingListenerV2 {

    private CallbackContext callbackContext;
    private SparseArray<InAppCampaign> inAppCampaignCache;
    private SparseArray<PushCampaign> pushCampaignCache;
    private SparseArray<PlacesCampaign> placesCampaignCache;

    private JSONObject inAppConfig;
    private JSONObject pushConfig;
    private JSONObject placesConfig;

    public CDMessagingListener(CallbackContext callbackContext, SparseArray<InAppCampaign> inAppCampaignCache,
                              SparseArray<PushCampaign> pushCampaignCache, SparseArray<PlacesCampaign> placesCampaignCache) {
        this.callbackContext = callbackContext;
        this.inAppCampaignCache = inAppCampaignCache;
        this.pushCampaignCache = pushCampaignCache;
        this.placesCampaignCache = placesCampaignCache;
    }

    public void setInAppConfiguration(JSONObject config) {
        inAppConfig = config;
    }

    public void setPushConfiguration(JSONObject config) {
        pushConfig = config;
    }

    public void setPlacesConfiguration(JSONObject config) {
        placesConfig = config;
    }

    @Override
    public boolean localyticsShouldShowInAppMessage(InAppCampaign campaign) {
      // Cache campaign
      inAppCampaignCache.put((int) campaign.getCampaignId(), campaign);

      boolean shouldShow = true;
      JSONObject object = new JSONObject();
      JSONObject params = new JSONObject();
      try {
          object.put("method", "localyticsShouldShowInAppMessage");
          object.put("params", params);
          params.put("campaign", LocalyticsPlugin.toInAppJSON(campaign));
      } catch (JSONException e) {
          // ignore
      }

      if (inAppConfig != null) {

          // Global Suppression
          if (inAppConfig.has("shouldShow")) {
              shouldShow = inAppConfig.optBoolean("shouldShow");
          }

          // DIY In-App. This callback will suppress the in-app and emit an event
          // for manually handling
          if (inAppConfig.has("diy") && inAppConfig.optBoolean("diy")) {
              try {
                  object.put("method", "localyticsDiyInAppMessage");
              } catch (JSONException e) {
                  // ignore
              }

              PluginResult result = new PluginResult(PluginResult.Status.OK, object);
              result.setKeepCallback(true);
              callbackContext.sendPluginResult(result);

              return false;
          }
      }

      try {
          params.put("shouldShow", shouldShow);
      } catch (JSONException e) {
          // ignore
      }

      PluginResult result = new PluginResult(PluginResult.Status.OK, object);
      result.setKeepCallback(true);
      callbackContext.sendPluginResult(result);

      return shouldShow;
    }

    @Override
    public void localyticsWillDisplayInAppMessage() {
        // Not called for MessagingListenerV2
    }

    @Override
    public InAppConfiguration localyticsWillDisplayInAppMessage(InAppCampaign campaign, InAppConfiguration configuration) {
        if (inAppConfig != null) {
            if (inAppConfig.has("aspectRatio")) {
                configuration.setAspectRatio((float) inAppConfig.optDouble("aspectRatio"));
            }
            if (inAppConfig.has("backgroundAlpha")) {
                configuration.setBackgroundAlpha((float) inAppConfig.optDouble("backgroundAlpha"));
            }
            if (inAppConfig.has("bannerOffsetDps")) {
                configuration.setBannerOffsetDps(inAppConfig.optInt("bannerOffsetDps"));
            }
            if (inAppConfig.has("dismissButtonLocation")) {
                String location = inAppConfig.optString("dismissButtonLocation");
                configuration.setDismissButtonLocation(LocalyticsPlugin.toLocation(location));
            }
            if (inAppConfig.has("dismissButtonHidden")) {
                boolean hidden = inAppConfig.optBoolean("dismissButtonHidden");
                configuration.setDismissButtonVisibility(hidden ? View.GONE : View.VISIBLE);
            }
        }

        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsWillDisplayInAppMessage");

            JSONObject params = new JSONObject();
            params.put("campaign", LocalyticsPlugin.toInAppJSON(campaign));
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        return configuration;
    }

    @Override
    public void localyticsDidDisplayInAppMessage() {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidDisplayInAppMessage");
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsWillDismissInAppMessage() {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsWillDismissInAppMessage");
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsDidDismissInAppMessage() {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidDismissInAppMessage");
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public boolean localyticsShouldDelaySessionStartInAppMessages() {
        boolean shouldDelay = false;
        if (inAppConfig != null && inAppConfig.has("delaySessionStart")) {
            shouldDelay = inAppConfig.optBoolean("delaySessionStart");
        }

        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsShouldDelaySessionStartInAppMessages");

            JSONObject params = new JSONObject();
            params.put("shouldDelay", shouldDelay);
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        return shouldDelay;
    }

    @Override
    public boolean localyticsShouldShowPushNotification(PushCampaign campaign) {
        // Cache campaign
        pushCampaignCache.put((int) campaign.getCampaignId(), campaign);

        boolean shouldShow = true;
        JSONObject object = new JSONObject();
        JSONObject params = new JSONObject();
        try {
            object.put("method", "localyticsShouldShowPushNotification");
            object.put("params", params);
            params.put("campaign", LocalyticsPlugin.toPushJSON(campaign));
        } catch (JSONException e) {
            // ignore
        }

        if (pushConfig != null) {

            // Global Suppression
            if (pushConfig.has("shouldShow")) {
                shouldShow = pushConfig.optBoolean("shouldShow");
            }

            // DIY Push. This callback will suppress the push and emit an event
            // for manually handling
            if (pushConfig.has("diy") && pushConfig.optBoolean("diy")) {
                try {
                    object.put("method", "localyticsDiyPushNotification");
                } catch (JSONException e) {
                    // ignore
                }

                PluginResult result = new PluginResult(PluginResult.Status.OK, object);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);

                return false;
            }
        }

        try {
            params.put("shouldShow", shouldShow);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        return shouldShow;
    }

    @Override
    public NotificationCompat.Builder localyticsWillShowPushNotification(NotificationCompat.Builder builder, PushCampaign campaign) {
        if (pushConfig != null) {
            updateNotification(builder, pushConfig);
        }

        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsWillShowPushNotification");

            JSONObject params = new JSONObject();
            params.put("campaign", LocalyticsPlugin.toPushJSON(campaign));
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        return builder;
    }

    @Override
    public boolean localyticsShouldShowPlacesPushNotification(PlacesCampaign campaign) {
        // Cache campaign
        placesCampaignCache.put((int) campaign.getCampaignId(), campaign);

        boolean shouldShow = true;
        JSONObject object = new JSONObject();
        JSONObject params = new JSONObject();
        try {
            object.put("method", "localyticsShouldShowPlacesPushNotification");
            object.put("params", params);
            params.put("campaign", LocalyticsPlugin.toPlacesJSON(campaign));
        } catch (JSONException e) {
            // ignore
        }

        if (placesConfig != null) {

            // Global Suppression
            if (placesConfig.has("shouldShow")) {
                shouldShow = placesConfig.optBoolean("shouldShow");
            }

            // DIY Places. This callback will suppress the push and emit an event
            // for manually handling
            if (placesConfig.has("diy") && placesConfig.optBoolean("diy")) {
                try {
                    object.put("method", "localyticsDiyPlacesPushNotification");
                } catch (JSONException e) {
                    // ignore
                }

                PluginResult result = new PluginResult(PluginResult.Status.OK, object);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);

                return false;
            }
        }

        try {
            params.put("shouldShow", shouldShow);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        return shouldShow;
    }

    @Override
    public NotificationCompat.Builder localyticsWillShowPlacesPushNotification(NotificationCompat.Builder builder, PlacesCampaign campaign) {
        if (placesConfig != null) {
            updateNotification(builder, placesConfig);
        }

        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsWillShowPlacesPushNotification");

            JSONObject params = new JSONObject();
            params.put("campaign", LocalyticsPlugin.toPlacesJSON(campaign));
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);

        return builder;
    }

    private NotificationCompat.Builder updateNotification(NotificationCompat.Builder builder, JSONObject config) {
        if (config.has("category")) {
            builder.setCategory(config.optString("category"));
        }
        if (config.has("color")) {
            builder.setColor(config.optInt("color"));
        }
        if (config.has("contentInfo")) {
            builder.setContentInfo(config.optString("contentInfo"));
        }
        if (config.has("contentTitle")) {
            builder.setContentTitle(config.optString("contentTitle"));
        }
        if (config.has("defaults")) {
            JSONArray defaultsArray = config.optJSONArray("defaults");
            List<String> defaultsList = LocalyticsPlugin.toStringList(defaultsArray);
            if (defaultsList.contains("all")) {
                builder.setDefaults(Notification.DEFAULT_ALL);
            } else {
                int defaults = 0;
                if (defaultsList.contains("lights")) {
                    defaults |= Notification.DEFAULT_LIGHTS;
                }
              if (defaultsList.contains("sound")) {
                  defaults |= Notification.DEFAULT_SOUND;
              }
              if (defaultsList.contains("vibrate")) {
                  defaults |= Notification.DEFAULT_VIBRATE;
              }
              builder.setDefaults(defaults);
            }
        }
        if (config.has("priority")) {
            builder.setPriority(config.optInt("priority"));
        }
        if (config.has("sound")) {
            builder.setSound(Uri.parse(config.optString("sound")));
        }
        if (config.has("vibrate")) {
            JSONArray vibrateArray = config.optJSONArray("vibrate");
            int length = vibrateArray.length();
            long[] vibrate = new long[length];
            for (int i = 0; i < length; i++) {
                vibrate[i] = (long) vibrateArray.optInt(i);
            }
            builder.setVibrate(vibrate);
        }

        return builder;
    }

}
