//
//  RNPLocation.m
//  ReactNativePermissions
//
//  Created by Yonah Forst on 11/07/16.
//  Copyright © 2016 Yonah Forst. All rights reserved.
//

#import "RNPLocation.h"
#import <CoreLocation/CoreLocation.h>

@interface RNPLocation() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager* locationManager;
@property (strong, nonatomic) NSString * lastTypeRequested;
@property (strong, nonatomic ) NSNumber * initallAuthCallback;
@property (copy) void (^completionHandler)(NSString *);
@end

@implementation RNPLocation

+ (NSString *)getStatusForType:(NSString *)type
{
    int status = [CLLocationManager authorizationStatus];
    NSString * rnpStatus =  [RNPLocation convert:status for:type];    
    return rnpStatus;
}


+(NSString*) convert:(CLAuthorizationStatus)status for:(NSString *) type{
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            return RNPStatusAuthorized;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return [type isEqualToString:@"always"] ? RNPStatusDenied : RNPStatusAuthorized;
        case kCLAuthorizationStatusDenied:
            return RNPStatusDenied;
        case kCLAuthorizationStatusRestricted:
            return RNPStatusRestricted;
        default:
            return RNPStatusUndetermined;
    }
}


-(id)init{
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.initallAuthCallback = [NSNumber numberWithBool:YES];
    }
    return self;
}

- (void)request:(NSString*)type completionHandler:(void (^)(NSString *))completionHandler
{
    NSString *status = [RNPLocation getStatusForType:type];    
    if (status != RNPStatusAuthorized) {
        self.lastTypeRequested = type;
        self.completionHandler = completionHandler;
      
        if ([type isEqualToString:@"always"]) {            
            [self.locationManager requestAlwaysAuthorization];
        } else {            
            [self.locationManager requestWhenInUseAuthorization];
        }
    } else {
        completionHandler(status);
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {    
    // Function is called once just after the CLLocationManager is created.
    // This works good in an native app, but since we operating with a callback we needs to skip frist time
    // didChangeAuthorizationStatus is called.
    // https://stackoverflow.com/questions/30106341/swift-locationmanager-didchangeauthorizationstatus-always-called/30107511
    if([self.initallAuthCallback boolValue] == YES){
        self.initallAuthCallback = [NSNumber numberWithBool:NO];
        return;
    }
    
    if (self.completionHandler) {
        NSString * rnpStatus = [RNPLocation convert:status for:self.lastTypeRequested];    
        self.completionHandler(rnpStatus);
        self.completionHandler = nil;
    }
}
@end
