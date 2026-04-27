# PlumWallPaper MVP v2 实施规格

> **日期**：2026-04-28  
> **版本**：MVP v2（基于 v5 原型整合）  
> **状态**：待实施  
> **原型参考**：`ui-prototype/plumwallpaper-v5.html`

---

## 1. 项目概述

PlumWallPaper 是一款 macOS 离线动态壁纸管理软件，提供专业级色彩调节、多显示器独立管理、智能省电策略等功能。

**核心原则：**
- 代码简洁清爽，避免臃肿
- 低系统资源占用（CPU < 5%，内存 < 150MB）
- 壁纸高渲染质量
- 深色沉浸式 UI（Jewel Edition 风格）

**应用形态：** 标准窗口应用（Dock 图标 + 主窗口），菜单栏常驻做快捷操作，支持开机自启动。

**技术栈：** SwiftUI + AppKit + AVFoundation + Core Image + SwiftData

---

## 2. MVP 功能范围

### 2.1 核心功能（必须实现）

#### 壁纸管理
- ✅ 视频壁纸（MP4/MOV）+ HEIC 动态壁纸双格式支持
- ✅ 壁纸导入（拖拽 + 文件选择器 + 文件夹批量导入）
- ✅ 重复检测（基于文件 hash）
- ✅ 自动生成缩略图（16:9 比例）
- ✅ 收藏功能（心形按钮）
- ✅ 标签管理（用户自定义标签，支持多标签）

#### 首页（HomePage）
- ✅ **Hero 展示区**：
  - 当前选中壁纸全屏背景展示
  - 渐变遮罩（底部 50% 高度，从透明到 `#0d0e12`）
  - 壁纸信息：标签、名称、类型、分辨率、大小、时长
  - 操作按钮：设为壁纸（白底主按钮）、收藏（次按钮）
- ✅ **缩略图条**（Hero 底部）：
  - 横向滚动，支持触控板惯性滚动
  - 支持鼠标拖拽滚动（区分拖拽和点击：位移 > 5px 判定为拖拽）
  - 当前项 100% 不透明 + 白色边框，非当前项 40% 不透明
- ✅ **静态网格区**（Hero 下方）：
  - 分类展示：收藏、最近添加、按标签分组
  - 卡片交互：
    - 左键点击：进入全屏预览页
    - 右键点击：弹出上下文菜单
    - Hover：图片 `scale(1.05)` + 自动播放预览（视频）

#### 壁纸库（LibraryPage）
- ✅ 网格布局展示所有壁纸
- ✅ 顶部筛选区：
  - 标签筛选（全部、收藏、自定义标签）
  - 搜索框（按名称搜索）
  - 排序（按导入时间、名称、最近使用）
- ✅ 卡片信息：缩略图、名称、类型、时长、大小、收藏状态、标签
- ✅ 右键菜单：
  - 设为壁纸
  - 色彩调节
  - 收藏/取消收藏
  - 删除（红色警示，二次确认）

#### 色彩调节页（ColorPage）
- ✅ **预览容器**：
  - 壁纸铺满全屏
  - 实时滤镜预览
  - 支持滤镜链：`hue-rotate` + `saturate` + `brightness` + `contrast` + `blur` + `grayscale` + `invert`
  - 暗角效果（`radial-gradient`）
  - 颗粒效果（SVG `feTurbulence` 噪声）
- ✅ **右侧浮动面板**（360px 宽）：
  - **基础校正组**：曝光度、对比度、饱和度、色调
  - **艺术效果组**：模糊（0-20px）、颗粒感（0-100）、暗角（0-100）
  - **风格转换组**：灰度（0-100%）、反转（0-100%）
  - **预设系统**：胶片、深夜等一键滤镜 + 保存自定义预设
  - **操作按钮**：应用、取消、重置

#### 多显示器支持
- ✅ **显示器选择弹层**（MonitorSelector）：
  - 自动检测显示器数量
  - 单显示器：直接应用
  - 多显示器：弹出选择层
    - 显示每个显示器的名称、分辨率、主副屏标识
    - 显示壁纸预览
    - 选项：为每个显示器单独设置、应用到所有显示器、取消
- ✅ **显示设置页**：
  - 拓扑可视化（显示器相对位置）
  - 拓扑模式：独立显示、镜像、全景拼接
  - 色彩空间：P3 / sRGB / Adobe RGB

#### 设置页（SettingsPage）
- ✅ **轮播设置**：
  - 启用/禁用自动轮播
  - 切换间隔（1-120 分钟）
  - 播放顺序（顺序/随机/收藏优先）
  - 过渡效果（淡入淡出/Ken Burns/无）
- ✅ **性能与省电**：
  - 性能仪表盘（CPU/GPU/Memory 压力百分比）
  - 高级引擎：V-Sync、预解码、Audio Ducking
  - **智能暂停策略**（9 项）：
    - 电池供电时暂停
    - 全屏应用时暂停
    - 遮挡感知（窗口遮挡时暂停）
    - 低电量时暂停（< 20%）
    - 屏幕共享时暂停
    - 合盖模式（笔记本合盖时暂停）
    - 高负载避让（CPU > 80% 时暂停）
    - **应用失去焦点时暂停**
    - 睡眠预停（进入睡眠前停止）
- ✅ **库管理**：
  - 存储饼图（视频/图片/缓存比例）
  - 自动清理（空间阈值报警，如 2GB）
  - 资源库存储路径设置
  - 缓存管理（清理缓存按钮）
- ✅ **快捷键**：
  - 下一张壁纸
  - 上一张壁纸
  - 暂停/继续轮播
  - 收藏当前壁纸
  - 打开主窗口
  - 打开设置
  - KBD 视觉：模拟物理键帽（2px 位移投影 + 内阴影）
- ✅ **外观**：
  - 主题模式（自动/浅色/深色）
  - Accent 颜色配置
  - 缩略图大小
  - 动效开关
- ✅ **关于**：
  - 版本号
  - 更新检查
  - 许可证信息
  - 反馈入口

#### 导入中心（ImportModal）
- ✅ **拖拽区**：
  - 动态边框（悬停时变为 Plum Red）
  - 格式标签：Video, 8K+, HEIC, ProRAW
- ✅ **导入选项**：
  - 批量文件（系统文件选择器）
  - 整包导入（文件夹扫描）
- ✅ **分析状态**：
  - 进度条
  - "请勿关闭应用"风险提示

#### 菜单栏快捷操作
- ✅ 下一张壁纸
- ✅ 上一张壁纸
- ✅ 暂停/继续轮播
- ✅ 打开主窗口
- ✅ 退出应用

### 2.2 不包含（后续迭代）
- ❌ 暗色/亮色模式绑定不同壁纸
- ❌ GIF、Live Photo、粒子特效等其他格式
- ❌ 壁纸导出（调整后的壁纸导出为文件）
- ❌ iCloud 同步
- ❌ 在线壁纸商店

---

## 3. 架构设计

```
PlumWallPaper/
├── App/                        # 应用入口和生命周期
│   ├── PlumWallPaperApp.swift
│   └── AppDelegate.swift
├── UI/                         # 界面层（SwiftUI）
│   ├── Views/
│   │   ├── HomePage/           # 首页（Hero + 缩略图条 + 网格）
│   │   ├── LibraryPage/        # 壁纸库
│   │   ├── ColorPage/          # 色彩调节
│   │   ├── SettingsPage/       # 设置
│   │   ├── PreviewPage/        # 全屏预览
│   │   └── Components/         # 通用组件
│   │       ├── TopNav.swift
│   │       ├── WallpaperCard.swift
│   │       ├── MonitorSelector.swift
│   │       ├── ImportModal.swift
│   │       └── ContextMenu.swift
│   └── MenuBar/                # 菜单栏
├── Core/                       # 核心业务逻辑
│   ├── WallpaperEngine/        # 壁纸渲染引擎
│   │   ├── VideoRenderer.swift
│   │   └── HEICRenderer.swift
│   ├── ColorFilter/            # 色彩滤镜处理
│   │   ├── FilterChain.swift
│   │   └── PresetManager.swift
│   ├── DisplayManager/         # 多显示器管理
│   │   ├── DisplayDetector.swift
│   │   └── TopologyManager.swift
│   ├── Scheduler/              # 轮播调度器
│   │   └── PlaybackScheduler.swift
│   └── PowerManager/           # 省电策略管理
│       └── SmartPauseEngine.swift
├── Storage/                    # 数据持久化
│   ├── Models/
│   │   ├── Wallpaper.swift
│   │   ├── Tag.swift
│   │   ├── FilterPreset.swift
│   │   └── Settings.swift
│   ├── WallpaperStore.swift    # 壁纸索引和元数据
│   └── PreferencesStore.swift  # 用户配置
├── System/                     # 系统集成
│   ├── DesktopBridge.swift     # macOS 桌面壁纸 API 封装
│   └── FileManager+.swift      # 文件管理扩展
└── Resources/                  # 资源文件
    ├── Assets.xcassets
    └── Localizable.strings
```

**关键设计决策：**

1. **WallpaperEngine 独立进程** — 视频解码和渲染放在单独的 XPC Service 中，主应用崩溃不影响壁纸播放
2. **非破坏性色彩调节** — 滤镜参数存 JSON，原文件不动，应用时用 Core Image 实时渲染（GPU 加速）
3. **轻量级存储** — 只存壁纸路径 + 缩略图 + 元数据，不复制原文件
4. **声明式 UI** — 纯 SwiftUI，代码量更少更清爽

---

## 4. 性能优化策略

**目标：CPU < 5%，内存 < 150MB，GPU 硬件加速**

### 视频渲染
- `AVPlayerLayer` 直接渲染到桌面窗口（位于 Dock 图标层下方）
- 启用硬件解码：`AVPlayer` 配置 `preferredVideoDecoderGPURegistryID`
- 视频循环用 `AVPlayerLooper`，避免手动监听播放结束
- 支持 8K 视频无缝循环播放

### HEIC 动态壁纸
- 直接调用 `NSWorkspace.shared.setDesktopImageURL`，系统原生支持

### 色彩滤镜
- Core Image `CIFilter` 链式处理：
  - `CIColorControls`（曝光度、对比度、饱和度）
  - `CITemperatureAndTint`（色温）
  - `CIHueAdjust`（色调）
  - `CIGaussianBlur`（模糊）
  - `CIColorMonochrome`（灰度）
  - `CIColorInvert`（反转）
  - 自定义 `CIFilter` 实现暗角和颗粒效果
- 滤镜应用在 `AVVideoComposition` 上，GPU 实时处理，不落盘

### 多显示器
- 每个屏幕一个独立 `AVPlayer` 实例
- 监听 `NSApplication.didChangeScreenParametersNotification` 处理屏幕插拔

### 缩略图
- 视频：`AVAssetImageGenerator` 提取第 1 秒帧
- HEIC：`CGImageSourceCreateThumbnailAtIndex`
- 缩略图尺寸：300×169（16:9）
- 存储路径：`~/Library/Caches/PlumWallPaper/Thumbnails/`

### 智能暂停
- 监听系统事件：
  - `NSWorkspace.didWakeNotification`（唤醒）
  - `NSWorkspace.willSleepNotification`（睡眠）
  - `NSApplication.didBecomeActiveNotification`（获得焦点）
  - `NSApplication.didResignActiveNotification`（失去焦点）
  - `IOPMCopyBatteryInfo`（电池状态）
  - `NSScreen.screensDidChangeNotification`（屏幕变化）
- 根据策略配置自动暂停/恢复播放

---

## 5. 数据模型

### Wallpaper
```swift
@Model
class Wallpaper {
    var id: UUID
    var name: String
    var filePath: String
    var type: WallpaperType // .video, .heic
    var resolution: String // "3840×2160"
    var fileSize: Int64 // bytes
    var duration: TimeInterval? // 视频时长（秒）
    var thumbnailPath: String
    var tags: [Tag]
    var isFavorite: Bool
    var importDate: Date
    var lastUsedDate: Date?
    var filterPreset: FilterPreset?
}

enum WallpaperType: String, Codable {
    case video
    case heic
}
```

### Tag
```swift
@Model
class Tag {
    var id: UUID
    var name: String
    var color: String? // HEX color
    var wallpapers: [Wallpaper]
}
```

### FilterPreset
```swift
@Model
class FilterPreset {
    var id: UUID
    var name: String
    var exposure: Double // 0-200
    var contrast: Double // 0-200
    var saturation: Double // 0-200
    var hue: Double // -180 to 180
    var blur: Double // 0-20
    var grain: Double // 0-100
    var vignette: Double // 0-100
    var grayscale: Double // 0-100
    var invert: Double // 0-100
}
```

### Settings
```swift
@Model
class Settings {
    // 轮播
    var slideshowEnabled: Bool
    var slideshowInterval: TimeInterval // 秒
    var slideshowOrder: SlideshowOrder // .sequential, .random, .favoritesFirst
    var transitionEffect: TransitionEffect // .fade, .kenBurns, .none
    
    // 性能
    var vSyncEnabled: Bool
    var preDecodeEnabled: Bool
    var audioDuckingEnabled: Bool
    
    // 省电策略
    var pauseOnBattery: Bool
    var pauseOnFullscreen: Bool
    var pauseOnOcclusion: Bool
    var pauseOnLowBattery: Bool
    var pauseOnScreenSharing: Bool
    var pauseOnLidClosed: Bool
    var pauseOnHighLoad: Bool
    var pauseOnLostFocus: Bool
    var pauseBeforeSleep: Bool
    
    // 显示
    var displayTopology: DisplayTopology // .independent, .mirror, .panorama
    var colorSpace: ColorSpace // .p3, .srgb, .adobeRGB
    
    // 库管理
    var libraryPath: String
    var cacheThreshold: Int64 // bytes
    var autoCleanEnabled: Bool
    
    // 外观
    var themeMode: ThemeMode // .auto, .light, .dark
    var accentColor: String // HEX
    var thumbnailSize: ThumbnailSize // .small, .medium, .large
    var animationsEnabled: Bool
}
```

---

## 6. UI 视觉规范（基于 v5 原型）

### 6.1 颜色系统
```swift
// CSS Variables 映射到 SwiftUI
struct AppColors {
    static let bg = Color(hex: "#0d0e12")
    static let fg = Color.white
    static let accent = Color(hex: "#E03E3E")
    static let glass = Color.white.opacity(0.04)
    static let glassHeavy = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.1)
}
```

### 6.2 字体系统
```swift
struct AppFonts {
    // Display: Cormorant Garamond (衬线，用于标题)
    static func display(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        .custom("Cormorant Garamond", size: size)
            .weight(weight)
            .italic(italic ? .init() : nil)
    }
    
    // UI: Inter (无衬线，用于正文和 UI)
    static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }
}
```

### 6.3 动画规范
```swift
struct AppAnimations {
    static let fadeIn = Animation.easeOut(duration: 0.6)
    static let hover = Animation.easeInOut(duration: 0.2)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
}
```

### 6.4 组件规范
- **按钮**：8px padding, 8px 圆角, 1px 边框
- **主按钮**：白底黑字，hover 变红底白字
- **次按钮**：半透明底，hover 变亮 + `translateY(-1px)`
- **卡片**：16:9 比例，12-16px 圆角，hover 时 `scale(1.05)`
- **模态框**：24px 圆角，40px 阴影，毛玻璃背景

---

## 7. MVP 验收标准

### 功能验收
1. ✅ 支持 MP4/MOV/HEIC 格式导入
2. ✅ 支持 8K 视频无缝循环播放（60fps）
3. ✅ Hero 缩略图拖拽不掉帧
4. ✅ 多显示器选择弹层正确显示所有显示器
5. ✅ 色彩调节实时预览无延迟
6. ✅ 智能暂停策略在模拟场景下正确触发
7. ✅ 右键菜单所有选项功能正常
8. ✅ 搜索和排序功能正常
9. ✅ 收藏和标签功能正常
10. ✅ 菜单栏快捷操作正常

### 性能验收
1. ✅ CPU 占用 < 5%（播放 4K 视频）
2. ✅ 内存占用 < 150MB（库内 100 个壁纸）
3. ✅ GPU 硬件加速正常工作
4. ✅ 应用启动时间 < 2 秒
5. ✅ 壁纸切换延迟 < 500ms

### UI 验收
1. ✅ 所有页面符合 v5 原型视觉规范
2. ✅ 动画流畅（60fps）
3. ✅ 响应式布局适配不同窗口尺寸
4. ✅ 无滚动条但保留滚动功能
5. ✅ 所有交互有明确反馈

---

## 8. 实施计划

### Phase 1: 基础架构（1-2 周）
- [ ] 项目初始化（Xcode 项目 + SwiftData 配置）
- [ ] 数据模型定义
- [ ] 文件管理和存储层
- [ ] 基础 UI 框架（TopNav + 路由）

### Phase 2: 壁纸管理（1-2 周）
- [ ] 壁纸导入（拖拽 + 文件选择器）
- [ ] 缩略图生成
- [ ] 壁纸库网格布局
- [ ] 搜索和排序
- [ ] 收藏和标签

### Phase 3: 渲染引擎（2-3 周）
- [ ] 视频渲染（AVPlayer + AVPlayerLayer）
- [ ] HEIC 渲染
- [ ] 多显示器支持
- [ ] 显示器选择弹层
- [ ] 桌面壁纸 API 集成

### Phase 4: 色彩调节（1-2 周）
- [ ] Core Image 滤镜链
- [ ] 色彩调节面板 UI
- [ ] 实时预览
- [ ] 预设系统
- [ ] 暗角和颗粒效果

### Phase 5: 高级功能（1-2 周）
- [ ] 轮播调度器
- [ ] 智能暂停策略
- [ ] 性能监控
- [ ] 设置页完整实现
- [ ] 菜单栏快捷操作

### Phase 6: 优化和测试（1 周）
- [ ] 性能优化
- [ ] 内存泄漏检测
- [ ] UI 细节打磨
- [ ] 全功能测试
- [ ] Bug 修复

**总计：7-11 周**

---

## 9. 技术风险和缓解

### 风险 1：8K 视频性能
- **风险**：8K 视频解码可能导致 CPU/GPU 过载
- **缓解**：
  - 强制硬件解码
  - 降低播放帧率（30fps）
  - 提供"性能模式"降低分辨率

### 风险 2：多显示器同步
- **风险**：多个 AVPlayer 实例可能不同步
- **缓解**：
  - 使用 `AVPlayerItemVideoOutput` 手动同步
  - 或接受轻微不同步（< 100ms）

### 风险 3：色彩滤镜性能
- **风险**：复杂滤镜链可能导致实时预览卡顿
- **缓解**：
  - 限制滤镜数量
  - 使用 Metal 自定义着色器优化
  - 提供"预览质量"选项

### 风险 4：系统权限
- **风险**：macOS 可能限制桌面壁纸 API 访问
- **缓解**：
  - 申请必要权限（屏幕录制、辅助功能）
  - 提供清晰的权限引导

---

## 10. 后续迭代方向

### v1.1
- 暗色/亮色模式绑定不同壁纸
- 壁纸导出功能
- 更多滤镜预设

### v1.2
- GIF 支持
- Live Photo 支持
- 粒子特效

### v2.0
- iCloud 同步
- 在线壁纸商店
- 社区分享

---

## 附录：参考文档

- **原型文件**：`ui-prototype/plumwallpaper-v5.html`
- **技术规格**：`docs/superpowers/specs/2026-04-28-plumwallpaper-v5-final-spec.md`
- **原 MVP**：`docs/superpowers/specs/2026-04-27-plumwallpaper-mvp-design.md`
