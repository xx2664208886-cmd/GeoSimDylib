#import "GeoSimEngine.h"
#import "GeoSimCoords.h"
#import <MapKit/MapKit.h>

NSNotificationName const GeoSimEngineStateDidChangeNotification = @"GeoSimEngineStateDidChangeNotification";

static NSString * const kPrefEnabled       = @"com.geosim.hook.enabled";
static NSString * const kPrefLat           = @"com.geosim.hook.lat";
static NSString * const kPrefLng           = @"com.geosim.hook.lng";
static NSString * const kPrefSpeed         = @"com.geosim.hook.speed";
static NSString * const kPrefJitter        = @"com.geosim.hook.jitter";
static NSString * const kPrefFavorites     = @"com.geosim.hook.favorites";
static NSString * const kPrefRecents       = @"com.geosim.hook.recents";
static NSString * const kPrefRangeEnabled  = @"com.geosim.hook.rangeEnabled";
static NSString * const kPrefRangeLat      = @"com.geosim.hook.rangeLat";
static NSString * const kPrefRangeLng      = @"com.geosim.hook.rangeLng";
static NSString * const kPrefRangeRadius   = @"com.geosim.hook.rangeRadius";
static NSString * const kPrefAccessPwd     = @"com.geosim.hook.accessPassword";
static NSString * const kDefaultAccessPwd  = @"122819";
static NSString * const kAdminAccessPwd    = @"119119";

@implementation GeoSimPlace

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latWGS84, self.lngWGS84);
}

- (NSDictionary *)toDictionary {
    return @{
        @"name": self.name ?: @"未命名地点",
        @"note": self.note ?: @"",
        @"lat": @(self.latWGS84),
        @"lng": @(self.lngWGS84),
        @"ts": @(self.timestamp)
    };
}

+ (nullable instancetype)fromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    NSNumber *lat = dict[@"lat"];
    NSNumber *lng = dict[@"lng"];
    if (![lat isKindOfClass:[NSNumber class]] || ![lng isKindOfClass:[NSNumber class]]) return nil;
    GeoSimPlace *p = [[GeoSimPlace alloc] init];
    p.name = [dict[@"name"] isKindOfClass:[NSString class]] ? dict[@"name"] : @"未命名地点";
    p.note = [dict[@"note"] isKindOfClass:[NSString class]] ? dict[@"note"] : @"";
    p.latWGS84 = lat.doubleValue;
    p.lngWGS84 = lng.doubleValue;
    p.timestamp = [dict[@"ts"] isKindOfClass:[NSNumber class]] ? [dict[@"ts"] doubleValue] : 0.0;
    return p;
}

@end

@interface GeoSimEngine ()
@property (nonatomic, assign, readwrite) BOOL enabled;
@property (nonatomic, assign, readwrite) CLLocationCoordinate2D currentWGS84;
@property (nonatomic, assign, readwrite) double currentCourse;
@property (nonatomic, assign, readwrite) BOOL joystickActive;
@property (nonatomic, assign, readwrite) CGPoint joystickVector;

@property (nonatomic, strong) NSMutableArray<NSValue *> *mutableWaypoints;
@property (nonatomic, strong) NSMutableArray<NSValue *> *mutablePolyline;
@property (nonatomic, assign, readwrite) BOOL routeRunning;
@property (nonatomic, assign, readwrite) BOOL routePaused;
@property (nonatomic, assign, readwrite) double routeProgress;

@property (nonatomic, strong) NSMutableArray<GeoSimPlace *> *mutableFavorites;
@property (nonatomic, strong) NSMutableArray<GeoSimPlace *> *mutableRecents;

@property (nonatomic, strong, nullable) NSTimer *tickTimer;
@property (nonatomic, assign) NSUInteger routeSegIndex;
@property (nonatomic, assign) double routeSegOffsetMeters;
@property (nonatomic, assign) double routeTotalMeters;
@property (nonatomic, assign) double routeTraveledMeters;
@property (nonatomic, assign) NSTimeInterval lastTickTime;
@end

@implementation GeoSimEngine

+ (instancetype)shared {
    static GeoSimEngine *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GeoSimEngine alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableWaypoints = [NSMutableArray array];
        _mutablePolyline = [NSMutableArray array];
        _mutableFavorites = [NSMutableArray array];
        _mutableRecents = [NSMutableArray array];
        _altitude = 15.0;
        _currentCourse = 0.0;
        _routeTransportMode = GeoSimTransportWalking;
        [self loadState];
    }
    return self;
}

- (NSArray<NSValue *> *)waypointsWGS84 { return [self.mutableWaypoints copy]; }
- (NSArray<NSValue *> *)routePolylineWGS84 { return [self.mutablePolyline copy]; }
- (NSArray<GeoSimPlace *> *)favorites { return [self.mutableFavorites copy]; }
- (NSArray<GeoSimPlace *> *)recents { return [self.mutableRecents copy]; }

- (void)loadState {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _enabled = [ud boolForKey:kPrefEnabled];
    if ([ud objectForKey:kPrefLat] && [ud objectForKey:kPrefLng]) {
        _currentWGS84 = CLLocationCoordinate2DMake([ud doubleForKey:kPrefLat], [ud doubleForKey:kPrefLng]);
    } else {
        // Default: Beijing Tiananmen (WGS-84)
        _currentWGS84 = CLLocationCoordinate2DMake(39.904989, 116.405285);
    }
    double spd = [ud doubleForKey:kPrefSpeed];
    _speedMetersPerSecond = (spd > 0.1) ? spd : 1.5;
    _speedJitterRatio = [ud objectForKey:kPrefJitter] ? [ud doubleForKey:kPrefJitter] : 0.10;

    _rangeEnabled = [ud boolForKey:kPrefRangeEnabled];
    if ([ud objectForKey:kPrefRangeLat] && [ud objectForKey:kPrefRangeLng]) {
        _rangeCenterWGS84 = CLLocationCoordinate2DMake([ud doubleForKey:kPrefRangeLat], [ud doubleForKey:kPrefRangeLng]);
    } else {
        _rangeCenterWGS84 = _currentWGS84;
    }
    double r = [ud doubleForKey:kPrefRangeRadius];
    _rangeRadiusMeters = (r >= 10.0) ? r : 200.0;

    NSArray *favRaw = [ud arrayForKey:kPrefFavorites];
    for (NSDictionary *d in favRaw) {
        GeoSimPlace *p = [GeoSimPlace fromDictionary:d];
        if (p) [_mutableFavorites addObject:p];
    }
    NSArray *recRaw = [ud arrayForKey:kPrefRecents];
    for (NSDictionary *d in recRaw) {
        GeoSimPlace *p = [GeoSimPlace fromDictionary:d];
        if (p) [_mutableRecents addObject:p];
    }
}

- (void)saveState {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:self.enabled forKey:kPrefEnabled];
    [ud setDouble:self.currentWGS84.latitude forKey:kPrefLat];
    [ud setDouble:self.currentWGS84.longitude forKey:kPrefLng];
    [ud setDouble:self.speedMetersPerSecond forKey:kPrefSpeed];
    [ud setDouble:self.speedJitterRatio forKey:kPrefJitter];
    [ud setBool:self.rangeEnabled forKey:kPrefRangeEnabled];
    [ud setDouble:self.rangeCenterWGS84.latitude forKey:kPrefRangeLat];
    [ud setDouble:self.rangeCenterWGS84.longitude forKey:kPrefRangeLng];
    [ud setDouble:self.rangeRadiusMeters forKey:kPrefRangeRadius];

    NSMutableArray *favArr = [NSMutableArray array];
    for (GeoSimPlace *p in self.mutableFavorites) [favArr addObject:[p toDictionary]];
    [ud setObject:favArr forKey:kPrefFavorites];

    NSMutableArray *recArr = [NSMutableArray array];
    for (GeoSimPlace *p in self.mutableRecents) [recArr addObject:[p toDictionary]];
    [ud setObject:recArr forKey:kPrefRecents];
}

- (void)notifyChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:GeoSimEngineStateDidChangeNotification object:self];
    });
}

- (void)recordRecent:(CLLocationCoordinate2D)coord name:(nullable NSString *)name {
    GeoSimPlace *place = [[GeoSimPlace alloc] init];
    place.name = (name.length > 0) ? name : [NSString stringWithFormat:@"%.5f, %.5f", coord.latitude, coord.longitude];
    place.latWGS84 = coord.latitude;
    place.lngWGS84 = coord.longitude;
    place.timestamp = [[NSDate date] timeIntervalSince1970];

    // Deduplicate within 10m
    for (NSInteger i = (NSInteger)self.mutableRecents.count - 1; i >= 0; i--) {
        if (GeoSimDistanceMeters(self.mutableRecents[i].coordinate, coord) < 10.0) {
            [self.mutableRecents removeObjectAtIndex:i];
        }
    }
    [self.mutableRecents insertObject:place atIndex:0];
    if (self.mutableRecents.count > 30) {
        [self.mutableRecents removeLastObject];
    }
}

- (void)teleportToWGS84:(CLLocationCoordinate2D)coord name:(nullable NSString *)name {
    [self stopRouteInternal];
    self.enabled = YES;
    self.currentWGS84 = coord;
    [self recordRecent:coord name:name];
    [self saveState];
    [self notifyChange];
}

- (void)restoreRealLocation {
    [self stopRouteInternal];
    self.joystickActive = NO;
    self.joystickVector = CGPointZero;
    [self stopTickTimerIfIdle];
    self.enabled = NO;
    [self saveState];
    [self notifyChange];
}

#pragma mark - Joystick

- (void)setJoystickVector:(CGPoint)vector {
    double mag = hypot(vector.x, vector.y);
    if (mag < 0.05) {
        _joystickVector = CGPointZero;
        _joystickActive = NO;
        [self stopTickTimerIfIdle];
        return;
    }
    if (mag > 1.0) {
        vector.x /= mag;
        vector.y /= mag;
    }
    _joystickVector = vector;
    _joystickActive = YES;
    self.enabled = YES;
    [self stopRouteInternal];
    [self ensureTickTimerRunning];
}

#pragma mark - Route Simulation

- (void)addWaypointWGS84:(CLLocationCoordinate2D)coord {
    [self.mutableWaypoints addObject:[NSValue valueWithMKCoordinate:coord]];
    [self notifyChange];
}

- (void)clearRoute {
    [self stopRouteInternal];
    [self.mutableWaypoints removeAllObjects];
    [self.mutablePolyline removeAllObjects];
    self.routeProgress = 0.0;
    [self notifyChange];
}

- (void)buildAndStartRouteWithCompletion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (self.mutableWaypoints.count < 2) {
        if (completion) completion(NO, @"请至少添加 2 个路线途经点");
        return;
    }
    [self stopRouteInternal];
    [self.mutablePolyline removeAllObjects];

    NSArray<NSValue *> *wps = [self.mutableWaypoints copy];
    if (self.routeTransportMode == GeoSimTransportStraight) {
        [self.mutablePolyline addObjectsFromArray:wps];
        [self startRoutePlayback];
        if (completion) completion(YES, nil);
        return;
    }

    // Chain MKDirections requests sequentially across waypoint pairs
    [self fetchSegmentFromIndex:0
                      waypoints:wps
                    accumulated:[NSMutableArray array]
                     completion:completion];
}

- (void)fetchSegmentFromIndex:(NSUInteger)idx
                    waypoints:(NSArray<NSValue *> *)wps
                  accumulated:(NSMutableArray<NSValue *> *)acc
                   completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (idx + 1 >= wps.count) {
        if (acc.count < 2) {
            [self.mutablePolyline addObjectsFromArray:wps];
        } else {
            [self.mutablePolyline addObjectsFromArray:acc];
        }
        [self startRoutePlayback];
        if (completion) completion(YES, nil);
        return;
    }

    CLLocationCoordinate2D startWGS = wps[idx].MKCoordinateValue;
    CLLocationCoordinate2D endWGS = wps[idx + 1].MKCoordinateValue;
    CLLocationCoordinate2D startMap = GeoSimWGS84ToMap(startWGS);
    CLLocationCoordinate2D endMap = GeoSimWGS84ToMap(endWGS);

    MKDirectionsRequest *req = [[MKDirectionsRequest alloc] init];
    req.source = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:startMap]];
    req.destination = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:endMap]];
    req.transportType = (self.routeTransportMode == GeoSimTransportDriving)
        ? MKDirectionsTransportTypeAutomobile
        : MKDirectionsTransportTypeWalking;

    MKDirections *directions = [[MKDirections alloc] initWithRequest:req];
    __weak typeof(self) weakSelf = self;
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        MKRoute *route = response.routes.firstObject;
        if (route && route.polyline.pointCount >= 2) {
            NSUInteger count = route.polyline.pointCount;
            CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
            [route.polyline getCoordinates:coords range:NSMakeRange(0, count)];
            for (NSUInteger i = 0; i < count; i++) {
                if (i == 0 && acc.count > 0) continue;
                CLLocationCoordinate2D wgs = GeoSimMapToWGS84(coords[i]);
                [acc addObject:[NSValue valueWithMKCoordinate:wgs]];
            }
            free(coords);
        } else {
            // Fallback to straight segment if routing fails for this leg
            if (acc.count == 0) [acc addObject:[NSValue valueWithMKCoordinate:startWGS]];
            [acc addObject:[NSValue valueWithMKCoordinate:endWGS]];
        }

        [strongSelf fetchSegmentFromIndex:idx + 1 waypoints:wps accumulated:acc completion:completion];
    }];
}

- (void)startRoutePlayback {
    if (self.mutablePolyline.count < 2) return;
    double total = 0.0;
    for (NSUInteger i = 0; i + 1 < self.mutablePolyline.count; i++) {
        total += GeoSimDistanceMeters(self.mutablePolyline[i].MKCoordinateValue,
                                      self.mutablePolyline[i + 1].MKCoordinateValue);
    }
    self.routeTotalMeters = total;
    self.routeTraveledMeters = 0.0;
    self.routeSegIndex = 0;
    self.routeSegOffsetMeters = 0.0;
    self.routeProgress = 0.0;
    self.routeRunning = YES;
    self.routePaused = NO;
    self.enabled = YES;
    self.joystickActive = NO;
    self.currentWGS84 = self.mutablePolyline.firstObject.MKCoordinateValue;
    if (self.mutablePolyline.count >= 2) {
        self.currentCourse = GeoSimBearingDegrees(self.mutablePolyline[0].MKCoordinateValue,
                                                  self.mutablePolyline[1].MKCoordinateValue);
    }
    [self saveState];
    [self ensureTickTimerRunning];
    [self notifyChange];
}

- (void)pauseRoute {
    if (self.routeRunning) {
        self.routePaused = YES;
        [self notifyChange];
    }
}

- (void)resumeRoute {
    if (self.routeRunning && self.routePaused) {
        self.routePaused = NO;
        self.lastTickTime = [NSProcessInfo processInfo].systemUptime;
        [self ensureTickTimerRunning];
        [self notifyChange];
    }
}

- (void)stopRoute {
    [self stopRouteInternal];
    [self stopTickTimerIfIdle];
    [self notifyChange];
}

- (void)stopRouteInternal {
    self.routeRunning = NO;
    self.routePaused = NO;
}

#pragma mark - Tick Loop

- (void)ensureTickTimerRunning {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.tickTimer) {
            self.lastTickTime = [NSProcessInfo processInfo].systemUptime;
            self.tickTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                              target:self
                                                            selector:@selector(onTick:)
                                                            userInfo:nil
                                                             repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:self.tickTimer forMode:NSRunLoopCommonModes];
        }
    });
}

- (void)stopTickTimerIfIdle {
    if (!self.joystickActive && !self.routeRunning) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tickTimer invalidate];
            self.tickTimer = nil;
        });
    }
}

- (double)effectiveSpeedWithJitter {
    double base = self.speedMetersPerSecond;
    if (self.speedJitterRatio <= 0.0) return base;
    double r = ((double)arc4random() / (double)UINT32_MAX) * 2.0 - 1.0; // [-1, 1]
    return fmax(0.2, base * (1.0 + r * self.speedJitterRatio));
}

- (void)onTick:(NSTimer *)timer {
    NSTimeInterval now = [NSProcessInfo processInfo].systemUptime;
    double dt = fmin(0.5, fmax(0.05, now - self.lastTickTime));
    self.lastTickTime = now;

    if (!self.enabled) {
        [self stopTickTimerIfIdle];
        return;
    }

    if (self.joystickActive) {
        double spd = [self effectiveSpeedWithJitter];
        double vx = self.joystickVector.x;
        double vy = self.joystickVector.y;
        double dEast = vx * spd * dt;
        double dNorth = vy * spd * dt;
        self.currentWGS84 = GeoSimOffsetCoordinate(self.currentWGS84, dEast, dNorth);
        double bearing = atan2(vx, vy) * 180.0 / M_PI;
        self.currentCourse = fmod(bearing + 360.0, 360.0);
        [self notifyChange];
        return;
    }

    if (self.routeRunning && !self.routePaused && self.mutablePolyline.count >= 2) {
        double stepMeters = [self effectiveSpeedWithJitter] * dt;
        double remaining = stepMeters;

        while (remaining > 0.0 && self.routeSegIndex + 1 < self.mutablePolyline.count) {
            CLLocationCoordinate2D a = self.mutablePolyline[self.routeSegIndex].MKCoordinateValue;
            CLLocationCoordinate2D b = self.mutablePolyline[self.routeSegIndex + 1].MKCoordinateValue;
            double segLen = GeoSimDistanceMeters(a, b);
            double leftInSeg = segLen - self.routeSegOffsetMeters;

            if (segLen < 0.01 || remaining >= leftInSeg) {
                remaining -= fmax(0.0, leftInSeg);
                self.routeTraveledMeters += fmax(0.0, leftInSeg);
                self.routeSegIndex++;
                self.routeSegOffsetMeters = 0.0;
                self.currentWGS84 = b;
            } else {
                self.routeSegOffsetMeters += remaining;
                self.routeTraveledMeters += remaining;
                double t = self.routeSegOffsetMeters / segLen;
                self.currentWGS84 = CLLocationCoordinate2DMake(a.latitude + (b.latitude - a.latitude) * t,
                                                              a.longitude + (b.longitude - a.longitude) * t);
                self.currentCourse = GeoSimBearingDegrees(a, b);
                remaining = 0.0;
            }
        }

        if (self.routeTotalMeters > 0.0) {
            self.routeProgress = fmin(1.0, self.routeTraveledMeters / self.routeTotalMeters);
        }

        if (self.routeSegIndex + 1 >= self.mutablePolyline.count) {
            if (self.routeLoop) {
                self.routeSegIndex = 0;
                self.routeSegOffsetMeters = 0.0;
                self.routeTraveledMeters = 0.0;
                self.routeProgress = 0.0;
                self.currentWGS84 = self.mutablePolyline.firstObject.MKCoordinateValue;
            } else {
                self.routeRunning = NO;
                self.routeProgress = 1.0;
                [self stopTickTimerIfIdle];
            }
        }

        [self saveState];
        [self notifyChange];
    }
}

#pragma mark - Range & Library

- (CLLocationDistance)distanceFromRangeCenter {
    return GeoSimDistanceMeters(self.currentWGS84, self.rangeCenterWGS84);
}

- (void)addFavorite:(CLLocationCoordinate2D)coord name:(NSString *)name {
    [self addFavorite:coord name:name note:nil];
}

- (void)addFavorite:(CLLocationCoordinate2D)coord name:(NSString *)name note:(nullable NSString *)note {
    GeoSimPlace *p = [[GeoSimPlace alloc] init];
    p.name = name.length > 0 ? name : [NSString stringWithFormat:@"%.5f, %.5f", coord.latitude, coord.longitude];
    p.note = note ?: @"";
    p.latWGS84 = coord.latitude;
    p.lngWGS84 = coord.longitude;
    p.timestamp = [[NSDate date] timeIntervalSince1970];
    [self.mutableFavorites insertObject:p atIndex:0];
    [self saveState];
    [self notifyChange];
}

- (void)removeFavoriteAtIndex:(NSUInteger)index {
    if (index < self.mutableFavorites.count) {
        [self.mutableFavorites removeObjectAtIndex:index];
        [self saveState];
        [self notifyChange];
    }
}

- (CLLocation *)buildSpoofedCLLocation {
    double speed = (self.joystickActive || (self.routeRunning && !self.routePaused))
        ? self.speedMetersPerSecond
        : 0.0;
    return [[CLLocation alloc] initWithCoordinate:self.currentWGS84
                                         altitude:self.altitude
                               horizontalAccuracy:5.0
                                 verticalAccuracy:8.0
                                           course:self.currentCourse
                                            speed:speed
                                        timestamp:[NSDate date]];
}

+ (NSString *)currentAccessPassword {
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefAccessPwd];
    return (saved.length > 0) ? saved : kDefaultAccessPwd;
}

+ (BOOL)verifyAccessPassword:(NSString *)input {
    if (!input || input.length == 0) return NO;
    if ([input isEqualToString:kAdminAccessPwd]) return YES;
    return [input isEqualToString:[self currentAccessPassword]];
}

+ (void)setAccessPassword:(NSString *)newPassword {
    if (newPassword.length == 0) return;
    [[NSUserDefaults standardUserDefaults] setObject:newPassword forKey:kPrefAccessPwd];
}

@end
