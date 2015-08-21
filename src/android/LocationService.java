package com.mobishift.cordova.plugins.amaplocation;

import android.app.Service;
import android.content.Intent;
import android.location.Location;
import android.os.Bundle;
import android.os.IBinder;
import android.support.annotation.Nullable;

import com.amap.api.location.*;
import com.amap.api.location.AMapLocation;

/**
 * Created by Gamma on 15/8/21.
 */
public class LocationService extends Service implements AMapLocationListener{
    private static final String TAG = "LocationService";

    private LocationManagerProxy locationManagerProxy;
    private LocationPreferences locationPreferences;
    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        locationManagerProxy = LocationManagerProxy.getInstance(this);
        locationManagerProxy.requestLocationData(LocationProviderProxy.AMapNetwork, -1, 15, this);
        return START_NOT_STICKY;
    }

    @Override
    public void onLocationChanged(AMapLocation aMapLocation) {
        if(aMapLocation != null && aMapLocation.getAMapException().getErrorCode() == 0){
            locationPreferences = LocationPreferences.getLocationPreferences(this);
            locationPreferences.putLocation(aMapLocation);
        }
    }

    @Override
    public void onLocationChanged(Location location) {

    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {

    }

    @Override
    public void onProviderEnabled(String provider) {

    }

    @Override
    public void onProviderDisabled(String provider) {

    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (locationManagerProxy != null) {
            locationManagerProxy.removeUpdates(this);
            locationManagerProxy.destroy();
        }
    }
}
