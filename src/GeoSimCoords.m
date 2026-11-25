#import "GeoSimCoords.h"
#import <math.h>

static const double kGeoA = 6378245.0;
static const double kGeoEE = 0.00669342162296594323;
static const double kGeoXPi = M_PI * 3000.0 / 180.0;
static const int kGeoReverseIterations = 6;
static const double kEarthRadiusMeters = 6371000.0;

BOOL GeoSimOutOfChina(double lat, double lng) {
    return !(lng > 73.66 && lng < 135.05 && lat > 3.86 && lat < 53.55);
}

static double geoTransformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320.0 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

static double geoTransformLng(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}

static void geoGCJOffset(double lat, double lng, double *outDLat, double *outDLng) {
    double dLat = geoTransformLat(lng - 105.0, lat - 35.0);
    double dLng = geoTransformLng(lng - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1.0 - kGeoEE * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((kGeoA * (1.0 - kGeoEE)) / (magic * sqrtMagic) * M_PI);
    dLng = (dLng * 180.0) / (kGeoA / sqrtMagic * cos(radLat) * M_PI);
    *outDLat = dLat;
    *outDLng = dLng;
}

CLLocationCoordinate2D GeoSimWGS84ToGCJ02(CLLocationCoordinate2D coord) {
    if (GeoSimOutOfChina(coord.latitude, coord.longitude)) {
        return coord;
    }
    double dLat = 0.0, dLng = 0.0;
    geoGCJOffset(coord.latitude, coord.longitude, &dLat, &dLng);
    return CLLocationCoordinate2DMake(coord.latitude + dLat, coord.longitude + dLng);
}

CLLocationCoordinate2D GeoSimGCJ02ToWGS84(CLLocationCoordinate2D coord) {
    if (GeoSimOutOfChina(coord.latitude, coord.longitude)) {
        return coord;
    }
    CLLocationCoordinate2D guess = coord;
    for (int i = 0; i < kGeoReverseIterations; i++) {
        CLLocationCoordinate2D fwd = GeoSimWGS84ToGCJ02(guess);
        guess.latitude += (coord.latitude - fwd.latitude);
        guess.longitude += (coord.longitude - fwd.longitude);
    }
    return guess;
}

CLLocationCoordinate2D GeoSimGCJ02ToBD09(CLLocationCoordinate2D coord) {
    double x = coord.longitude;
    double y = coord.latitude;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * kGeoXPi);
    double theta = atan2(y, x) + 0.000003 * cos(x * kGeoXPi);
    return CLLocationCoordinate2DMake(z * sin(theta) + 0.006, z * cos(theta) + 0.0065);
}

CLLocationCoordinate2D GeoSimBD09ToGCJ02(CLLocationCoordinate2D coord) {
    double x = coord.longitude - 0.0065;
    double y = coord.latitude - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * kGeoXPi);
    double theta = atan2(y, x) - 0.000003 * cos(x * kGeoXPi);
    return CLLocationCoordinate2DMake(z * sin(theta), z * cos(theta));
}

CLLocationCoordinate2D GeoSimToWGS84(CLLocationCoordinate2D coord, GeoSimCRS crs) {
    switch (crs) {
        case GeoSimCRSWGS84: return coord;
        case GeoSimCRSGCJ02: return GeoSimGCJ02ToWGS84(coord);
        case GeoSimCRSBD09:  return GeoSimGCJ02ToWGS84(GeoSimBD09ToGCJ02(coord));
    }
}

CLLocationCoordinate2D GeoSimFromWGS84(CLLocationCoordinate2D coord, GeoSimCRS crs) {
    switch (crs) {
        case GeoSimCRSWGS84: return coord;
        case GeoSimCRSGCJ02: return GeoSimWGS84ToGCJ02(coord);
        case GeoSimCRSBD09:  return GeoSimGCJ02ToBD09(GeoSimWGS84ToGCJ02(coord));
    }
}

CLLocationCoordinate2D GeoSimMapToWGS84(CLLocationCoordinate2D mapCoord) {
    return GeoSimGCJ02ToWGS84(mapCoord);
}

CLLocationCoordinate2D GeoSimWGS84ToMap(CLLocationCoordinate2D wgsCoord) {
    return GeoSimWGS84ToGCJ02(wgsCoord);
}

static BOOL geoParseSingleValue(NSString *part, double *outVal) {
    NSString *trimmed = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return NO;

    // Check plain decimal first
    NSScanner *plainScanner = [NSScanner scannerWithString:trimmed];
    double plainVal = 0.0;
    if ([plainScanner scanDouble:&plainVal] && plainScanner.isAtEnd) {
        *outVal = plainVal;
        return YES;
    }

    // Check DMS format e.g. 39°54'15.2"N
    NSRegularExpression *dmsRegex = [NSRegularExpression regularExpressionWithPattern:@"([+-]?\\d+(?:\\.\\d+)?)\\s*[°d]\\s*(\\d+(?:\\.\\d+)?)?\\s*[′'m]?\\s*(\\d+(?:\\.\\d+)?)?\\s*[″\"s]?\\s*([NSEWnsew])?"
                                                                              options:0
                                                                                error:nil];
    NSTextCheckingResult *m = [dmsRegex firstMatchInString:trimmed options:0 range:NSMakeRange(0, trimmed.length)];
    if (!m || m.range.location != 0 || m.range.length != trimmed.length) {
        return NO;
    }
    double deg = [[trimmed substringWithRange:[m rangeAtIndex:1]] doubleValue];
    double min = ([m rangeAtIndex:2].location != NSNotFound) ? [[trimmed substringWithRange:[m rangeAtIndex:2]] doubleValue] : 0.0;
    double sec = ([m rangeAtIndex:3].location != NSNotFound) ? [[trimmed substringWithRange:[m rangeAtIndex:3]] doubleValue] : 0.0;
    double sign = (deg < 0) ? -1.0 : 1.0;
    double val = fabs(deg) + min / 60.0 + sec / 3600.0;
    val *= sign;
    if ([m rangeAtIndex:4].location != NSNotFound) {
        NSString *hemi = [[trimmed substringWithRange:[m rangeAtIndex:4]] uppercaseString];
        if ([hemi isEqualToString:@"S"] || [hemi isEqualToString:@"W"]) {
            val = -fabs(val);
        } else {
            val = fabs(val);
        }
    }
    *outVal = val;
    return YES;
}

BOOL GeoSimParseCoordinateString(NSString *input, CLLocationCoordinate2D *outCoord) {
    if (!input || input.length == 0 || !outCoord) return NO;
    NSString *cleaned = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@"，" withString:@","];
    cleaned = [cleaned stringByReplacingOccurrencesOfString:@";" withString:@","];

    NSArray<NSString *> *parts = [cleaned componentsSeparatedByString:@","];
    if (parts.count != 2) {
        // Fallback: split on whitespace if no comma
        NSArray<NSString *> *wsParts = [cleaned componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSMutableArray<NSString *> *nonEmpty = [NSMutableArray array];
        for (NSString *p in wsParts) {
            if (p.length > 0) [nonEmpty addObject:p];
        }
        if (nonEmpty.count != 2) return NO;
        parts = nonEmpty;
    }

    double v1 = 0.0, v2 = 0.0;
    if (!geoParseSingleValue(parts[0], &v1) || !geoParseSingleValue(parts[1], &v2)) {
        return NO;
    }

    double lat = v1, lng = v2;
    // Auto-swap if first looks like longitude (> 90) and second looks like latitude (<= 90),
    // or if first is in [70, 140] and second is in [0, 60] (common Chinese map picker lng,lat order).
    if ((fabs(v1) > 90.0 && fabs(v2) <= 90.0) ||
        (v1 >= 70.0 && v1 <= 140.0 && v2 >= 0.0 && v2 <= 60.0)) {
        lat = v2;
        lng = v1;
    }

    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
        return NO;
    }
    *outCoord = CLLocationCoordinate2DMake(lat, lng);
    return YES;
}

CLLocationDistance GeoSimDistanceMeters(CLLocationCoordinate2D a, CLLocationCoordinate2D b) {
    double lat1 = a.latitude * M_PI / 180.0;
    double lat2 = b.latitude * M_PI / 180.0;
    double dLat = (b.latitude - a.latitude) * M_PI / 180.0;
    double dLng = (b.longitude - a.longitude) * M_PI / 180.0;
    double h = sin(dLat / 2.0) * sin(dLat / 2.0) +
               cos(lat1) * cos(lat2) * sin(dLng / 2.0) * sin(dLng / 2.0);
    double c = 2.0 * atan2(sqrt(h), sqrt(1.0 - h));
    return kEarthRadiusMeters * c;
}

double GeoSimBearingDegrees(CLLocationCoordinate2D a, CLLocationCoordinate2D b) {
    double lat1 = a.latitude * M_PI / 180.0;
    double lat2 = b.latitude * M_PI / 180.0;
    double dLng = (b.longitude - a.longitude) * M_PI / 180.0;
    double y = sin(dLng) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    double brng = atan2(y, x) * 180.0 / M_PI;
    return fmod(brng + 360.0, 360.0);
}

CLLocationCoordinate2D GeoSimOffsetCoordinate(CLLocationCoordinate2D origin,
                                              double deltaEastMeters,
                                              double deltaNorthMeters) {
    double dLat = (deltaNorthMeters / kEarthRadiusMeters) * (180.0 / M_PI);
    double cosLat = cos(origin.latitude * M_PI / 180.0);
    if (fabs(cosLat) < 1e-6) cosLat = 1e-6;
    double dLng = (deltaEastMeters / (kEarthRadiusMeters * cosLat)) * (180.0 / M_PI);
    double newLat = fmax(-89.999, fmin(89.999, origin.latitude + dLat));
    double newLng = origin.longitude + dLng;
    if (newLng > 180.0) newLng -= 360.0;
    if (newLng < -180.0) newLng += 360.0;
    return CLLocationCoordinate2DMake(newLat, newLng);
}
