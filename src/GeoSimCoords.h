#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GeoSimCRS) {
    GeoSimCRSWGS84 = 0, // GPS / CoreLocation
    GeoSimCRSGCJ02 = 1, // AMap / Tencent / Apple Maps CN
    GeoSimCRSBD09  = 2, // Baidu Maps
};

FOUNDATION_EXPORT BOOL GeoSimOutOfChina(double lat, double lng);
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimWGS84ToGCJ02(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimGCJ02ToWGS84(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimGCJ02ToBD09(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimBD09ToGCJ02(CLLocationCoordinate2D coord);
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimToWGS84(CLLocationCoordinate2D coord, GeoSimCRS crs);
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimFromWGS84(CLLocationCoordinate2D coord, GeoSimCRS crs);

/// Convert map-display coordinate (GCJ-02 inside China, WGS-84 outside) to WGS-84.
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimMapToWGS84(CLLocationCoordinate2D mapCoord);
/// Convert WGS-84 to map-display coordinate (GCJ-02 inside China, WGS-84 outside).
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimWGS84ToMap(CLLocationCoordinate2D wgsCoord);

/// Parses "lat, lng", swapped "lng, lat", or DMS strings. Returns YES on success.
FOUNDATION_EXPORT BOOL GeoSimParseCoordinateString(NSString *input, CLLocationCoordinate2D *outCoord);

/// Great-circle distance in meters (Haversine).
FOUNDATION_EXPORT CLLocationDistance GeoSimDistanceMeters(CLLocationCoordinate2D a, CLLocationCoordinate2D b);

/// Bearing in degrees [0, 360) from a to b.
FOUNDATION_EXPORT double GeoSimBearingDegrees(CLLocationCoordinate2D a, CLLocationCoordinate2D b);

/// Offset a coordinate by deltaEastMeters and deltaNorthMeters.
FOUNDATION_EXPORT CLLocationCoordinate2D GeoSimOffsetCoordinate(CLLocationCoordinate2D origin,
                                                                 double deltaEastMeters,
                                                                 double deltaNorthMeters);

NS_ASSUME_NONNULL_END
