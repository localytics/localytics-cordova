cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
    {
        "file": "plugins/com.localytics.phonegap.LocalyticsPlugin/www/localytics.js",
        "id": "com.localytics.phonegap.LocalyticsPlugin.Localytics",
        "clobbers": [
            "Localytics"
        ]
    }
];
module.exports.metadata = 
// TOP OF METADATA
{
    "com.localytics.phonegap.LocalyticsPlugin": "1.0.0"
};
// BOTTOM OF METADATA
});