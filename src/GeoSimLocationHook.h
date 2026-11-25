#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeoSimLocationHook : NSObject

+ (void)install;

/// Returns the most recent genuine device location observed before spoofing replacement, if any.
+ (nullable CLLocation *)lastObservedRealLocation;

@end

NS_ASSUME_NONNULL_END
