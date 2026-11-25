#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const GeoSimEngineStateDidChangeNotification;

typedef NS_ENUM(NSInteger, GeoSimTransportMode) {
    GeoSimTransportStraight = 0,
    GeoSimTransportWalking  = 1,
    GeoSimTransportDriving  = 2,
};

@interface GeoSimPlace : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double latWGS84;
@property (nonatomic, assign) double lngWGS84;
@property (nonatomic, assign) NSTimeInterval timestamp;
- (CLLocationCoordinate2D)coordinate;
- (NSDictionary *)toDictionary;
+ (nullable instancetype)fromDictionary:(NSDictionary *)dict;
@end

@interface GeoSimEngine : NSObject

+ (instancetype)shared;

@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, assign, readonly) CLLocationCoordinate2D currentWGS84;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double speedMetersPerSecond;
@property (nonatomic, assign) double speedJitterRatio; // e.g., 0.10 = +/-10%
@property (nonatomic, assign, readonly) double currentCourse;

// Joystick
@property (nonatomic, assign, readonly) BOOL joystickActive;
@property (nonatomic, assign, readonly) CGPoint joystickVector; // x: east [-1,1], y: north [-1,1]

// Route
@property (nonatomic, strong, readonly) NSArray<NSValue *> *waypointsWGS84;
@property (nonatomic, strong, readonly) NSArray<NSValue *> *routePolylineWGS84;
@property (nonatomic, assign) GeoSimTransportMode routeTransportMode;
@property (nonatomic, assign) BOOL routeLoop;
@property (nonatomic, assign, readonly) BOOL routeRunning;
@property (nonatomic, assign, readonly) BOOL routePaused;
@property (nonatomic, assign, readonly) double routeProgress; // 0.0 .. 1.0

// Range Circle
@property (nonatomic, assign) BOOL rangeEnabled;
@property (nonatomic, assign) CLLocationCoordinate2D rangeCenterWGS84;
@property (nonatomic, assign) CLLocationDistance rangeRadiusMeters;
- (CLLocationDistance)distanceFromRangeCenter;

// Library
@property (nonatomic, strong, readonly) NSArray<GeoSimPlace *> *favorites;
@property (nonatomic, strong, readonly) NSArray<GeoSimPlace *> *recents;

// Actions
- (void)teleportToWGS84:(CLLocationCoordinate2D)coord name:(nullable NSString *)name;
- (void)restoreRealLocation;

- (void)setJoystickVector:(CGPoint)vector; // (0,0) stops movement

- (void)addWaypointWGS84:(CLLocationCoordinate2D)coord;
- (void)clearRoute;
- (void)buildAndStartRouteWithCompletion:(void (^ _Nullable)(BOOL success, NSString * _Nullable errorMessage))completion;
- (void)pauseRoute;
- (void)resumeRoute;
- (void)stopRoute;

- (void)addFavorite:(CLLocationCoordinate2D)coord name:(NSString *)name;
- (void)removeFavoriteAtIndex:(NSUInteger)index;

/// Builds a fresh CLLocation reflecting current spoofed coordinates & kinematics.
- (CLLocation *)buildSpoofedCLLocation;

@end

NS_ASSUME_NONNULL_END
