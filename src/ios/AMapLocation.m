//
//  AMapLocation.m
//  乐停车
//
//  Created by Gamma on 15/8/24.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Cordova/CDV.h>

static NSString* const USER_DEFAULT_KEY = @"locations";
static NSString* const LATITUDE_KEY = @"latitude";
static NSString* const LONGITUDE_KEY = @"longitude";
static NSString* const CREATED_AT_KEY = @"createdAt";
static NSString* const IN_BACKGROUND_KEY = @"inBackground";
static NSString* const MAX_LENGTH_KEY = @"maxLength";
static NSString* const INTERVAL_KEY = @"interval";

static int const MAX_LENGTH = 30;
static int const INTERVAL = 60 * 60;
@interface AMapLocation : CDVPlugin <CLLocationManagerDelegate>{
    // Member variables go here.
    CLLocationManager* locationManager;
    CLLocationManager* curLocationManager;
    BOOL isStart;
    NSString* callbackId;
    int maxLength;
    int interval;
}

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command;
- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)read:(CDVInvokedUrlCommand*)command;
- (CLLocationCoordinate2D)transformFromWGSToGCJ:(CLLocationCoordinate2D) wgLoc;
- (CLLocationCoordinate2D)bd_encrypt:(CLLocationCoordinate2D)gcLoc;
- (CLLocationCoordinate2D)bd_decrypt:(CLLocationCoordinate2D) bdLoc;

@end

@implementation AMapLocation

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command{
    callbackId = command.callbackId;
    if(curLocationManager == nil){
        curLocationManager = [[CLLocationManager alloc] init];
        curLocationManager.distanceFilter = kCLDistanceFilterNone;
        curLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        curLocationManager.delegate = self;
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined && [[[UIDevice currentDevice] systemVersion ] floatValue] >= 8.0){
            [curLocationManager requestAlwaysAuthorization];
        }

    }
    
    if(![CLLocationManager locationServicesEnabled]){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"定位服务未打开"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"请在设置中允许乐停车使用定位服务"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    [curLocationManager startUpdatingLocation];
}

- (void)start:(CDVInvokedUrlCommand *)command{
    maxLength = MAX_LENGTH;
    interval = INTERVAL;
    NSDictionary* dictionary = (NSDictionary*)[command.arguments objectAtIndex:0];
    if(dictionary != nil){
        if([dictionary objectForKey:MAX_LENGTH_KEY] != nil){
            NSNumber* number = (NSNumber*)[dictionary objectForKey:MAX_LENGTH_KEY];
            maxLength = [number intValue];
        }
        if([dictionary objectForKey:INTERVAL_KEY] != nil){
            NSNumber* number = (NSNumber*)[dictionary objectForKey:INTERVAL_KEY];
            interval = [number intValue];
        }
    }
    if(locationManager == nil){
        [self initLocationManager];
    }
    
//    if(timer != nil){
//        [timer invalidate];
//        timer = nil;
//    }
    isStart = YES;
//    timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(worker) userInfo:nil repeats:YES];
    [locationManager startMonitoringSignificantLocationChanges];
}

- (void)stop:(CDVInvokedUrlCommand *)command{
    if(locationManager != nil){
        [locationManager stopMonitoringSignificantLocationChanges];
    }
    isStart = NO;
}

- (void)read:(CDVInvokedUrlCommand *)command{
    NSArray* array = [self getLocations];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:array];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    [self clearLocations];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation* location = (CLLocation*)[locations lastObject];
    CLLocationCoordinate2D gcjLocation = [self transformFromWGSToGCJ: location.coordinate];
    if(manager == curLocationManager){
        if(callbackId != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble: gcjLocation.longitude], LONGITUDE_KEY, [NSNumber numberWithDouble: gcjLocation.latitude], LATITUDE_KEY, nil]];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            callbackId = nil;
        }
        [manager stopUpdatingLocation];
    }else{
        NSLog(@"lat:%f,lng:%f", gcjLocation.latitude, gcjLocation.longitude);
        if(isStart){
            [self putLocation:gcjLocation];
        }
    }
        
//        if(callbackId != nil){
//            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble: gcjLocation.longitude], LONGITUDE_KEY, [NSNumber numberWithDouble: gcjLocation.latitude], LATITUDE_KEY, nil]];
//            
//            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
//            callbackId = nil;
//        }
}

//- (void)worker{
//    if(isStart){
//        [locationManager startUpdatingLocation];
//    }
//}


- (void)initLocationManager{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone; //更新距离
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if([[[UIDevice currentDevice] systemVersion ] floatValue] >= 8.0){
        [locationManager requestAlwaysAuthorization];
    }
}

- (NSMutableArray*)getLocations {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* array = [userDefaults objectForKey:USER_DEFAULT_KEY];
    NSMutableArray* mutableArray = nil;
    if(array != nil){
        mutableArray = [NSMutableArray arrayWithArray:array];
    }else{
        mutableArray = [[NSMutableArray alloc] init];
    }
    return mutableArray;
}

- (void) setLocations:(NSMutableArray*)locations{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:locations forKey:USER_DEFAULT_KEY];
}

- (NSString*)dictionaryToJson:(NSDictionary*)dictionary{
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
}

- (void) putLocation:(CLLocationCoordinate2D)location{
    //is in background
    UIApplicationState appState = UIApplicationStateActive;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
        appState = [UIApplication sharedApplication].applicationState;
    }
    BOOL inBackground = appState != UIApplicationStateActive;
    
    //get current date
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString* createAt = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableArray* locations = [self getLocations];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:inBackground], IN_BACKGROUND_KEY, createAt, CREATED_AT_KEY, [NSNumber numberWithDouble: location.latitude], LATITUDE_KEY, [NSNumber numberWithDouble: location.longitude], LONGITUDE_KEY, nil];
    [locations addObject:[self dictionaryToJson:dictionary]];
    if([locations count] > maxLength){
        [locations removeObjectAtIndex:0];
    }
    
    [self setLocations:locations];
}

- (void) clearLocations{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey: USER_DEFAULT_KEY];
}

const double pi = 3.14159265358979324;
const double a = 6378245.0;
const double ee = 0.00669342162296594323;

bool outOfChina(double lat, double lon)
{
    if (lon < 72.004 || lon > 137.8347)
        return true;
    if (lat < 0.8293 || lat > 55.8271)
        return true;
    return false;
}

double transformLat(double x, double y)
{
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 *sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
}

double transformLon(double x, double y)
{
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
}

///
///  WGS-84 到 GCJ-02 的转换
///
- (CLLocationCoordinate2D) transformFromWGSToGCJ:(CLLocationCoordinate2D) wgLoc
{
    CLLocationCoordinate2D mgLoc;
    if (outOfChina(wgLoc.latitude, wgLoc.longitude))
    {
        mgLoc = wgLoc;
        return mgLoc;
    }
    double dLat = transformLat(wgLoc.longitude - 105.0, wgLoc.latitude - 35.0);
    double dLon = transformLon(wgLoc.longitude - 105.0, wgLoc.latitude - 35.0);
    double radLat = wgLoc.latitude / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    mgLoc = CLLocationCoordinate2DMake(wgLoc.latitude + dLat, wgLoc.longitude + dLon);
    
    return mgLoc;
}

///
///  GCJ-02 坐标转换成 BD-09 坐标
///

const double x_pi = 3.14159265358979324 * 3000.0 / 180.0;
- (CLLocationCoordinate2D)bd_encrypt:(CLLocationCoordinate2D)gcLoc
{
    double x = gcLoc.longitude, y = gcLoc.latitude;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) + 0.000003 * cos(x * x_pi);
    return CLLocationCoordinate2DMake(z * cos(theta) + 0.0065, z * sin(theta) + 0.006);
}

///
///   BD-09 坐标转换成 GCJ-02坐标
///
///
- (CLLocationCoordinate2D)bd_decrypt:(CLLocationCoordinate2D) bdLoc
{
    double x = bdLoc.longitude - 0.0065, y = bdLoc.latitude - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
    return CLLocationCoordinate2DMake(z * cos(theta), z * sin(theta));

}


@end