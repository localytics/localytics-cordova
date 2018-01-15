//
//  CDLocationListener.java
//
//  Copyright 2018 Localytics. All rights reserved.
//

package com.localytics.phonegap;

import android.location.Location;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

import com.localytics.android.CircularRegion;
import com.localytics.android.Region;

public class CDLocationListener implements com.localytics.android.LocationListener {

    private CallbackContext callbackContext;

    public CDLocationListener(CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
    }

    @Override
    public void localyticsDidUpdateLocation(Location location) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidUpdateLocation");

            JSONObject locationObject = new JSONObject();
            locationObject.put("latitude", location.getLatitude());
            locationObject.put("longitude", location.getLongitude());

            JSONObject params = new JSONObject();
            params.put("location", locationObject);
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsDidTriggerRegions(List<Region> regions, Region.Event event) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidTriggerRegions");

            JSONObject params = new JSONObject();
            params.put("regions", LocalyticsPlugin.toRegionJSON(regions));
            params.put("event", Region.Event.ENTER.equals(event) ? "enter" : "exit");
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void localyticsDidUpdateMonitoredGeofences(List<CircularRegion> added, List<CircularRegion> removed) {
        JSONObject object = new JSONObject();
        try {
            object.put("method", "localyticsDidUpdateMonitoredGeofences");

            JSONObject params = new JSONObject();
            params.put("added", LocalyticsPlugin.toCircularRegionJSON(added));
            params.put("removed", LocalyticsPlugin.toCircularRegionJSON(removed));
            object.put("params", params);
        } catch (JSONException e) {
            // ignore
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, object);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

}
