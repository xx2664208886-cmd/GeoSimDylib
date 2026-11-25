#import "GeoSimViewController.h"
#import "GeoSimEngine.h"
#import "GeoSimCoords.h"
#import "GeoSimOverlay.h"
#import "GeoSimLocationHook.h"
#import <MapKit/MapKit.h>

@interface GeoSimPinAnnotation : MKPointAnnotation
@property (nonatomic, assign) BOOL isWaypoint;
@end

@implementation GeoSimPinAnnotation
@end

@interface GeoSimViewController () <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UISwitch *enableSwitch;
@property (nonatomic, strong) UILabel *coordLabel;
@property (nonatomic, strong) UILabel *rangeStatusLabel;

@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UISegmentedControl *crsSegment;

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILabel *crosshairLabel;
@property (nonatomic, strong) UILabel *centerCoordLabel;

@property (nonatomic, strong) UISegmentedControl *tabSegment;
@property (nonatomic, strong) UIView *tabTeleportView;
@property (nonatomic, strong) UIView *tabRouteView;
@property (nonatomic, strong) UIView *tabRangeView;
@property (nonatomic, strong) UITableView *libraryTableView;

// Teleport / Speed controls
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedValueLabel;
@property (nonatomic, strong) UIButton *joystickToggleBtn;

// Route controls
@property (nonatomic, strong) UISegmentedControl *transportSegment;
@property (nonatomic, strong) UISwitch *loopSwitch;
@property (nonatomic, strong) UILabel *routeInfoLabel;
@property (nonatomic, strong) UIProgressView *routeProgressView;
@property (nonatomic, strong) UIButton *routePlayBtn;

// Range controls
@property (nonatomic, strong) UISwitch *rangeSwitch;
@property (nonatomic, strong) UISlider *rangeRadiusSlider;
@property (nonatomic, strong) UILabel *rangeRadiusLabel;
@property (nonatomic, strong) UISwitch *jitterSwitch;
@end

@implementation GeoSimViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self buildUI];
    [self centerMapOnWGS84:[GeoSimEngine shared].currentWGS84 animated:NO];
    [self refreshAllUI];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onEngineChanged)
                                                 name:GeoSimEngineStateDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI Construction

- (void)buildUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // 1. Header Bar
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    titleLbl.text = @"GeoSim 虚拟定位";
    titleLbl.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [header addSubview:titleLbl];

    UIButton *hideFloatBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    hideFloatBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [hideFloatBtn setTitle:@"隐藏球" forState:UIControlStateNormal];
    hideFloatBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [hideFloatBtn addTarget:self action:@selector(hideFloatTapped) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:hideFloatBtn];

    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    doneBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    doneBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [doneBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:doneBtn];

    // 2. Status Card
    UIView *statusBar = [[UIView alloc] init];
    statusBar.translatesAutoresizingMaskIntoConstraints = NO;
    statusBar.backgroundColor = [UIColor secondarySystemBackgroundColor];
    statusBar.layer.cornerRadius = 10;
    [self.view addSubview:statusBar];

    self.enableSwitch = [[UISwitch alloc] init];
    self.enableSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [self.enableSwitch addTarget:self action:@selector(enableSwitchChanged) forControlEvents:UIControlEventValueChanged];
    [statusBar addSubview:self.enableSwitch];

    self.coordLabel = [[UILabel alloc] init];
    self.coordLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.coordLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
    self.coordLabel.numberOfLines = 2;
    self.coordLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *copyTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyCurrentCoords)];
    [self.coordLabel addGestureRecognizer:copyTap];
    [statusBar addSubview:self.coordLabel];

    self.rangeStatusLabel = [[UILabel alloc] init];
    self.rangeStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.rangeStatusLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    self.rangeStatusLabel.textAlignment = NSTextAlignmentRight;
    [statusBar addSubview:self.rangeStatusLabel];

    UIButton *restoreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    restoreBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [restoreBtn setTitle:@"恢复真实" forState:UIControlStateNormal];
    [restoreBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    restoreBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [restoreBtn addTarget:self action:@selector(restoreRealTapped) forControlEvents:UIControlEventTouchUpInside];
    [statusBar addSubview:restoreBtn];

    // 3. Search / Coordinate Jump Row
    UIView *searchRow = [[UIView alloc] init];
    searchRow.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:searchRow];

    self.searchField = [[UITextField alloc] init];
    self.searchField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchField.borderStyle = UITextBorderStyleRoundedRect;
    self.searchField.font = [UIFont systemFontOfSize:13];
    self.searchField.placeholder = @"搜索地点 或 粘贴坐标(lat,lng)";
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.delegate = self;
    [searchRow addSubview:self.searchField];

    self.crsSegment = [[UISegmentedControl alloc] initWithItems:@[@"WGS", @"GCJ", @"BD"]];
    self.crsSegment.translatesAutoresizingMaskIntoConstraints = NO;
    self.crsSegment.selectedSegmentIndex = 1; // Default GCJ-02 (Gaode/Tencent)
    [searchRow addSubview:self.crsSegment];

    UIButton *goBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    goBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [goBtn setTitle:@"定位" forState:UIControlStateNormal];
    goBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [goBtn addTarget:self action:@selector(searchOrJumpTapped) forControlEvents:UIControlEventTouchUpInside];
    [searchRow addSubview:goBtn];

    // 4. Map Container
    UIView *mapContainer = [[UIView alloc] init];
    mapContainer.translatesAutoresizingMaskIntoConstraints = NO;
    mapContainer.layer.cornerRadius = 12;
    mapContainer.clipsToBounds = YES;
    [self.view addSubview:mapContainer];

    self.mapView = [[MKMapView alloc] init];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.showsCompass = YES;
    [mapContainer addSubview:self.mapView];

    UITapGestureRecognizer *mapTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapTap:)];
    [self.mapView addGestureRecognizer:mapTap];

    UILongPressGestureRecognizer *mapLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapLongPress:)];
    mapLongPress.minimumPressDuration = 0.5;
    [self.mapView addGestureRecognizer:mapLongPress];

    self.crosshairLabel = [[UILabel alloc] init];
    self.crosshairLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.crosshairLabel.text = @"✛";
    self.crosshairLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightLight];
    self.crosshairLabel.textColor = [UIColor systemRedColor];
    self.crosshairLabel.userInteractionEnabled = NO;
    [mapContainer addSubview:self.crosshairLabel];

    self.centerCoordLabel = [[UILabel alloc] init];
    self.centerCoordLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.centerCoordLabel.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightMedium];
    self.centerCoordLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    self.centerCoordLabel.textColor = [UIColor whiteColor];
    self.centerCoordLabel.textAlignment = NSTextAlignmentCenter;
    self.centerCoordLabel.layer.cornerRadius = 6;
    self.centerCoordLabel.clipsToBounds = YES;
    [mapContainer addSubview:self.centerCoordLabel];

    // Map side floating buttons
    UIStackView *mapTools = [[UIStackView alloc] init];
    mapTools.translatesAutoresizingMaskIntoConstraints = NO;
    mapTools.axis = UILayoutConstraintAxisVertical;
    mapTools.spacing = 6;
    [mapContainer addSubview:mapTools];

    [mapTools addArrangedSubview:[self makeMapToolButton:@"图" action:@selector(toggleMapType)]];
    [mapTools addArrangedSubview:[self makeMapToolButton:@"拟" action:@selector(focusSimulatedLocation)]];
    [mapTools addArrangedSubview:[self makeMapToolButton:@"真" action:@selector(focusRealLocation)]];
    [mapTools addArrangedSubview:[self makeMapToolButton:@"★" action:@selector(favoriteCenterTapped)]];

    // 5. Bottom Tabs
    self.tabSegment = [[UISegmentedControl alloc] initWithItems:@[@"瞬移/摇杆", @"路线模拟", @"范围/设置", @"收藏/历史"]];
    self.tabSegment.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabSegment.selectedSegmentIndex = 0;
    [self.tabSegment addTarget:self action:@selector(tabChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.tabSegment];

    UIView *tabHost = [[UIView alloc] init];
    tabHost.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tabHost];

    [self buildTeleportTabIn:tabHost];
    [self buildRouteTabIn:tabHost];
    [self buildRangeTabIn:tabHost];
    [self buildLibraryTabIn:tabHost];

    // Layout Constraints
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [header.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:14],
        [header.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-14],
        [header.heightAnchor constraintEqualToConstant:32],

        [titleLbl.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [titleLbl.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [doneBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [doneBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [hideFloatBtn.trailingAnchor constraintEqualToAnchor:doneBtn.leadingAnchor constant:-12],
        [hideFloatBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],

        [statusBar.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:6],
        [statusBar.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [statusBar.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [statusBar.heightAnchor constraintEqualToConstant:46],

        [self.enableSwitch.leadingAnchor constraintEqualToAnchor:statusBar.leadingAnchor constant:8],
        [self.enableSwitch.centerYAnchor constraintEqualToAnchor:statusBar.centerYAnchor],
        [self.coordLabel.leadingAnchor constraintEqualToAnchor:self.enableSwitch.trailingAnchor constant:8],
        [self.coordLabel.centerYAnchor constraintEqualToAnchor:statusBar.centerYAnchor],
        [restoreBtn.trailingAnchor constraintEqualToAnchor:statusBar.trailingAnchor constant:-8],
        [restoreBtn.centerYAnchor constraintEqualToAnchor:statusBar.centerYAnchor],
        [self.rangeStatusLabel.trailingAnchor constraintEqualToAnchor:restoreBtn.leadingAnchor constant:-8],
        [self.rangeStatusLabel.centerYAnchor constraintEqualToAnchor:statusBar.centerYAnchor],
        [self.coordLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.rangeStatusLabel.leadingAnchor constant:-4],

        [searchRow.topAnchor constraintEqualToAnchor:statusBar.bottomAnchor constant:8],
        [searchRow.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [searchRow.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [searchRow.heightAnchor constraintEqualToConstant:34],

        [self.searchField.leadingAnchor constraintEqualToAnchor:searchRow.leadingAnchor],
        [self.searchField.centerYAnchor constraintEqualToAnchor:searchRow.centerYAnchor],
        [self.searchField.heightAnchor constraintEqualToConstant:32],
        [self.crsSegment.leadingAnchor constraintEqualToAnchor:self.searchField.trailingAnchor constant:6],
        [self.crsSegment.centerYAnchor constraintEqualToAnchor:searchRow.centerYAnchor],
        [self.crsSegment.widthAnchor constraintEqualToConstant:118],
        [goBtn.leadingAnchor constraintEqualToAnchor:self.crsSegment.trailingAnchor constant:6],
        [goBtn.trailingAnchor constraintEqualToAnchor:searchRow.trailingAnchor],
        [goBtn.centerYAnchor constraintEqualToAnchor:searchRow.centerYAnchor],
        [goBtn.widthAnchor constraintEqualToConstant:36],

        [mapContainer.topAnchor constraintEqualToAnchor:searchRow.bottomAnchor constant:8],
        [mapContainer.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [mapContainer.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [mapContainer.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.38],

        [self.mapView.topAnchor constraintEqualToAnchor:mapContainer.topAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:mapContainer.bottomAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:mapContainer.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:mapContainer.trailingAnchor],

        [self.crosshairLabel.centerXAnchor constraintEqualToAnchor:mapContainer.centerXAnchor],
        [self.crosshairLabel.centerYAnchor constraintEqualToAnchor:mapContainer.centerYAnchor],

        [self.centerCoordLabel.bottomAnchor constraintEqualToAnchor:mapContainer.bottomAnchor constant:-6],
        [self.centerCoordLabel.centerXAnchor constraintEqualToAnchor:mapContainer.centerXAnchor],
        [self.centerCoordLabel.heightAnchor constraintEqualToConstant:20],
        [self.centerCoordLabel.widthAnchor constraintGreaterThanOrEqualToConstant:190],

        [mapTools.topAnchor constraintEqualToAnchor:mapContainer.topAnchor constant:8],
        [mapTools.trailingAnchor constraintEqualToAnchor:mapContainer.trailingAnchor constant:-8],

        [self.tabSegment.topAnchor constraintEqualToAnchor:mapContainer.bottomAnchor constant:10],
        [self.tabSegment.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.tabSegment.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],

        [tabHost.topAnchor constraintEqualToAnchor:self.tabSegment.bottomAnchor constant:10],
        [tabHost.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [tabHost.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [tabHost.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8],
    ]];

    [self tabChanged];
}

- (UIButton *)makeMapToolButton:(NSString *)title action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    b.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.88];
    b.layer.cornerRadius = 15;
    b.layer.shadowColor = [UIColor blackColor].CGColor;
    b.layer.shadowOpacity = 0.2;
    b.layer.shadowRadius = 2;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [b.widthAnchor constraintEqualToConstant:30],
        [b.heightAnchor constraintEqualToConstant:30],
    ]];
    return b;
}

- (void)pinToHost:(UIView *)sub host:(UIView *)host {
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [host addSubview:sub];
    [NSLayoutConstraint activateConstraints:@[
        [sub.topAnchor constraintEqualToAnchor:host.topAnchor],
        [sub.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
        [sub.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
        [sub.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
    ]];
}

- (UIButton *)makePillButton:(NSString *)title color:(UIColor *)color action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    b.backgroundColor = color;
    b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    b.layer.cornerRadius = 10;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)buildTeleportTabIn:(UIView *)host {
    self.tabTeleportView = [[UIView alloc] init];
    [self pinToHost:self.tabTeleportView host:host];

    UIButton *tpBtn = [self makePillButton:@"📍 瞬移到准星位置" color:[UIColor systemBlueColor] action:@selector(teleportToCrosshair)];
    [self.tabTeleportView addSubview:tpBtn];

    self.joystickToggleBtn = [self makePillButton:@"🕹️ 显示/隐藏悬浮摇杆" color:[UIColor systemIndigoColor] action:@selector(toggleJoystickHUD)];
    [self.tabTeleportView addSubview:self.joystickToggleBtn];

    self.speedValueLabel = [[UILabel alloc] init];
    self.speedValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.speedValueLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.tabTeleportView addSubview:self.speedValueLabel];

    self.speedSlider = [[UISlider alloc] init];
    self.speedSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.speedSlider.minimumValue = 0.5;
    self.speedSlider.maximumValue = 30.0;
    self.speedSlider.value = [GeoSimEngine shared].speedMetersPerSecond;
    [self.speedSlider addTarget:self action:@selector(speedSliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.tabTeleportView addSubview:self.speedSlider];

    UIStackView *presets = [[UIStackView alloc] init];
    presets.translatesAutoresizingMaskIntoConstraints = NO;
    presets.distribution = UIStackViewDistributionFillEqually;
    presets.spacing = 8;
    [self.tabTeleportView addSubview:presets];

    NSArray *titles = @[@"步行 1.5", @"跑步 3.5", @"骑行 6.0", @"驾车 15"];
    NSArray *tags = @[@15, @35, @60, @150]; // x0.1 m/s
    for (NSUInteger i = 0; i < titles.count; i++) {
        UIButton *p = [UIButton buttonWithType:UIButtonTypeSystem];
        [p setTitle:titles[i] forState:UIControlStateNormal];
        p.backgroundColor = [UIColor secondarySystemBackgroundColor];
        p.layer.cornerRadius = 8;
        p.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        p.tag = [tags[i] integerValue];
        [p addTarget:self action:@selector(speedPresetTapped:) forControlEvents:UIControlEventTouchUpInside];
        [presets addArrangedSubview:p];
    }

    [NSLayoutConstraint activateConstraints:@[
        [tpBtn.topAnchor constraintEqualToAnchor:self.tabTeleportView.topAnchor constant:4],
        [tpBtn.leadingAnchor constraintEqualToAnchor:self.tabTeleportView.leadingAnchor],
        [tpBtn.trailingAnchor constraintEqualToAnchor:self.tabTeleportView.trailingAnchor],
        [tpBtn.heightAnchor constraintEqualToConstant:42],

        [self.joystickToggleBtn.topAnchor constraintEqualToAnchor:tpBtn.bottomAnchor constant:8],
        [self.joystickToggleBtn.leadingAnchor constraintEqualToAnchor:self.tabTeleportView.leadingAnchor],
        [self.joystickToggleBtn.trailingAnchor constraintEqualToAnchor:self.tabTeleportView.trailingAnchor],
        [self.joystickToggleBtn.heightAnchor constraintEqualToConstant:38],

        [self.speedValueLabel.topAnchor constraintEqualToAnchor:self.joystickToggleBtn.bottomAnchor constant:12],
        [self.speedValueLabel.leadingAnchor constraintEqualToAnchor:self.tabTeleportView.leadingAnchor],
        [self.speedSlider.centerYAnchor constraintEqualToAnchor:self.speedValueLabel.centerYAnchor],
        [self.speedSlider.leadingAnchor constraintEqualToAnchor:self.speedValueLabel.trailingAnchor constant:10],
        [self.speedSlider.trailingAnchor constraintEqualToAnchor:self.tabTeleportView.trailingAnchor],

        [presets.topAnchor constraintEqualToAnchor:self.speedValueLabel.bottomAnchor constant:10],
        [presets.leadingAnchor constraintEqualToAnchor:self.tabTeleportView.leadingAnchor],
        [presets.trailingAnchor constraintEqualToAnchor:self.tabTeleportView.trailingAnchor],
        [presets.heightAnchor constraintEqualToConstant:32],
    ]];
}

- (void)buildRouteTabIn:(UIView *)host {
    self.tabRouteView = [[UIView alloc] init];
    [self pinToHost:self.tabRouteView host:host];

    self.transportSegment = [[UISegmentedControl alloc] initWithItems:@[@"直线", @"沿路步行", @"沿路驾车"]];
    self.transportSegment.translatesAutoresizingMaskIntoConstraints = NO;
    self.transportSegment.selectedSegmentIndex = [GeoSimEngine shared].routeTransportMode;
    [self.transportSegment addTarget:self action:@selector(transportChanged) forControlEvents:UIControlEventValueChanged];
    [self.tabRouteView addSubview:self.transportSegment];

    UILabel *loopLbl = [[UILabel alloc] init];
    loopLbl.translatesAutoresizingMaskIntoConstraints = NO;
    loopLbl.text = @"循环";
    loopLbl.font = [UIFont systemFontOfSize:13];
    [self.tabRouteView addSubview:loopLbl];

    self.loopSwitch = [[UISwitch alloc] init];
    self.loopSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.loopSwitch.on = [GeoSimEngine shared].routeLoop;
    [self.loopSwitch addTarget:self action:@selector(loopChanged) forControlEvents:UIControlEventValueChanged];
    [self.tabRouteView addSubview:self.loopSwitch];

    UIStackView *btnRow = [[UIStackView alloc] init];
    btnRow.translatesAutoresizingMaskIntoConstraints = NO;
    btnRow.distribution = UIStackViewDistributionFillEqually;
    btnRow.spacing = 8;
    [self.tabRouteView addSubview:btnRow];

    UIButton *addWp = [self makePillButton:@"+ 途经点" color:[UIColor systemTealColor] action:@selector(addWaypointTapped)];
    self.routePlayBtn = [self makePillButton:@"▶ 开始" color:[UIColor systemGreenColor] action:@selector(routePlayPauseTapped)];
    UIButton *stopBtn = [self makePillButton:@"■ 停止" color:[UIColor systemOrangeColor] action:@selector(routeStopTapped)];
    UIButton *clrBtn = [self makePillButton:@"清空" color:[UIColor systemGrayColor] action:@selector(routeClearTapped)];

    [btnRow addArrangedSubview:addWp];
    [btnRow addArrangedSubview:self.routePlayBtn];
    [btnRow addArrangedSubview:stopBtn];
    [btnRow addArrangedSubview:clrBtn];

    self.routeInfoLabel = [[UILabel alloc] init];
    self.routeInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.routeInfoLabel.font = [UIFont systemFontOfSize:12];
    self.routeInfoLabel.textColor = [UIColor secondaryLabelColor];
    [self.tabRouteView addSubview:self.routeInfoLabel];

    self.routeProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.routeProgressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tabRouteView addSubview:self.routeProgressView];

    [NSLayoutConstraint activateConstraints:@[
        [self.transportSegment.topAnchor constraintEqualToAnchor:self.tabRouteView.topAnchor constant:4],
        [self.transportSegment.leadingAnchor constraintEqualToAnchor:self.tabRouteView.leadingAnchor],
        [self.loopSwitch.trailingAnchor constraintEqualToAnchor:self.tabRouteView.trailingAnchor],
        [self.loopSwitch.centerYAnchor constraintEqualToAnchor:self.transportSegment.centerYAnchor],
        [loopLbl.trailingAnchor constraintEqualToAnchor:self.loopSwitch.leadingAnchor constant:-6],
        [loopLbl.centerYAnchor constraintEqualToAnchor:self.transportSegment.centerYAnchor],
        [self.transportSegment.trailingAnchor constraintEqualToAnchor:loopLbl.leadingAnchor constant:-10],

        [btnRow.topAnchor constraintEqualToAnchor:self.transportSegment.bottomAnchor constant:12],
        [btnRow.leadingAnchor constraintEqualToAnchor:self.tabRouteView.leadingAnchor],
        [btnRow.trailingAnchor constraintEqualToAnchor:self.tabRouteView.trailingAnchor],
        [btnRow.heightAnchor constraintEqualToConstant:40],

        [self.routeInfoLabel.topAnchor constraintEqualToAnchor:btnRow.bottomAnchor constant:12],
        [self.routeInfoLabel.leadingAnchor constraintEqualToAnchor:self.tabRouteView.leadingAnchor],
        [self.routeInfoLabel.trailingAnchor constraintEqualToAnchor:self.tabRouteView.trailingAnchor],

        [self.routeProgressView.topAnchor constraintEqualToAnchor:self.routeInfoLabel.bottomAnchor constant:8],
        [self.routeProgressView.leadingAnchor constraintEqualToAnchor:self.tabRouteView.leadingAnchor],
        [self.routeProgressView.trailingAnchor constraintEqualToAnchor:self.tabRouteView.trailingAnchor],
    ]];
}

- (void)buildRangeTabIn:(UIView *)host {
    self.tabRangeView = [[UIView alloc] init];
    [self pinToHost:self.tabRangeView host:host];

    UILabel *rLbl = [[UILabel alloc] init];
    rLbl.translatesAutoresizingMaskIntoConstraints = NO;
    rLbl.text = @"启用范围圈（打卡范围检查）";
    rLbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.tabRangeView addSubview:rLbl];

    self.rangeSwitch = [[UISwitch alloc] init];
    self.rangeSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.rangeSwitch.on = [GeoSimEngine shared].rangeEnabled;
    [self.rangeSwitch addTarget:self action:@selector(rangeSwitchChanged) forControlEvents:UIControlEventValueChanged];
    [self.tabRangeView addSubview:self.rangeSwitch];

    UIButton *setCenterBtn = [self makePillButton:@"⭕ 将准星设为范围圈圆心" color:[UIColor systemPurpleColor] action:@selector(setRangeCenterTapped)];
    [self.tabRangeView addSubview:setCenterBtn];

    self.rangeRadiusLabel = [[UILabel alloc] init];
    self.rangeRadiusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.rangeRadiusLabel.font = [UIFont systemFontOfSize:13];
    [self.tabRangeView addSubview:self.rangeRadiusLabel];

    self.rangeRadiusSlider = [[UISlider alloc] init];
    self.rangeRadiusSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.rangeRadiusSlider.minimumValue = 20.0;
    self.rangeRadiusSlider.maximumValue = 2000.0;
    self.rangeRadiusSlider.value = [GeoSimEngine shared].rangeRadiusMeters;
    [self.rangeRadiusSlider addTarget:self action:@selector(rangeRadiusChanged) forControlEvents:UIControlEventValueChanged];
    [self.tabRangeView addSubview:self.rangeRadiusSlider];

    UILabel *jLbl = [[UILabel alloc] init];
    jLbl.translatesAutoresizingMaskIntoConstraints = NO;
    jLbl.text = @"速度随机浮动 (±10% 防规律检测)";
    jLbl.font = [UIFont systemFontOfSize:14];
    [self.tabRangeView addSubview:jLbl];

    self.jitterSwitch = [[UISwitch alloc] init];
    self.jitterSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.jitterSwitch.on = [GeoSimEngine shared].speedJitterRatio > 0.01;
    [self.jitterSwitch addTarget:self action:@selector(jitterSwitchChanged) forControlEvents:UIControlEventValueChanged];
    [self.tabRangeView addSubview:self.jitterSwitch];

    [NSLayoutConstraint activateConstraints:@[
        [rLbl.topAnchor constraintEqualToAnchor:self.tabRangeView.topAnchor constant:8],
        [rLbl.leadingAnchor constraintEqualToAnchor:self.tabRangeView.leadingAnchor],
        [self.rangeSwitch.centerYAnchor constraintEqualToAnchor:rLbl.centerYAnchor],
        [self.rangeSwitch.trailingAnchor constraintEqualToAnchor:self.tabRangeView.trailingAnchor],

        [setCenterBtn.topAnchor constraintEqualToAnchor:rLbl.bottomAnchor constant:12],
        [setCenterBtn.leadingAnchor constraintEqualToAnchor:self.tabRangeView.leadingAnchor],
        [setCenterBtn.trailingAnchor constraintEqualToAnchor:self.tabRangeView.trailingAnchor],
        [setCenterBtn.heightAnchor constraintEqualToConstant:38],

        [self.rangeRadiusLabel.topAnchor constraintEqualToAnchor:setCenterBtn.bottomAnchor constant:12],
        [self.rangeRadiusLabel.leadingAnchor constraintEqualToAnchor:self.tabRangeView.leadingAnchor],
        [self.rangeRadiusSlider.centerYAnchor constraintEqualToAnchor:self.rangeRadiusLabel.centerYAnchor],
        [self.rangeRadiusSlider.leadingAnchor constraintEqualToAnchor:self.rangeRadiusLabel.trailingAnchor constant:10],
        [self.rangeRadiusSlider.trailingAnchor constraintEqualToAnchor:self.tabRangeView.trailingAnchor],

        [jLbl.topAnchor constraintEqualToAnchor:self.rangeRadiusLabel.bottomAnchor constant:16],
        [jLbl.leadingAnchor constraintEqualToAnchor:self.tabRangeView.leadingAnchor],
        [self.jitterSwitch.centerYAnchor constraintEqualToAnchor:jLbl.centerYAnchor],
        [self.jitterSwitch.trailingAnchor constraintEqualToAnchor:self.tabRangeView.trailingAnchor],
    ]];
}

- (void)buildLibraryTabIn:(UIView *)host {
    self.libraryTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.libraryTableView.dataSource = self;
    self.libraryTableView.delegate = self;
    self.libraryTableView.rowHeight = 46;
    [self pinToHost:self.libraryTableView host:host];
}

#pragma mark - Refresh & Sync

- (void)onEngineChanged {
    [self refreshAllUI];
}

- (void)refreshAllUI {
    GeoSimEngine *eng = [GeoSimEngine shared];
    self.enableSwitch.on = eng.enabled;

    CLLocationCoordinate2D wgs = eng.currentWGS84;
    CLLocationCoordinate2D gcj = GeoSimFromWGS84(wgs, GeoSimCRSGCJ02);
    self.coordLabel.text = [NSString stringWithFormat:@"%@ WGS: %.5f, %.5f\nGCJ: %.5f, %.5f (点击复制)",
                            eng.enabled ? @"🟢" : @"⚪️",
                            wgs.latitude, wgs.longitude,
                            gcj.latitude, gcj.longitude];

    if (eng.rangeEnabled) {
        double dist = [eng distanceFromRangeCenter];
        double diff = dist - eng.rangeRadiusMeters;
        if (diff <= 0) {
            self.rangeStatusLabel.text = [NSString stringWithFormat:@"圈内 (余%.0fm)", -diff];
            self.rangeStatusLabel.textColor = [UIColor systemGreenColor];
        } else {
            self.rangeStatusLabel.text = [NSString stringWithFormat:@"超圈 %.0fm", diff];
            self.rangeStatusLabel.textColor = [UIColor systemRedColor];
        }
    } else {
        self.rangeStatusLabel.text = @"";
    }

    self.speedValueLabel.text = [NSString stringWithFormat:@"速度 %.1f m/s (%.0f km/h)",
                                 eng.speedMetersPerSecond, eng.speedMetersPerSecond * 3.6];
    self.rangeRadiusLabel.text = [NSString stringWithFormat:@"半径 %.0f m", eng.rangeRadiusMeters];

    // Route info
    NSString *statusText = @"待机";
    if (eng.routeRunning) {
        statusText = eng.routePaused ? @"已暂停" : @"模拟行走中";
        [self.routePlayBtn setTitle:(eng.routePaused ? @"▶ 继续" : @"⏸ 暂停") forState:UIControlStateNormal];
    } else {
        [self.routePlayBtn setTitle:@"▶ 开始" forState:UIControlStateNormal];
    }
    self.routeInfoLabel.text = [NSString stringWithFormat:@"途经点: %lu · 轨迹点: %lu · 状态: %@",
                                (unsigned long)eng.waypointsWGS84.count,
                                (unsigned long)eng.routePolylineWGS84.count,
                                statusText];
    self.routeProgressView.progress = (float)eng.routeProgress;

    [self refreshMapOverlaysAndAnnotations];
    [self.libraryTableView reloadData];
}

- (void)refreshMapOverlaysAndAnnotations {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];

    GeoSimEngine *eng = [GeoSimEngine shared];
    if (eng.enabled) {
        GeoSimPinAnnotation *pin = [[GeoSimPinAnnotation alloc] init];
        pin.coordinate = GeoSimWGS84ToMap(eng.currentWGS84);
        pin.title = @"当前模拟位置";
        pin.isWaypoint = NO;
        [self.mapView addAnnotation:pin];
    }

    for (NSUInteger i = 0; i < eng.waypointsWGS84.count; i++) {
        GeoSimPinAnnotation *wp = [[GeoSimPinAnnotation alloc] init];
        wp.coordinate = GeoSimWGS84ToMap(eng.waypointsWGS84[i].MKCoordinateValue);
        wp.title = [NSString stringWithFormat:@"途经点 %lu", (unsigned long)(i + 1)];
        wp.isWaypoint = YES;
        [self.mapView addAnnotation:wp];
    }

    NSArray<NSValue *> *polyPts = eng.routePolylineWGS84.count >= 2 ? eng.routePolylineWGS84 : eng.waypointsWGS84;
    if (polyPts.count >= 2) {
        CLLocationCoordinate2D *coords = calloc(polyPts.count, sizeof(CLLocationCoordinate2D));
        for (NSUInteger i = 0; i < polyPts.count; i++) {
            coords[i] = GeoSimWGS84ToMap(polyPts[i].MKCoordinateValue);
        }
        MKPolyline *line = [MKPolyline polylineWithCoordinates:coords count:polyPts.count];
        free(coords);
        [self.mapView addOverlay:line];
    }

    if (eng.rangeEnabled) {
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:GeoSimWGS84ToMap(eng.rangeCenterWGS84)
                                                         radius:eng.rangeRadiusMeters];
        [self.mapView addOverlay:circle];
    }
}

- (void)centerMapOnWGS84:(CLLocationCoordinate2D)wgs animated:(BOOL)animated {
    CLLocationCoordinate2D mapCoord = GeoSimWGS84ToMap(wgs);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(mapCoord, 1200, 1200);
    [self.mapView setRegion:region animated:animated];
}

#pragma mark - Actions

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hideFloatTapped {
    [GeoSimOverlay setFloatingButtonHidden:YES];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"悬浮球已隐藏"
                                                                message:@"随时在屏幕任意位置「三指双击」即可重新唤出悬浮球。"
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)enableSwitchChanged {
    GeoSimEngine *eng = [GeoSimEngine shared];
    if (self.enableSwitch.on) {
        [eng teleportToWGS84:eng.currentWGS84 name:nil];
    } else {
        [eng restoreRealLocation];
    }
}

- (void)restoreRealTapped {
    [[GeoSimEngine shared] restoreRealLocation];
}

- (void)copyCurrentCoords {
    CLLocationCoordinate2D wgs = [GeoSimEngine shared].currentWGS84;
    CLLocationCoordinate2D gcj = GeoSimFromWGS84(wgs, GeoSimCRSGCJ02);
    NSString *text = [NSString stringWithFormat:@"WGS84: %.6f, %.6f\nGCJ02: %.6f, %.6f",
                      wgs.latitude, wgs.longitude, gcj.latitude, gcj.longitude];
    [UIPasteboard generalPasteboard].string = text;
    self.centerCoordLabel.text = @" 已复制当前坐标 ";
}

- (void)tabChanged {
    NSInteger idx = self.tabSegment.selectedSegmentIndex;
    self.tabTeleportView.hidden = (idx != 0);
    self.tabRouteView.hidden = (idx != 1);
    self.tabRangeView.hidden = (idx != 2);
    self.libraryTableView.hidden = (idx != 3);
}

- (void)teleportToCrosshair {
    CLLocationCoordinate2D wgs = GeoSimMapToWGS84(self.mapView.centerCoordinate);
    [[GeoSimEngine shared] teleportToWGS84:wgs name:nil];
}

- (void)toggleJoystickHUD {
    BOOL next = ![GeoSimOverlay isJoystickHUDVisible];
    [GeoSimOverlay setJoystickHUDVisible:next];
}

- (void)speedSliderChanged {
    [GeoSimEngine shared].speedMetersPerSecond = self.speedSlider.value;
    [self refreshAllUI];
}

- (void)speedPresetTapped:(UIButton *)sender {
    double spd = (double)sender.tag / 10.0;
    [GeoSimEngine shared].speedMetersPerSecond = spd;
    self.speedSlider.value = (float)spd;
    [self refreshAllUI];
}

- (void)transportChanged {
    [GeoSimEngine shared].routeTransportMode = (GeoSimTransportMode)self.transportSegment.selectedSegmentIndex;
}

- (void)loopChanged {
    [GeoSimEngine shared].routeLoop = self.loopSwitch.on;
}

- (void)addWaypointTapped {
    CLLocationCoordinate2D wgs = GeoSimMapToWGS84(self.mapView.centerCoordinate);
    [[GeoSimEngine shared] addWaypointWGS84:wgs];
}

- (void)routePlayPauseTapped {
    GeoSimEngine *eng = [GeoSimEngine shared];
    if (eng.routeRunning) {
        if (eng.routePaused) [eng resumeRoute];
        else [eng pauseRoute];
        return;
    }
    [eng buildAndStartRouteWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        if (!success) {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"无法开始路线"
                                                                        message:errorMessage ?: @"未知错误"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:ac animated:YES completion:nil];
        }
    }];
}

- (void)routeStopTapped {
    [[GeoSimEngine shared] stopRoute];
}

- (void)routeClearTapped {
    [[GeoSimEngine shared] clearRoute];
}

- (void)rangeSwitchChanged {
    [GeoSimEngine shared].rangeEnabled = self.rangeSwitch.on;
    [self refreshAllUI];
}

- (void)setRangeCenterTapped {
    CLLocationCoordinate2D wgs = GeoSimMapToWGS84(self.mapView.centerCoordinate);
    [GeoSimEngine shared].rangeCenterWGS84 = wgs;
    [GeoSimEngine shared].rangeEnabled = YES;
    self.rangeSwitch.on = YES;
    [self refreshAllUI];
}

- (void)rangeRadiusChanged {
    [GeoSimEngine shared].rangeRadiusMeters = self.rangeRadiusSlider.value;
    [self refreshAllUI];
}

- (void)jitterSwitchChanged {
    [GeoSimEngine shared].speedJitterRatio = self.jitterSwitch.on ? 0.10 : 0.0;
}

- (void)toggleMapType {
    self.mapView.mapType = (self.mapView.mapType == MKMapTypeStandard) ? MKMapTypeHybrid : MKMapTypeStandard;
}

- (void)focusSimulatedLocation {
    [self centerMapOnWGS84:[GeoSimEngine shared].currentWGS84 animated:YES];
}

- (void)focusRealLocation {
    CLLocation *realLoc = [GeoSimLocationHook lastObservedRealLocation];
    if (realLoc) {
        [self centerMapOnWGS84:realLoc.coordinate animated:YES];
    }
}

- (void)promptFavoriteAtWGS84:(CLLocationCoordinate2D)wgs title:(NSString *)title {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title
                                                                message:[NSString stringWithFormat:@"WGS-84: %.5f, %.5f", wgs.latitude, wgs.longitude]
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull tf) {
        tf.placeholder = @"输入地点名称 (如: 公司打卡点)";
    }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull tf) {
        tf.placeholder = @"输入备注 (选填，如: 东门考勤机)";
    }];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:@"保存收藏" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = ac.textFields[0].text;
        NSString *note = ac.textFields[1].text;
        [[GeoSimEngine shared] addFavorite:wgs name:name note:note];
        self.centerCoordLabel.text = @" 已收藏该地点 ";
    }]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)favoriteCenterTapped {
    CLLocationCoordinate2D wgs = GeoSimMapToWGS84(self.mapView.centerCoordinate);
    [self promptFavoriteAtWGS84:wgs title:@"收藏准星位置"];
}

- (void)handleMapLongPress:(UILongPressGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateBegan) return;
    CGPoint pt = [gr locationInView:self.mapView];
    CLLocationCoordinate2D mapCoord = [self.mapView convertPoint:pt toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D wgs = GeoSimMapToWGS84(mapCoord);
    [self promptFavoriteAtWGS84:wgs title:@"长按收藏地点"];
}

- (void)handleMapTap:(UITapGestureRecognizer *)gr {
    CGPoint pt = [gr locationInView:self.mapView];
    CLLocationCoordinate2D mapCoord = [self.mapView convertPoint:pt toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:mapCoord animated:YES];
}

#pragma mark - Search & Coordinate Parsing

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self searchOrJumpTapped];
    return YES;
}

- (void)searchOrJumpTapped {
    [self.searchField resignFirstResponder];
    NSString *query = [self.searchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (query.length == 0) return;

    CLLocationCoordinate2D parsed;
    if (GeoSimParseCoordinateString(query, &parsed)) {
        GeoSimCRS crs = (GeoSimCRS)self.crsSegment.selectedSegmentIndex;
        CLLocationCoordinate2D wgs = GeoSimToWGS84(parsed, crs);
        [self centerMapOnWGS84:wgs animated:YES];
        [[GeoSimEngine shared] teleportToWGS84:wgs name:query];
        return;
    }

    MKLocalSearchRequest *req = [[MKLocalSearchRequest alloc] init];
    req.naturalLanguageQuery = query;
    req.region = self.mapView.region;
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:req];
    __weak typeof(self) weakSelf = self;
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (response.mapItems.count == 0) {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"未找到结果"
                                                                        message:error.localizedDescription ?: @"请尝试更具体的关键词或直接输入经纬度"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [strongSelf presentViewController:ac animated:YES completion:nil];
            return;
        }
        UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择搜索结果"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        NSUInteger limit = MIN((NSUInteger)6, response.mapItems.count);
        for (NSUInteger i = 0; i < limit; i++) {
            MKMapItem *item = response.mapItems[i];
            NSString *title = item.name ?: @"未知地点";
            [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                CLLocationCoordinate2D wgs = GeoSimMapToWGS84(item.placemark.coordinate);
                [strongSelf centerMapOnWGS84:wgs animated:YES];
                [[GeoSimEngine shared] teleportToWGS84:wgs name:title];
            }]];
        }
        [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        if (sheet.popoverPresentationController) {
            sheet.popoverPresentationController.sourceView = strongSelf.searchField;
            sheet.popoverPresentationController.sourceRect = strongSelf.searchField.bounds;
        }
        [strongSelf presentViewController:sheet animated:YES completion:nil];
    }];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D wgs = GeoSimMapToWGS84(mapView.centerCoordinate);
    self.centerCoordLabel.text = [NSString stringWithFormat:@" 准星 WGS: %.5f, %.5f ", wgs.latitude, wgs.longitude];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *r = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline *)overlay];
        r.strokeColor = [UIColor systemBlueColor];
        r.lineWidth = 4.0;
        return r;
    }
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *r = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        BOOL inside = ([[GeoSimEngine shared] distanceFromRangeCenter] <= [GeoSimEngine shared].rangeRadiusMeters);
        UIColor *c = inside ? [UIColor systemGreenColor] : [UIColor systemRedColor];
        r.strokeColor = c;
        r.fillColor = [c colorWithAlphaComponent:0.15];
        r.lineWidth = 2.0;
        return r;
    }
    return [[MKOverlayRenderer alloc] initWithOverlay:overlay];
}

- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[GeoSimPinAnnotation class]]) return nil;
    GeoSimPinAnnotation *pin = (GeoSimPinAnnotation *)annotation;
    NSString *reuseId = pin.isWaypoint ? @"GeoSimWP" : @"GeoSimSim";
    MKMarkerAnnotationView *v = (MKMarkerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (!v) {
        v = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        v.canShowCallout = YES;
    } else {
        v.annotation = annotation;
    }
    v.markerTintColor = pin.isWaypoint ? [UIColor systemTealColor] : [UIColor systemOrangeColor];
    v.glyphText = pin.isWaypoint ? @"●" : @"📍";
    return v;
}

#pragma mark - UITableViewDataSource / Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return (section == 0) ? @"⭐ 收藏地点" : @"🕒 最近瞬移";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    GeoSimEngine *eng = [GeoSimEngine shared];
    return (section == 0) ? eng.favorites.count : eng.recents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeoSimCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GeoSimCell"];
    }
    GeoSimEngine *eng = [GeoSimEngine shared];
    GeoSimPlace *p = (indexPath.section == 0) ? eng.favorites[indexPath.row] : eng.recents[indexPath.row];
    if (p.note.length > 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ · %@", p.name, p.note];
    } else {
        cell.textLabel.text = p.name;
    }
    cell.textLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"点击一键定位 · WGS: %.5f, %.5f", p.latWGS84, p.lngWGS84];
    cell.detailTextLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightRegular];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GeoSimEngine *eng = [GeoSimEngine shared];
    GeoSimPlace *p = (indexPath.section == 0) ? eng.favorites[indexPath.row] : eng.recents[indexPath.row];
    [self centerMapOnWGS84:p.coordinate animated:YES];
    [eng teleportToWGS84:p.coordinate name:p.name];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 0) {
        [[GeoSimEngine shared] removeFavoriteAtIndex:indexPath.row];
    }
}

@end
