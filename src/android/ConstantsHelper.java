
package com.localytics.android;

public class ConstantsHelper {
    static final String pluginVersion = "Cordova_5.1.0";
    public static void updatePluginVersion() {
        com.localytics.android.Constants.LOCALYTICS_CLIENT_LIBRARY_VERSION = com.localytics.android.Constants.LOCALYTICS_CLIENT_LIBRARY_VERSION + ":" + ConstantsHelper.pluginVersion;
    }

}
