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
static int const MAX_LENGTH = 30;
@interface AMapLocation : CDVPlugin <CLLocationManagerDelegate>{
    // Member variables go here.
    CLLocationManager* locationManager;
    BOOL isStart;
    NSString* callbackId;
    int maxLength;
}

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command;
- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)read:(CDVInvokedUrlCommand*)command;

@end

@implementation AMapLocation

- (void)getCurrentPosition:(CDVInvokedUrlCommand*)command{
    callbackId = command.callbackId;
    if(locationManager == nil){
        [self initLocationManager];
    }
    
    [locationManager startUpdatingLocation];
}

- (void)start:(CDVInvokedUrlCommand *)command{
    if(locationManager != nil){
        [self initLocationManager];
    }
    maxLength = MAX_LENGTH;
    NSDictionary* dictionary = (NSDictionary*)[command.arguments objectAtIndex:0];
    if(dictionary != nil && [dictionary objectForKey:MAX_LENGTH_KEY] != nil){
        NSNumber* number = (NSNumber*)[dictionary objectForKey:MAX_LENGTH_KEY];
        maxLength = [number intValue];
    }
    
    isStart = YES;
    [locationManager startUpdatingLocation];
}

- (void)stop:(CDVInvokedUrlCommand *)command{
    if(locationManager != nil){
        [locationManager stopUpdatingLocation];
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
    if(location != nil){
        NSLog(@"lat:%f,lng:%f", location.coordinate.latitude, location.coordinate.longitude);
        if(isStart){
            [self putLocation:location];
        }
        
        if(callbackId != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble: location.coordinate.longitude], LONGITUDE_KEY, [NSNumber numberWithDouble: location.coordinate.latitude], LATITUDE_KEY, nil]];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            callbackId = nil;
        }
    }
}

- (void)initLocationManager{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone; //更新距离
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if([[[UIDevice currentDevice] systemVersion ] floatValue] >= 8.0){
        [locationManager requestWhenInUseAuthorization];
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

- (void) putLocation:(CLLocation*)location{
    //is in background
    UIApplicationState appState = UIApplicationStateActive;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
        appState = [UIApplication sharedApplication].applicationState;
    }
    BOOL inBackground = appState == UIApplicationStateActive;
    
    //get current date
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString* createAt = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableArray* locations = [self getLocations];
    [locations addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:inBackground], IN_BACKGROUND_KEY, createAt, CREATED_AT_KEY, [NSNumber numberWithDouble: location.coordinate.latitude], LATITUDE_KEY, [NSNumber numberWithDouble: location.coordinate.longitude], LONGITUDE_KEY, nil]];
    if([locations count] > maxLength){
        [locations removeObjectAtIndex:0];
    }
    
    [self setLocations:locations];
}

- (void) clearLocations{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey: USER_DEFAULT_KEY];
}


@end