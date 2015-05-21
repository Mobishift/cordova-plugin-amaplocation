package com.mobishift.cordova.plugins.amaplocation;


import java.util.HashMap;
import java.util.Map;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.os.Bundle;
import android.location.Location;

import com.amap.api.location.LocationManagerProxy;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.LocationProviderProxy;

public class AMapLocation extends CordovaPlugin {

    private static final String GET_ACTION = "getCurrentPosition";

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
        }
        return false;
    }
}