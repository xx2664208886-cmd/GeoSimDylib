#import "GeoSimOverlay.h"
#import "GeoSimEngine.h"
#import "GeoSimViewController.h"

@interface GeoSimJoystickHUD : UIView
@property (nonatomic, copy) void (^onClose)(void);
- (void)refreshSpeedTitle;
@end

@interface GeoSimJoystickHUD ()
@property (nonatomic, strong) UIView *padView;
@property (nonatomic, strong) UIView *knobView;
@property (nonatomic, strong) UIButton *speedButton;
@property (nonatomic, assign) BOOL draggingKnob;
@end

@implementation GeoSimJoystickHUD

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(24, 220, 140, 176)];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        self.layer.cornerRadius = 18.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18].CGColor;
        self.clipsToBounds = YES;

        // Top bar (drag handle + speed + close)
        UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 34)];
        topBar.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
        [self addSubview:topBar];

        UIPanGestureRecognizer *dragHUD = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragHUD:)];
        [topBar addGestureRecognizer:dragHUD];

        _speedButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _speedButton.frame = CGRectMake(8, 3, 92, 28);
        _speedButton.titleLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightSemibold];
        [_speedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _speedButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_speedButton addTarget:self action:@selector(cycleSpeed) forControlEvents:UIControlEventTouchUpInside];
        [topBar addSubview:_speedButton];
        [self refreshSpeedTitle];

        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(108, 3, 28, 28);
        [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
        [topBar addSubview:closeBtn];

        // Pad
        CGFloat padSize = 112.0;
        _padView = [[UIView alloc] initWithFrame:CGRectMake((140.0 - padSize) / 2.0, 44.0, padSize, padSize)];
        _padView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
        _padView.layer.cornerRadius = padSize / 2.0;
        _padView.layer.borderWidth = 1.5;
        _padView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.25].CGColor;
        [self addSubview:_padView];

        // Crosshair lines inside pad
        UIView *hLine = [[UIView alloc] initWithFrame:CGRectMake(12, padSize / 2.0 - 0.5, padSize - 24, 1)];
        hLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        hLine.userInteractionEnabled = NO;
        [_padView addSubview:hLine];

        UIView *vLine = [[UIView alloc] initWithFrame:CGRectMake(padSize / 2.0 - 0.5, 12, 1, padSize - 24)];
        vLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        vLine.userInteractionEnabled = NO;
        [_padView addSubview:vLine];

        // Knob
        CGFloat knobSize = 44.0;
        _knobView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, knobSize, knobSize)];
        _knobView.center = CGPointMake(padSize / 2.0, padSize / 2.0);
        _knobView.backgroundColor = [UIColor systemBlueColor];
        _knobView.layer.cornerRadius = knobSize / 2.0;
        _knobView.layer.shadowColor = [UIColor blackColor].CGColor;
        _knobView.layer.shadowOpacity = 0.35;
        _knobView.layer.shadowRadius = 4.0;
        _knobView.userInteractionEnabled = NO;
        [_padView addSubview:_knobView];
    }
    return self;
}

- (void)refreshSpeedTitle {
    double spd = [GeoSimEngine shared].speedMetersPerSecond;
    NSString *tag = (spd <= 2.2) ? @"步" : (spd <= 7.0 ? @"骑" : @"车");
    [self.speedButton setTitle:[NSString stringWithFormat:@"%@ %.1fm/s", tag, spd] forState:UIControlStateNormal];
}

- (void)cycleSpeed {
    GeoSimEngine *eng = [GeoSimEngine shared];
    double s = eng.speedMetersPerSecond;
    if (s < 2.5) eng.speedMetersPerSecond = 5.0;
    else if (s < 8.0) eng.speedMetersPerSecond = 15.0;
    else eng.speedMetersPerSecond = 1.5;
    [self refreshSpeedTitle];
}

- (void)closeTapped {
    [[GeoSimEngine shared] setJoystickVector:CGPointZero];
    if (self.onClose) self.onClose();
}

- (void)handleDragHUD:(UIPanGestureRecognizer *)gr {
    UIView *superview = self.superview;
    if (!superview) return;
    CGPoint delta = [gr translationInView:superview];
    CGPoint c = self.center;
    c.x = fmax(self.bounds.size.width / 2.0, fmin(superview.bounds.size.width - self.bounds.size.width / 2.0, c.x + delta.x));
    c.y = fmax(self.bounds.size.height / 2.0 + 30.0, fmin(superview.bounds.size.height - self.bounds.size.height / 2.0, c.y + delta.y));
    self.center = c;
    [gr setTranslation:CGPointZero inView:superview];
}

- (void)updateKnobForTouch:(UITouch *)touch {
    CGPoint pt = [touch locationInView:self.padView];
    CGFloat radius = self.padView.bounds.size.width / 2.0;
    CGFloat maxOffset = radius - 22.0;
    CGFloat dx = pt.x - radius;
    CGFloat dy = pt.y - radius;
    CGFloat dist = hypot(dx, dy);
    if (dist > maxOffset && dist > 0.001) {
        dx = dx * (maxOffset / dist);
        dy = dy * (maxOffset / dist);
    }
    self.knobView.center = CGPointMake(radius + dx, radius + dy);
    // UIKit y grows downward, whereas North (+y) is upward
    CGPoint vec = CGPointMake(dx / maxOffset, -dy / maxOffset);
    [[GeoSimEngine shared] setJoystickVector:vec];
}

- (void)resetKnob {
    CGFloat radius = self.padView.bounds.size.width / 2.0;
    [UIView animateWithDuration:0.15 animations:^{
        self.knobView.center = CGPointMake(radius, radius);
    }];
    [[GeoSimEngine shared] setJoystickVector:CGPointZero];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    if (!t) return;
    CGPoint pt = [t locationInView:self.padView];
    if (CGRectContainsPoint(CGRectInset(self.padView.bounds, -10, -10), pt)) {
        self.draggingKnob = YES;
        [self updateKnobForTouch:t];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.draggingKnob) return;
    UITouch *t = touches.anyObject;
    if (t) [self updateKnobForTouch:t];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.draggingKnob) {
        self.draggingKnob = NO;
        [self resetKnob];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.draggingKnob) {
        self.draggingKnob = NO;
        [self resetKnob];
    }
}

@end

#pragma mark - GeoSimOverlay

@interface GeoSimOverlay ()
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) GeoSimJoystickHUD *joystickHUD;
@property (nonatomic, weak) UIWindow *attachedWindow;
@property (nonatomic, assign) BOOL buttonHidden;
@end

@implementation GeoSimOverlay

+ (instancetype)shared {
    static GeoSimOverlay *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[GeoSimOverlay alloc] init];
    });
    return inst;
}

+ (void)install {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[GeoSimOverlay shared] ensureAttached];
        });
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:GeoSimEngineStateDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[GeoSimOverlay shared] refreshButtonAppearance];
    }];
}

+ (void)setFloatingButtonHidden:(BOOL)hidden {
    GeoSimOverlay *ov = [GeoSimOverlay shared];
    ov.buttonHidden = hidden;
    ov.floatingButton.hidden = hidden;
}

+ (void)setJoystickHUDVisible:(BOOL)visible {
    GeoSimOverlay *ov = [GeoSimOverlay shared];
    [ov ensureAttached];
    ov.joystickHUD.hidden = !visible;
    if (visible) {
        [ov.joystickHUD refreshSpeedTitle];
        [ov.attachedWindow bringSubviewToFront:ov.joystickHUD];
    } else {
        [[GeoSimEngine shared] setJoystickVector:CGPointZero];
    }
}

+ (BOOL)isJoystickHUDVisible {
    GeoSimOverlay *ov = [GeoSimOverlay shared];
    return ov.joystickHUD && !ov.joystickHUD.hidden;
}

- (nullable UIWindow *)findKeyWindow {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (ws.activationState == UISceneActivationStateForegroundActive ||
            ws.activationState == UISceneActivationStateForegroundInactive) {
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow && !w.hidden) return w;
            }
            if (ws.windows.firstObject) return ws.windows.firstObject;
        }
    }
    return nil;
}

- (void)ensureAttached {
    UIWindow *win = [self findKeyWindow];
    if (!win) return;

    if (!self.floatingButton) {
        CGFloat w = 88.0, h = 34.0;
        CGFloat x = win.bounds.size.width - w - 14.0;
        CGFloat y = 110.0;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, y, w, h);
        btn.layer.cornerRadius = h / 2.0;
        btn.layer.shadowColor = [UIColor blackColor].CGColor;
        btn.layer.shadowOpacity = 0.3;
        btn.layer.shadowOffset = CGSizeMake(0, 2);
        btn.layer.shadowRadius = 4.0;
        btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(openControlPanel) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
        [btn addGestureRecognizer:pan];

        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonLongPress:)];
        lp.minimumPressDuration = 0.45;
        [btn addGestureRecognizer:lp];

        self.floatingButton = btn;
        [self refreshButtonAppearance];
    }

    if (!self.joystickHUD) {
        self.joystickHUD = [[GeoSimJoystickHUD alloc] initWithFrame:CGRectZero];
        self.joystickHUD.hidden = YES;
        __weak typeof(self) weakSelf = self;
        self.joystickHUD.onClose = ^{
            weakSelf.joystickHUD.hidden = YES;
        };
    }

    if (self.attachedWindow != win) {
        self.attachedWindow = win;
        [win addSubview:self.floatingButton];
        [win addSubview:self.joystickHUD];

        // 3-finger double-tap toggles floating button visibility
        UITapGestureRecognizer *threeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThreeFingerDoubleTap)];
        threeTap.numberOfTouchesRequired = 3;
        threeTap.numberOfTapsRequired = 2;
        threeTap.cancelsTouchesInView = NO;
        [win addGestureRecognizer:threeTap];
    }

    self.floatingButton.hidden = self.buttonHidden;
    [win bringSubviewToFront:self.floatingButton];
    if (!self.joystickHUD.hidden) {
        [win bringSubviewToFront:self.joystickHUD];
    }
}

- (void)refreshButtonAppearance {
    BOOL on = [GeoSimEngine shared].enabled;
    self.floatingButton.backgroundColor = on
        ? [[UIColor systemGreenColor] colorWithAlphaComponent:0.9]
        : [[UIColor darkGrayColor] colorWithAlphaComponent:0.85];
    [self.floatingButton setTitle:(on ? @"📍 模拟中" : @"📍 GeoSim") forState:UIControlStateNormal];
}

- (void)handleThreeFingerDoubleTap {
    self.buttonHidden = !self.buttonHidden;
    self.floatingButton.hidden = self.buttonHidden;
    if (!self.buttonHidden) {
        [self.attachedWindow bringSubviewToFront:self.floatingButton];
    }
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)gr {
    UIView *win = self.attachedWindow;
    if (!win) return;
    CGPoint delta = [gr translationInView:win];
    CGPoint c = self.floatingButton.center;
    c.x = fmax(self.floatingButton.bounds.size.width / 2.0, fmin(win.bounds.size.width - self.floatingButton.bounds.size.width / 2.0, c.x + delta.x));
    c.y = fmax(50.0, fmin(win.bounds.size.height - 40.0, c.y + delta.y));
    self.floatingButton.center = c;
    [gr setTranslation:CGPointZero inView:win];
}

- (void)handleButtonLongPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        [GeoSimOverlay setJoystickHUDVisible:self.joystickHUD.hidden];
    }
}

- (void)openControlPanel {
    UIWindow *win = [self findKeyWindow];
    UIViewController *topVC = win.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    if (!topVC || [topVC isKindOfClass:[GeoSimViewController class]]) return;

    GeoSimViewController *panel = [[GeoSimViewController alloc] init];
    panel.modalPresentationStyle = UIModalPresentationPageSheet;
    [topVC presentViewController:panel animated:YES completion:nil];
}

@end
