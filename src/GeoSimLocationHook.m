#import "GeoSimLocationHook.h"
#import "GeoSimEngine.h"
#import "GeoSimOverlay.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSHashTable<CLLocationManager *> *gActiveManagers = nil;
static NSMutableDictionary<NSString *, NSValue *> *gOrigDidUpdateLocationsIMPs = nil;
static NSMutableDictionary<NSString *, NSValue *> *gOrigDidUpdateToLocationIMPs = nil;
static NSLock *gHookLock = nil;
static CLLocation *gLastRealLocation = nil;
static NSTimer *gHeartbeatTimer = nil;

static IMP gOrigLocationIMP = NULL;
static IMP gOrigSetDelegateIMP = NULL;
static IMP gOrigStartUpdatingIMP = NULL;
static IMP gOrigStopUpdatingIMP = NULL;
static IMP gOrigRequestLocationIMP = NULL;
static IMP gOrigStartSignificantIMP = NULL;
static IMP gOrigIsSimulatedIMP = NULL;
static IMP gOrigIsAccessoryIMP = NULL;

#pragma mark - Helpers

static void geoRecordRealLocation(CLLocation *loc) {
    if (!loc) return;
    [gHookLock lock];
    gLastRealLocation = loc;
    [gHookLock unlock];
}

static void geoPushSpoofedToManager(CLLocationManager *manager) {
    if (!manager || ![GeoSimEngine shared].enabled) return;
    id<CLLocationManagerDelegate> delegate = manager.delegate;
    if (!delegate) return;

    CLLocation *spoofed = [[GeoSimEngine shared] buildSpoofedCLLocation];
    if ([delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [delegate locationManager:manager didUpdateLocations:@[spoofed]];
    } else if ([delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [delegate locationManager:manager didUpdateToLocation:spoofed fromLocation:spoofed];
#pragma clang diagnostic pop
    }
}

static void geoPushSpoofedToAllActiveManagers(void) {
    if (![GeoSimEngine shared].enabled) return;
    NSArray<CLLocationManager *> *managers = nil;
    [gHookLock lock];
    managers = gActiveManagers.allObjects;
    [gHookLock unlock];

    for (CLLocationManager *mgr in managers) {
        geoPushSpoofedToManager(mgr);
    }
}

#pragma mark - Delegate Swizzled Implementations

static void geo_didUpdateLocations(id self, SEL _cmd, CLLocationManager *manager, NSArray<CLLocation *> *locations) {
    if (locations.lastObject) {
        geoRecordRealLocation(locations.lastObject);
    }
    NSArray<CLLocation *> *finalLocations = locations;
    if ([GeoSimEngine shared].enabled) {
        finalLocations = @[[[GeoSimEngine shared] buildSpoofedCLLocation]];
    }

    Class cls = object_getClass(self);
    IMP origIMP = NULL;
    [gHookLock lock];
    while (cls && !origIMP) {
        NSValue *val = gOrigDidUpdateLocationsIMPs[NSStringFromClass(cls)];
        if (val) origIMP = val.pointerValue;
        cls = class_getSuperclass(cls);
    }
    [gHookLock unlock];

    if (origIMP) {
        ((void (*)(id, SEL, CLLocationManager *, NSArray<CLLocation *> *))origIMP)(self, _cmd, manager, finalLocations);
    }
}

static void geo_didUpdateToLocation(id self, SEL _cmd, CLLocationManager *manager, CLLocation *newLocation, CLLocation *oldLocation) {
    if (newLocation) {
        geoRecordRealLocation(newLocation);
    }
    CLLocation *finalNew = newLocation;
    CLLocation *finalOld = oldLocation;
    if ([GeoSimEngine shared].enabled) {
        finalNew = [[GeoSimEngine shared] buildSpoofedCLLocation];
        finalOld = finalNew;
    }

    Class cls = object_getClass(self);
    IMP origIMP = NULL;
    [gHookLock lock];
    while (cls && !origIMP) {
        NSValue *val = gOrigDidUpdateToLocationIMPs[NSStringFromClass(cls)];
        if (val) origIMP = val.pointerValue;
        cls = class_getSuperclass(cls);
    }
    [gHookLock unlock];

    if (origIMP) {
        ((void (*)(id, SEL, CLLocationManager *, CLLocation *, CLLocation *))origIMP)(self, _cmd, manager, finalNew, finalOld);
    }
}

static void geoSwizzleDelegateClassIfNeeded(id delegate) {
    if (!delegate) return;
    Class cls = object_getClass(delegate);
    if (!cls) return;
    NSString *clsName = NSStringFromClass(cls);

    [gHookLock lock];
    SEL selModern = @selector(locationManager:didUpdateLocations:);
    if (!gOrigDidUpdateLocationsIMPs[clsName]) {
        Method m = class_getInstanceMethod(cls, selModern);
        if (m) {
            IMP curIMP = method_getImplementation(m);
            if (curIMP != (IMP)geo_didUpdateLocations) {
                if (class_addMethod(cls, selModern, (IMP)geo_didUpdateLocations, method_getTypeEncoding(m))) {
                    gOrigDidUpdateLocationsIMPs[clsName] = [NSValue valueWithPointer:curIMP];
                } else {
                    IMP prev = method_setImplementation(m, (IMP)geo_didUpdateLocations);
                    gOrigDidUpdateLocationsIMPs[clsName] = [NSValue valueWithPointer:prev];
                }
            }
        }
    }

    SEL selLegacy = @selector(locationManager:didUpdateToLocation:fromLocation:);
    if (!gOrigDidUpdateToLocationIMPs[clsName]) {
        Method m = class_getInstanceMethod(cls, selLegacy);
        if (m) {
            IMP curIMP = method_getImplementation(m);
            if (curIMP != (IMP)geo_didUpdateToLocation) {
                if (class_addMethod(cls, selLegacy, (IMP)geo_didUpdateToLocation, method_getTypeEncoding(m))) {
                    gOrigDidUpdateToLocationIMPs[clsName] = [NSValue valueWithPointer:curIMP];
                } else {
                    IMP prev = method_setImplementation(m, (IMP)geo_didUpdateToLocation);
                    gOrigDidUpdateToLocationIMPs[clsName] = [NSValue valueWithPointer:prev];
                }
            }
        }
    }
    [gHookLock unlock];
}

#pragma mark - CLLocationManager Swizzled Implementations

static CLLocation *geo_location(CLLocationManager *self, SEL _cmd) {
    CLLocation *orig = ((CLLocation *(*)(id, SEL))gOrigLocationIMP)(self, _cmd);
    if (orig) geoRecordRealLocation(orig);
    if ([GeoSimEngine shared].enabled) {
        return [[GeoSimEngine shared] buildSpoofedCLLocation];
    }
    return orig;
}

static void geo_setDelegate(CLLocationManager *self, SEL _cmd, id<CLLocationManagerDelegate> delegate) {
    if (delegate) {
        geoSwizzleDelegateClassIfNeeded(delegate);
    }
    ((void (*)(id, SEL, id))gOrigSetDelegateIMP)(self, _cmd, delegate);
}

static void geo_startUpdatingLocation(CLLocationManager *self, SEL _cmd) {
    [gHookLock lock];
    [gActiveManagers addObject:self];
    [gHookLock unlock];

    ((void (*)(id, SEL))gOrigStartUpdatingIMP)(self, _cmd);

    if ([GeoSimEngine shared].enabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            geoPushSpoofedToManager(self);
        });
    }
}

static void geo_stopUpdatingLocation(CLLocationManager *self, SEL _cmd) {
    [gHookLock lock];
    [gActiveManagers removeObject:self];
    [gHookLock unlock];

    ((void (*)(id, SEL))gOrigStopUpdatingIMP)(self, _cmd);
}

static void geo_requestLocation(CLLocationManager *self, SEL _cmd) {
    [gHookLock lock];
    [gActiveManagers addObject:self];
    [gHookLock unlock];

    ((void (*)(id, SEL))gOrigRequestLocationIMP)(self, _cmd);

    if ([GeoSimEngine shared].enabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            geoPushSpoofedToManager(self);
        });
    }
}

static void geo_startMonitoringSignificantLocationChanges(CLLocationManager *self, SEL _cmd) {
    [gHookLock lock];
    [gActiveManagers addObject:self];
    [gHookLock unlock];

    ((void (*)(id, SEL))gOrigStartSignificantIMP)(self, _cmd);

    if ([GeoSimEngine shared].enabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            geoPushSpoofedToManager(self);
        });
    }
}

#pragma mark - CLLocationSourceInformation Swizzled Implementations

static BOOL geo_isSimulatedBySoftware(id self, SEL _cmd) {
    if ([GeoSimEngine shared].enabled) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))gOrigIsSimulatedIMP)(self, _cmd);
}

static BOOL geo_isProducedByAccessory(id self, SEL _cmd) {
    if ([GeoSimEngine shared].enabled) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))gOrigIsAccessoryIMP)(self, _cmd);
}

#pragma mark - Hook Installer

static void geoHookMethod(Class cls, SEL sel, IMP newIMP, IMP *outOrigIMP) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;
    *outOrigIMP = method_setImplementation(m, newIMP);
}

@implementation GeoSimLocationHook

+ (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gHookLock = [[NSLock alloc] init];
        gActiveManagers = [NSHashTable weakObjectsHashTable];
        gOrigDidUpdateLocationsIMPs = [NSMutableDictionary dictionary];
        gOrigDidUpdateToLocationIMPs = [NSMutableDictionary dictionary];

        Class lmClass = [CLLocationManager class];
        geoHookMethod(lmClass, @selector(location), (IMP)geo_location, &gOrigLocationIMP);
        geoHookMethod(lmClass, @selector(setDelegate:), (IMP)geo_setDelegate, &gOrigSetDelegateIMP);
        geoHookMethod(lmClass, @selector(startUpdatingLocation), (IMP)geo_startUpdatingLocation, &gOrigStartUpdatingIMP);
        geoHookMethod(lmClass, @selector(stopUpdatingLocation), (IMP)geo_stopUpdatingLocation, &gOrigStopUpdatingIMP);
        geoHookMethod(lmClass, @selector(requestLocation), (IMP)geo_requestLocation, &gOrigRequestLocationIMP);
        geoHookMethod(lmClass, @selector(startMonitoringSignificantLocationChanges), (IMP)geo_startMonitoringSignificantLocationChanges, &gOrigStartSignificantIMP);

        Class srcInfoClass = NSClassFromString(@"CLLocationSourceInformation");
        if (srcInfoClass) {
            geoHookMethod(srcInfoClass, NSSelectorFromString(@"isSimulatedBySoftware"), (IMP)geo_isSimulatedBySoftware, &gOrigIsSimulatedIMP);
            geoHookMethod(srcInfoClass, NSSelectorFromString(@"isProducedByAccessory"), (IMP)geo_isProducedByAccessory, &gOrigIsAccessoryIMP);
        }

        // Push updates immediately whenever GeoSim state changes (teleport, joystick, route tick)
        [[NSNotificationCenter defaultCenter] addObserverForName:GeoSimEngineStateDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            geoPushSpoofedToAllActiveManagers();
        }];

        // Keep location fresh at 1Hz for apps expecting periodic GPS heartbeats while idle
        dispatch_async(dispatch_get_main_queue(), ^{
            gHeartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer) {
                GeoSimEngine *eng = [GeoSimEngine shared];
                if (eng.enabled && !eng.joystickActive && !(eng.routeRunning && !eng.routePaused)) {
                    geoPushSpoofedToAllActiveManagers();
                }
            }];
            [[NSRunLoop mainRunLoop] addTimer:gHeartbeatTimer forMode:NSRunLoopCommonModes];
        });
    });
}

+ (nullable CLLocation *)lastObservedRealLocation {
    [gHookLock lock];
    CLLocation *loc = gLastRealLocation;
    [gHookLock unlock];
    return loc;
}

@end

__attribute__((constructor))
static void GeoSimDylibEntry(void) {
    @autoreleasepool {
        [GeoSimLocationHook install];
        [GeoSimOverlay install];
    }
}
