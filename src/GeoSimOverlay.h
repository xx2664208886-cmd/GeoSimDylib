#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeoSimOverlay : NSObject

+ (void)install;
+ (void)setFloatingButtonHidden:(BOOL)hidden;
+ (void)setJoystickHUDVisible:(BOOL)visible;
+ (BOOL)isJoystickHUDVisible;

@end

NS_ASSUME_NONNULL_END
