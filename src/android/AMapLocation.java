package com.mobishift.cordova.plugins.amaplocation;


import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.location.Location;
import android.os.SystemClock;
import android.util.Log;

import com.amap.api.location.LocationManagerProxy;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.LocationProviderProxy;

public class AMapLocation extends CordovaPlugin {
    private static final String TAG = "AMapLocation";
    private static final String GET_ACTION = "getCurrentPosition";
    private static final String START_ACTION = "start";
    private static final String STOP_ACTION = "stop";
    private static final String READ_ACCTION = "read";
    private static final int INTERVAL = 60 * 60;

    private int interval = INTERVAL;
    @Override
    public boolean execute(String action, JSONArray args,
            final CallbackContext callbackContext) {
        if (GET_ACTION.equals(action)) {
            LocationManagerProxy mLocationManagerProxy = LocationManagerProxy.getInstance(cordova.getActivity());
            //此方法为每隔固定时间会发起一次定位请求，为了减少电量消耗或网络流量消耗，
            //注意设置合适的定位时间的间隔，并且在合适时间调用removeUpdates()方法来取消定位请求
            //在定位结束后，在合适的生命周期调用destroy()方法     
            //其中如果间隔时间为-1，则定位只定一次
            mLocationManagerProxy.requestLocationData(LocationProviderProxy.AMapNetwork, -1, 15, new AMapLocationListener(){
                @Override
                public void onLocationChanged(com.amap.api.location.AMapLocation amapLocation) {
                    if(amapLocation != null && amapLocation.getAMapException().getErrorCode() == 0){
                        //获取位置信息
                        Double geoLat = amapLocation.getLatitude();
                        Double geoLng = amapLocation.getLongitude();
                        JSONObject jsonObj = new JSONObject();
                        try {
                            jsonObj.put("latitude", geoLat);
                            jsonObj.put("longitude", geoLng);
                        } catch (JSONException e) {
            				callbackContext.error(e.getMessage());
            				return;
            			}
                        callbackContext.success(jsonObj);
                    }else{
                        if(amapLocation != null){
                            callbackContext.error(amapLocation.getAMapException().getErrorCode()+"");
                        }else{
                            callbackContext.error("failed");
                        }
                    }
                }
                
                @Override
                public void onLocationChanged(Location location) {
                    ;
                }
                
                @Override
                public void onProviderDisabled(String provider) {
                    ;
                }
                
                @Override
                public void onProviderEnabled(String provider) {
                    ;
                }
                
                @Override
                public void onStatusChanged(String provider, int status, Bundle extras) {
                    ;
                }
            });
            return true;
        }else if (START_ACTION.equals(action)){
            if(args.length() > 0){
                try{
                    JSONObject jsonObject = args.getJSONObject(0);
                    if(jsonObject.has("maxLength")){
                        LocationPreferences.maxLength = jsonObject.getInt("maxLength");
                    }
                    if(jsonObject.has("interval")){
                        this.interval = jsonObject.getInt("interval");
                    }
                }catch (JSONException ex){
                    Log.e(TAG, ex.getMessage());
                }
            }
            start(callbackContext);
            return true;
        }else if (STOP_ACTION.equals(action)){
            stop();
            return true;
        }else if (READ_ACCTION.equals(action)){
            read(callbackContext);
            return true;
        }
        return false;
    }

    private void start(CallbackContext callbackContext){
        stop();

        Intent intent = new Intent(this.cordova.getActivity(), LocationService.class);
        PendingIntent pendingIntent = PendingIntent.getService(this.cordova.getActivity(), 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

        long nowTime = SystemClock.elapsedRealtime();

        AlarmManager alarmManager = (AlarmManager)this.cordova.getActivity().getSystemService(Context.ALARM_SERVICE);
        alarmManager.setRepeating(AlarmManager.ELAPSED_REALTIME, nowTime, interval* 1000, pendingIntent);
        callbackContext.success();
    }

    private void stop(){
        Intent intent = new Intent(this.cordova.getActivity(), LocationService.class);
        PendingIntent pendingIntent = PendingIntent.getService(this.cordova.getActivity(), 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

        AlarmManager alarmManager = (AlarmManager)this.cordova.getActivity().getSystemService(Context.ALARM_SERVICE);
        alarmManager.cancel(pendingIntent);

    }

    private void read(CallbackContext callbackContext){
        LocationPreferences locationPreferences = LocationPreferences.getLocationPreferences(cordova.getActivity());
        JSONArray jsonArray = locationPreferences.getLocations();
        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, jsonArray);
        callbackContext.sendPluginResult(pluginResult);
        locationPreferences.clearLocations();
    }
}