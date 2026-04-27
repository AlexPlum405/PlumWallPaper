# PlumWallPaper MVP 闭环 + FilterEngine + 启动恢复 设计文档

日期：2026-04-28
状态：已确认，待实现

## 目标

完成 PlumWallPaper 的第一条完整闭环：

1. **导入** — 用户从 ImportModalView 选择/拖拽文件，文件被 FileImporter 真实处理后写入 SwiftData
2. **展示** — HomeView 和 LibraryView 通过 SwiftData @Query 自动展示新导入的壁纸
3. **设为壁纸** — 单击 "设为壁纸" 后，根据显示器数量智能弹出 MonitorSelectorView 或直接应用
4. **滤镜调节** — ColorAdjustView 的 9 个调色参数通过 FilterEngine 真实作用于视频/HEIC 壁纸
5. **启动恢复** — 应用重启后自动恢复每个显示器上次使用的壁纸

## 关键决策

| 议题 | 选择 |
|---|---|
| 重复文件处理 | 用户确认后自动加 `(2)` 后缀 |
| "设为壁纸" 多屏处理 | 智能判断：单屏直接设，多屏弹 MonitorSelectorView |
| FilterEngine 范围 | 9 参数全量（曝光、对比度、饱和度、色调、模糊、颗粒、暗角、黑白、反转） |
| 滤镜应用方式 | 参数持久化 + 渲染时 AVVideoComposition 实时应用 |
| 目录唯一真源 | `PlumWallPaper/Sources/*` |
| 本轮范围 | 核心闭环 + FilterEngine + 启动恢复 |
| 启动恢复语义 | 每屏独立恢复，显示器消失则忽略 |
| 架构方式 | AppViewModel 中介层（@Observable） |

## 目录结构

收敛后唯一真源：

```
PlumWallPaper/Sources/
├── App/
│   └── PlumWallPaperApp.swift      # 入口 + MainView + 导航组件
├── Core/
│   ├── DisplayManager/
│   │   └── DisplayManager.swift
│   ├── WallpaperEngine/
│   │   ├── WallpaperEngine.swift
│   │   ├── BasicVideoRenderer.swift
│   │   └── HEICRenderer.swift
│   ├── FilterEngine.swift           # 新增
│   ├── FileImporter.swift
│   ├── ThumbnailGenerator.swift
│   └── RestoreManager.swift         # 新增
├── Storage/
│   ├── WallpaperStore.swift
│   └── PreferencesStore.swift
├── System/
│   └── DesktopBridge.swift
├── UI/
│   ├── Theme.swift
│   ├── AppViewModel.swift           # 新增
│   └── Views/
│       ├── HomeView.swift
│       ├── LibraryView.swift
│       ├── ImportModalView.swift
│       ├── MonitorSelectorView.swift
│       ├── ColorAdjustView.swift
│       ├── SettingsView.swift
│       └── WallpaperDetailView.swift
└── Resources/
```

迁移操作：
- 把根目录 `Sources/UI/Views/*.swift` 全部移入 `PlumWallPaper/Sources/UI/Views/`
- 删除 `PlumWallPaper/Sources/App/PlumWallPaperApp.swift` 末尾的占位 `LibraryView`
- 删除根目录 `Sources/` 整个目录

## AppViewModel 设计

中介层，挂到 SwiftUI Environment，所有视图通过 `@Environment` 获取。

```swift
@Observable @MainActor
final class AppViewModel {
    // 后端引用
    let engine = WallpaperEngine.shared
    let display = DisplayManager.shared
    let importer = FileImporter.shared
    let filter = FilterEngine.shared
    let restore = RestoreManager.shared

    // 导入状态（驱动 ImportModalView 进度环）
    var isImporting = false
    var importProgress: Double = 0
    var currentImportFileName = ""

    // 重复确认（驱动 ImportModalView 弹层）
    var pendingDuplicates: [URL] = []
    var duplicateConfirmHandler: (([URL]) -> Void)?

    // 壁纸状态
    var activeWallpaperPerScreen: [String: Wallpaper] = [:]

    // 多屏选择信号
    var monitorSelectorRequest: Wallpaper? = nil

    // MARK: 接口
    func importFiles(urls: [URL], context: ModelContext) async
    func confirmDuplicates(_ urls: [URL], context: ModelContext) async
    func smartSetWallpaper(_ wallpaper: Wallpaper)
    func setWallpaper(_ wallpaper: Wallpaper, for screen: ScreenInfo)
    func setWallpaperToAll(_ wallpaper: Wallpaper)
    func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper)
    func restoreLastSession(context: ModelContext) async
}
```

注入：

```swift
@main
struct PlumWallPaperApp: App {
    let modelContainer: ModelContainer
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(viewModel)
                .modelContainer(modelContainer)
                .task { await viewModel.restoreLastSession(context: modelContainer.mainContext) }
        }
    }
}
```

## 4 条数据链路

### 1. 导入链路

```
ImportModalView
  └─ NSOpenPanel / DropDelegate
      └─ AppViewModel.importFiles(urls:)
          ├─ 对每个 URL 调 FileImporter.importFile
          │   └─ 提取 type / resolution / duration / hash / thumbnail
          ├─ WallpaperStore.wallpaperExists(fileHash:)
          │   ├─ 不重复 → 直接 insert
          │   └─ 重复 → 加入 pendingDuplicates，触发用户确认
          └─ 用户确认后：生成唯一名 "Name (2)" → insert
              └─ SwiftData @Query 自动驱动 HomeView/LibraryView 刷新
```

唯一名规则：从 `name` 开始，递增后缀 `(2)`、`(3)`...，直到 `WallpaperStore` 中不存在同名记录。

### 2. 设壁纸链路

```
HomeView "设为壁纸" 按钮
  └─ AppViewModel.smartSetWallpaper(wallpaper)
      ├─ display.availableScreens.count == 1
      │   └─ engine.setWallpaper(wallpaper, for: 主屏)
      └─ count > 1
          └─ monitorSelectorRequest = wallpaper
              └─ MainView 监听 monitorSelectorRequest，弹 MonitorSelectorView
                  └─ 用户选择后调 AppViewModel.setWallpaper / setWallpaperToAll
                      └─ 调用 WallpaperEngine
                      └─ 更新 activeWallpaperPerScreen
                      └─ RestoreManager.saveSession
```

### 3. 滤镜链路

```
ColorAdjustView
  ├─ 9 个 @State 滑块 → 实时驱动 SwiftUI modifier 预览（保留现有行为）
  └─ "应用修改" 按钮
      └─ 写入 FilterPreset → wallpaper.filterPreset
          └─ AppViewModel.applyFilter(preset, to: wallpaper)
              └─ FilterEngine.videoComposition(for: asset, preset:)
              └─ BasicVideoRenderer 重新挂载 videoComposition
              └─ HEICRenderer 重新合成图像并刷新桌面
```

### 4. 启动恢复链路

```
PlumWallPaperApp.task
  └─ AppViewModel.restoreLastSession(context:)
      └─ RestoreManager.restoreSession(context:, displayManager:, wallpaperEngine:)
          ├─ 读 UserDefaults["activeWallpaperMapping"]: [screenID: PersistentIdentifier]
          └─ 遍历 displayManager.availableScreens
              ├─ screenID 不在映射中 → 跳过
              ├─ 在映射中 → 用 PersistentIdentifier 查 SwiftData
              │   ├─ 查到 → engine.setWallpaper
              │   └─ 查不到 → 跳过（壁纸已删除）
```

## FilterEngine 设计

```swift
final class FilterEngine {
    static let shared = FilterEngine()

    func videoComposition(for asset: AVAsset, preset: FilterPreset) -> AVVideoComposition
    func applyToImage(at url: URL, preset: FilterPreset) -> NSImage?
    func compositeCIImage(_ input: CIImage, preset: FilterPreset) -> CIImage
}
```

参数 → CIFilter 映射：

| 参数 | CIFilter | 关键属性 |
|---|---|---|
| 曝光度 (0..200, 默认 100) | CIExposureAdjust | inputEV = (value - 100) / 50 |
| 对比度 (0..200) | CIColorControls | inputContrast = value / 100 |
| 饱和度 (0..200) | CIColorControls | inputSaturation = (value/100) * (1 - grayscale/100) |
| 色调 (-180..180) | CIHueAdjust | inputAngle = value × π / 180 |
| 模糊 (0..20) | CIGaussianBlur | inputRadius = value |
| 颗粒感 (0..100) | CIRandomGenerator + CISourceOverCompositing | alpha = value / 100 |
| 暗角 (0..100) | CIVignette | inputIntensity = value / 100 |
| 黑白 (0..100) | 与饱和度合并 | 见上 |
| 反转 (0..100) | CIColorInvert | value > 50 时启用 |

实现要点：
- `CIColorControls` 一次性承载对比度、饱和度、黑白
- 视频用 `AVVideoComposition(asset:applyingCIFiltersWithHandler:)`，GPU 加速
- 模糊后必须用 `imageByClampingToExtent` 防止边缘出现透明
- 颗粒感的 CIRandomGenerator 输出无限大，需 `cropped(to: input.extent)`
- BasicVideoRenderer 重新挂载 composition 时不要重建 player，只替换 `playerItem.videoComposition`

## RestoreManager 设计

```swift
final class RestoreManager {
    static let shared = RestoreManager()
    private let key = "activeWallpaperMapping"

    func saveSession(mapping: [String: PersistentIdentifier])
    func loadSession() -> [String: PersistentIdentifier]
    func restoreSession(
        context: ModelContext,
        displayManager: DisplayManager,
        wallpaperEngine: WallpaperEngine
    ) async
}
```

持久化格式：
- `UserDefaults` key：`activeWallpaperMapping`
- 值：`Data`（PropertyListEncoder 编码的 `[String: Data]`，每个 value 是 `PersistentIdentifier` 编码后的 Data）
- 使用 `PersistentIdentifier` 而非 UUID，确保 SwiftData 重启后仍可定位

行为：
- 显示器不存在 → 跳过该条
- 壁纸记录不存在（用户已删除） → 跳过该条
- 任何异常 → 不抛出，仅日志记录，不阻塞启动

## 错误处理

| 场景 | 行为 |
|---|---|
| 文件不可读 | 跳过该文件，继续导入其它，最后汇总提示 |
| 缩略图生成失败 | 使用占位缩略图，仍然写入 SwiftData |
| 显示器在设壁纸瞬间被拔掉 | WallpaperEngine 内部静默忽略 |
| FilterEngine 滤镜应用失败 | 回退到无滤镜状态，记录日志 |
| 启动恢复任何环节失败 | 跳过，不阻塞应用启动 |

## 测试策略

MVP 阶段以手动验证为主：

1. 导入 1 个新文件 → 出现在 Library
2. 重复导入相同文件 → 弹确认，确认后名称变成 `(2)`
3. 单屏点 "设为壁纸" → 桌面立刻变化
4. 多屏点 "设为壁纸" → 弹 MonitorSelectorView
5. 调色 → 应用 → 桌面壁纸真实变化
6. 重启应用 → 上次的壁纸自动恢复

## 不在本轮范围

- 设置开机自启
- 偏好系统的完整持久化
- FilterEngine 的预设系统（仅做 Custom）
- 视频音频处理
- 视频缓存优化
- 显示器拔插时的自动迁移
