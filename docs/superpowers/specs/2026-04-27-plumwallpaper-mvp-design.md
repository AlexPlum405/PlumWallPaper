# PlumWallPaper MVP 设计文档

> 日期：2026-04-27
> 状态：待审核

## 1. 项目概述

PlumWallPaper 是一款 macOS 离线动态壁纸管理软件，支持视频壁纸和 HEIC 动态壁纸，提供色彩调节、多显示器独立设置、定时轮播等功能。

**核心原则：**

- 代码简洁清爽，避免臃肿
- 低系统资源占用（CPU < 5%，内存 < 150MB）
- 壁纸高渲染质量
- UI 设计由 huashu-design 完成

**项目定位：** 先自用，后续可能上架 Mac App Store，同时开源。

**应用形态：** 标准窗口应用（Dock 图标 + 主窗口），菜单栏常驻做快捷操作，支持开机自启动。

**技术栈：** SwiftUI + AppKit + AVFoundation + Core Image + SwiftData

## 2. MVP 功能范围

### 包含

- 视频壁纸（MP4/MOV）+ HEIC 动态壁纸双格式支持
- 壁纸导入（拖拽 + 文件选择器）、重复检测、自动生成缩略图
- 首页 Hero 展示区（大图展示当前/最近使用的壁纸）+ 横向缩略图滚动
- 壁纸库卡片网格布局，搜索和排序（按导入时间/名称）
- 鼠标悬停卡片自动播放预览
- 收藏功能（心形按钮，一键收藏/取消）
- 分类标签管理（用户自定义标签，按标签筛选）
- 完整色彩调节面板（色调/色温/饱和度/亮度/对比度 + 预设滤镜 + 自定义预设保存）
- 多显示器独立设置不同壁纸
- 定时轮播（顺序/随机，可配置间隔）
- 可配置省电策略
- 菜单栏快捷操作
- 深色沉浸式 UI（纯黑底，壁纸内容为视觉主角，参考 Wallspace 风格）

### 不包含（后续迭代）

- 暗色/亮色模式绑定不同壁纸
- GIF、Live Photo、粒子特效等其他格式
- 壁纸导出（调整后的壁纸导出为文件）

## 3. 架构设计

```
PlumWallPaper/
├── App/                    # 应用入口和生命周期
├── UI/                     # 界面层（SwiftUI）
│   ├── WallpaperLibrary/   # 壁纸库视图
│   ├── ColorAdjustment/    # 色彩调节面板
│   └── MenuBar/            # 菜单栏快捷操作
├── Core/                   # 核心业务逻辑
│   ├── WallpaperEngine/    # 壁纸渲染引擎
│   ├── ColorFilter/        # 色彩滤镜处理
│   ├── DisplayManager/     # 多显示器管理
│   └── Scheduler/          # 轮播调度器
├── Storage/                # 数据持久化
│   ├── WallpaperStore/     # 壁纸索引和元数据
│   └── PreferencesStore/   # 用户配置
└── System/                 # 系统集成
    └── DesktopBridge/      # macOS 桌面壁纸 API 封装
```

**关键设计决策：**

1. **WallpaperEngine 独立进程** — 视频解码和渲染放在单独的 XPC Service 中，主应用崩溃不影响壁纸播放，资源隔离更彻底
2. **非破坏性色彩调节** — 滤镜参数存 JSON，原文件不动，应用时用 Core Image 实时渲染（GPU 加速）
3. **轻量级存储** — 只存壁纸路径 + 缩略图 + 元数据，不复制原文件，用户自己管理文件位置
4. **声明式 UI** — 纯 SwiftUI，代码量更少更清爽

## 4. 性能优化策略

**目标：CPU < 5%，内存 < 150MB，GPU 硬件加速**

### 视频渲染

- `AVPlayerLayer` 直接渲染到桌面窗口（位于 Dock 图标层下方）
- 启用硬件解码：`AVPlayer` 配置 `preferredVideoDecoderGPURegistryID`
- 视频循环用 `AVPlayerLooper`，避免手动监听播放结束

### HEIC 动态壁纸

- 直接调用 `NSWorkspace.shared.setDesktopImageURL`，系统原生支持

### 色彩滤镜

- Core Image `CIFilter` 链式处理：`CIColorControls` + `CITemperatureAndTint` + `CIHueAdjust`
- 滤镜应用在 `AVVideoComposition` 上，GPU 实时处理，不落盘

### 多显示器

- 每个屏幕一个独立 `AVPlayer` 实例
- 监听 `NSApplication.didChangeScreenParametersNotification` 处理屏幕插拔

### 缩略图

- 导入时用 `AVAssetImageGenerator` 提取第一帧，压缩到 300x200
- 存储路径：`~/Library/Caches/PlumWallPaper/Thumbnails/`

## 5. 省电策略

### 应用状态触发

- 任意应用全屏时暂停
- 任意应用最大化时暂停
- 指定应用获得焦点时暂停（用户可添加应用白名单）
- 任意应用获得焦点时暂停

### 系统状态触发

- 使用电池供电时暂停
- 低电量模式时暂停（< 20%）
- 屏幕锁定时暂停
- 屏保激活时暂停

### 性能模式预设

- 始终播放（不暂停）
- 智能模式（电池时暂停 + 全屏时暂停）
- 省电模式（所有条件都暂停）
- 自定义（用户勾选具体条件）

### 降级策略

- 触发条件时降低帧率（60fps → 15fps）
- 触发条件时切换到静态壁纸（显示视频第一帧）

### 实现方式

- 监听 `NSWorkspace` 的应用切换、屏幕参数变化
- 监听 `IOPSNotificationCreateRunLoopSource` 获取电源状态
- 用户配置存 `UserDefaults`

## 6. 数据模型

### Wallpaper（壁纸实体）

```swift
struct Wallpaper {
    let id: UUID
    var name: String                    // 显示名称
    let filePath: URL                   // 原文件路径
    let thumbnailPath: URL              // 缩略图缓存路径
    let type: WallpaperType             // .video / .heic
    let duration: TimeInterval?         // 视频时长（HEIC 为 nil）
    let resolution: CGSize              // 原始分辨率
    let fileSize: Int64                 // 文件大小
    var colorFilter: ColorFilterParams? // 色彩调节参数
    var playbackSpeed: Double           // 播放速度，默认 1.0
    let importDate: Date                // 导入时间
    var lastUsedDate: Date?             // 最后使用时间
}

enum WallpaperType {
    case video  // MP4, MOV
    case heic   // HEIC 动态壁纸
}
```

### ColorFilterParams（色彩参数）

```swift
struct ColorFilterParams: Codable {
    var hue: Double           // 色相 -180~180
    var saturation: Double    // 饱和度 0~2
    var brightness: Double    // 亮度 -1~1
    var contrast: Double      // 对比度 0~2
    var temperature: Double   // 色温 2000~10000
    var presetName: String?   // 预设名称（如果使用预设）
}
```

### RotationConfig（轮播配置）

```swift
struct RotationConfig {
    var enabled: Bool
    var interval: TimeInterval          // 轮播间隔（秒）
    var wallpaperIDs: [UUID]            // 参与轮播的壁纸列表
    var order: RotationOrder            // .sequential / .random
    var perDisplay: [String: [UUID]]    // 每个显示器独立轮播列表
}

enum RotationOrder {
    case sequential
    case random
}
```

### 持久化方案

使用 **SwiftData**，轻量且与 SwiftUI 深度集成，避免 Core Data 的复杂度。

## 7. 核心组件

### WallpaperEngine（壁纸渲染引擎）

```swift
class WallpaperEngine {
    private var players: [String: AVPlayer] = [:]

    func setWallpaper(_ wallpaper: Wallpaper, for screen: NSScreen)
    func pause(for screen: NSScreen)
    func resume(for screen: NSScreen)
    func applyColorFilter(_ params: ColorFilterParams, to wallpaper: Wallpaper)
}
```

**职责：** 视频解码、渲染到桌面窗口、色彩滤镜应用

**关键实现：**

- 创建透明 `NSWindow`（level = `kCGDesktopWindowLevel - 1`）
- 添加 `AVPlayerLayer` 到窗口
- 通过 `AVVideoComposition` 应用 Core Image 滤镜

### ColorFilterEngine（色彩滤镜引擎）

```swift
class ColorFilterEngine {
    func createVideoComposition(
        for asset: AVAsset,
        with params: ColorFilterParams
    ) -> AVVideoComposition

    func presetFilters() -> [String: ColorFilterParams]
}
```

**职责：** Core Image 滤镜链构建，预设滤镜管理

**预设滤镜：**

- 暖色调
- 冷色调
- 复古
- 黑白
- 高对比度

### DisplayManager（多显示器管理）

```swift
class DisplayManager: ObservableObject {
    @Published var screens: [NSScreen] = []
    @Published var wallpaperAssignments: [String: UUID] = [:]

    func handleScreenChange()
    func assignWallpaper(_ id: UUID, to screenID: String)
}
```

**职责：** 监听屏幕插拔，维护屏幕-壁纸映射关系

### RotationScheduler（轮播调度器）

```swift
class RotationScheduler {
    private var timer: Timer?

    func start(with config: RotationConfig)
    func stop()
    func next(for screen: NSScreen)
}
```

**职责：** 定时切换壁纸，支持顺序/随机模式

### PowerManager（省电管理器）

```swift
class PowerManager {
    func shouldPause(for screen: NSScreen) -> Bool
    func startMonitoring()
    func stopMonitoring()
}
```

**职责：** 监听系统状态（电池、应用焦点、全屏），根据用户配置决定是否暂停

## 8. UI 设计

**由 huashu-design skill 负责设计**，遵循以下原则：

- macOS 原生风格，与系统设置应用保持一致
- 卡片式网格布局，视觉层级清晰
- 色彩调节面板实时预览
- 流畅的动画过渡

**主要界面：**

1. **壁纸库主界面**

   - 顶部：搜索框 + 排序选择器 + 导入按钮
   - 中间：卡片网格（缩略图 + 名称 + 时长标签）
   - 底部：状态栏（壁纸总数、存储占用）

2. **色彩调节面板**

   - 左侧：实时预览区域
   - 右侧：滑块控制（色调/色温/饱和度/亮度/对比度）
   - 底部：预设滤镜快捷按钮 + 保存自定义预设

3. **菜单栏**
   - 当前壁纸缩略图
   - 快捷切换（下一张/暂停/恢复）
   - 打开主窗口
   - 退出

## 9. 数据流

```
用户操作 → UI 层 → Core 层 → System 层
                ↓
            Storage 层
```

**示例：设置壁纸**

1. 用户点击壁纸卡片
2. `WallpaperLibraryView` 调用 `DisplayManager.assignWallpaper()`
3. `DisplayManager` 更新映射关系，通知 `WallpaperEngine`
4. `WallpaperEngine` 创建 `AVPlayer`，应用色彩滤镜，渲染到桌面窗口
5. `WallpaperStore` 更新 `lastUsedDate`

## 10. 错误处理

### 文件丢失

- 导入时记录文件路径，使用时检查文件是否存在
- 文件丢失时显示占位符，提示用户重新导入

### 视频解码失败

- 捕获 `AVPlayer` 错误，显示错误提示
- 自动跳过损坏的壁纸，继续轮播

### 屏幕插拔

- 监听屏幕变化，自动调整壁纸分配
- 屏幕移除时保存其壁纸配置，重新连接时恢复

### 权限问题

- 首次运行时请求屏幕录制权限（用于检测全屏应用）
- 权限被拒绝时禁用相关省电策略选项

## 11. 测试策略

### 单元测试

- `ColorFilterEngine` 滤镜参数计算
- `RotationScheduler` 轮播逻辑
- `PowerManager` 暂停条件判断

### 集成测试

- 多显示器插拔场景
- 视频播放 + 色彩滤镜组合
- 轮播切换流畅性

### 性能测试

- CPU/内存占用监控
- 长时间运行稳定性（24 小时）
- 多显示器同时播放

## 12. 开发计划

### 第一阶段：核心渲染（1 周）

- WallpaperEngine 基础实现
- 视频播放到桌面窗口
- 单显示器支持

### 第二阶段：色彩调节（3-4 天）

- ColorFilterEngine 实现
- Core Image 滤镜链
- 预设滤镜

### 第三阶段：多显示器 + 轮播（3-4 天）

- DisplayManager 实现
- RotationScheduler 实现
- 屏幕插拔处理

### 第四阶段：省电策略（2-3 天）

- PowerManager 实现
- 系统状态监听
- 配置界面

### 第五阶段：UI + 数据持久化（1 周）

- SwiftUI 界面（由 huashu-design 设计）
- SwiftData 集成
- 导入/搜索/排序

### 第六阶段：测试 + 优化（3-4 天）

- 性能优化
- Bug 修复
- 用户体验打磨

**总计：3-4 周**

## 13. 技术风险

### 桌面窗口渲染

**风险：** macOS 可能限制应用在桌面层级创建窗口  
**缓解：** 使用 `kCGDesktopWindowLevel - 1`，参考 Wallpaper Engine 等成熟方案

### 硬件加速

**风险：** 部分 Mac 设备可能不支持特定视频编码的硬件解码  
**缓解：** 降级到软件解码，提示用户转码视频

### 系统权限

**风险：** 屏幕录制权限可能被用户拒绝  
**缓解：** 提供清晰的权限说明，禁用依赖该权限的功能

## 14. 后续迭代方向

- 暗色/亮色模式绑定不同壁纸
- 壁纸分组/标签管理
- GIF、Live Photo 支持
- 壁纸导出功能
- iCloud 同步配置
- 社区壁纸分享

---

**设计完成，等待审核。**
