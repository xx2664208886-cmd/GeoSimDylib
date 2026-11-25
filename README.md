# GeoSimHook — iOS 虚拟定位注入插件 (`.dylib`)

参考 [ZhangLifan1987/GeoSim](https://github.com/ZhangLifan1987/GeoSim) 的核心能力实现的纯 Objective-C / UIKit / CoreLocation iOS 动态库插件。**无任何第三方越狱框架依赖（不依赖 Substrate / ElleKit）**，可直接注入任意 `.ipa` 重签使用，也可在巨魔（TrollStore / TrollFools）或越狱环境下使用。

## 核心功能

- **零依赖运行时 Hook (`GeoSimLocationHook.m`)**：
  - 使用 Objective-C Runtime 动态拦截 `CLLocationManager`（`location`、`setDelegate:`、`startUpdatingLocation`、`requestLocation`、`startMonitoringSignificantLocationChanges`）及代理回调（`didUpdateLocations:` / `didUpdateToLocation:fromLocation:`）。
  - 兼容 iOS 15+ `CLLocationSourceInformation`，将 `isSimulatedBySoftware` 与 `isProducedByAccessory` 返回 `NO`。
  - 支持随时一键「**恢复真实**」定位。
- **精准坐标系换算 (`GeoSimCoords.m`)**：
  - 完整移植 GeoSim 的 `WGS-84` / `GCJ-02`（高德/腾讯/苹果国内地图）/ `BD-09`（百度）互转算法，含 6 次迭代求逆（中国大陆境内误差 < 1 厘米，境外自动直通）。
  - 支持直接粘贴十进制、`经纬度反写自动识别` 及度分秒（DMS）坐标并跳转。
- **悬浮球 + 悬浮摇杆 (`GeoSimOverlay.m`)**：
  - 注入后屏幕右上角出现可拖动悬浮球（`📍 GeoSim` / `📍 模拟中`）。
  - **点击**打开主面板，**长按**快速开关悬浮摇杆，**三指双击**屏幕任意位置可隐藏/重新唤出悬浮球（方便干净截图）。
  - 悬浮摇杆支持 360° 平滑移动、速度切换（步行 1.5 / 骑行 5.0 / 驾车 15.0 m/s）。
- **内置地图控制面板 (`GeoSimViewController.m`)**：
  - **瞬移 & 中心准星**：内置 Apple `MKMapView`，拖动地图对准中心准星一键瞬移。
  - **地点搜索**：内置 `MKLocalSearch` 关键词搜索。
  - **路线模拟**：支持多途经点、**沿真实道路**（`MKDirections` 步行/驾车）或直线、循环开关、暂停/继续、`±10%` 速度随机浮动。
  - **范围圈（打卡范围检查）**：设置圆心和半径（20m~2000m），圈内绿圈、超圈红圈并提示超出米数。
  - **收藏 & 最近记录**：本地持久化保存在宿主 App 的 `NSUserDefaults`（独立前缀 `com.geosim.hook.`）。

## 云端编译方法（GitHub Actions，无需本地 Mac）

1. 在 GitHub 上新建一个仓库（公开或私有均可），将本项目所有文件（务必包含隐藏目录 `.github/workflows/build-dylib.yml`）上传 / 推送上去。
2. 打开 GitHub 仓库页面 -> 点击顶部 **Actions** -> 选择左侧 **Build iOS GeoSimHook.dylib** -> 点击右侧 **Run workflow**（`push` 到 `main`/`master` 也会自动触发）。
3. 等待约 1 分钟编译完成后，在本次运行详情页底部的 **Artifacts** 中下载 `GeoSimHook-dylib`，解压即可得到签名好的 `arm64` 格式 `GeoSimHook.dylib`。

> 如果你本地有 Mac + Xcode，也可以直接在项目根目录执行 `./build.sh` 编译生成 `build/GeoSimHook.dylib`。

## 注入 `.ipa` 使用方式

- **电脑端工具**：使用 `Sideloadly`（勾选 *Inject dylibs/frameworks* 添加 `GeoSimHook.dylib`）、`cyan`、`insert_dylib` 或 `Azule` 将 `GeoSimHook.dylib` 注入目标 `.ipa` 后重新签名安装。
- **手机端工具**：
  - **自签工具（全能签 / 轻松签 ESign 等）**：导入 `.ipa` 与 `GeoSimHook.dylib`，在注入动态库中勾选 `GeoSimHook.dylib`，签名安装即可。
  - **巨魔（TrollStore）**：配合 **TrollFools** 直接选择目标 App 注入 `GeoSimHook.dylib`（无需重签）。
