# Gemini 前端任务清单

## 背景
PlumWallPaper 的后端数据模型和存储层已经完成，现在需要你完成所有前端 SwiftUI 视图的实现和数据绑定。

## 已有的基础设施

### 数据模型（SwiftData）
```swift
@Model class Wallpaper {
    var id: UUID
    var name: String
    var filePath: String
    var type: WallpaperType // .video, .heic
    var resolution: String
    var fileSize: Int64
    var duration: TimeInterval?
    var thumbnailPath: String
    var tags: [Tag]
    var isFavorite: Bool
    var importDate: Date
    var lastUsedDate: Date?
    var filterPreset: FilterPreset?
    var fileHash: String
}

@Model class Tag {
    var id: UUID
    var name: String
    var color: String?
    var wallpapers: [Wallpaper]
}

@Model class FilterPreset {
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

@Model class Settings {
    // 轮播
    var slideshowEnabled: Bool
    var slideshowInterval: TimeInterval
    var slideshowOrder: SlideshowOrder
    var transitionEffect: TransitionEffect
    
    // 性能
    var vSyncEnabled: Bool
    var preDecodeEnabled: Bool
    var audioDuckingEnabled: Bool
    
    // 省电策略（9项）
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
    var displayTopology: DisplayTopology
    var colorSpace: ColorSpace
    
    // 库管理
    var libraryPath: String
    var cacheThreshold: Int64
    var autoCleanEnabled: Bool
    
    // 外观
    var themeMode: ThemeMode
    var accentColor: String
    var thumbnailSize: ThumbnailSize
    var animationsEnabled: Bool
}
```

### 已完成的视图
- ✅ `Theme.swift` - 视觉规范
- ✅ `PlumWallPaperApp.swift` - 应用入口（已集成 SwiftData）
- ✅ `HomeView.swift` - 首页（已有基础数据绑定）

---

## 任务 1: 完善 SettingsView.swift

### 要求
1. **数据绑定**：使用 `@Query` 获取 Settings 模型
   ```swift
   @Query private var settings: [Settings]
   var currentSettings: Settings? { settings.first }
   ```

2. **实现所有设置项**：
   - 轮播设置（启用、间隔、顺序、过渡效果）
   - 性能设置（V-Sync、预解码、Audio Ducking）
   - 智能暂停策略（9 个开关）
   - 显示设置（拓扑模式、色彩空间）
   - 库管理（路径、缓存阈值、自动清理）
   - 外观（主题、Accent 颜色、缩略图大小、动画）
   - 快捷键（展示，暂不实现编辑）
   - 关于（版本号、更新检查）

3. **双栏布局**：保持你之前的设计
   - 左侧 Sidebar 导航
   - 右侧详情区域
   - 140px 垂直基准线对齐

4. **数据持久化**：所有修改通过 `modelContext.save()` 保存

### 参考代码结构
```swift
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    
    var currentSettings: Settings? { settings.first }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
        } detail: {
            // Detail view with all settings
        }
        .onAppear {
            // 如果没有设置，创建默认设置
            if settings.isEmpty {
                let defaultSettings = Settings()
                modelContext.insert(defaultSettings)
                try? modelContext.save()
            }
        }
    }
}
```

---

## 任务 2: 完善 ColorAdjustView.swift

### 要求
1. **接收参数**：接收要调节的 Wallpaper
   ```swift
   struct ColorAdjustView: View {
       let wallpaper: Wallpaper
       @Environment(\.dismiss) var dismiss
       @Environment(\.modelContext) private var modelContext
   }
   ```

2. **滤镜参数绑定**：
   - 如果 wallpaper 已有 filterPreset，加载它
   - 否则创建临时 FilterPreset
   - 所有滑块绑定到 FilterPreset 的属性

3. **实时预览**：
   - 滑块变化时，通过 `@State` 更新预览
   - 后端会处理实际的滤镜渲染

4. **预设系统**：
   - 显示预设列表（胶片、深夜、复古等）
   - 点击预设加载参数
   - "保存当前"按钮创建新预设

5. **操作按钮**：
   - **应用**：保存 FilterPreset 到 wallpaper，调用后端应用滤镜
   - **取消**：丢弃修改，关闭视图
   - **重置**：恢复默认值（所有参数归零）

### 参考代码结构
```swift
struct ColorAdjustView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var exposure: Double
    @State private var contrast: Double
    // ... 其他滤镜参数
    
    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
        // 初始化参数
        if let preset = wallpaper.filterPreset {
            _exposure = State(initialValue: preset.exposure)
            // ...
        } else {
            _exposure = State(initialValue: 100)
            // ...
        }
    }
    
    var body: some View {
        // 你之前的布局
    }
    
    func applyFilter() {
        // 创建或更新 FilterPreset
        let preset = wallpaper.filterPreset ?? FilterPreset(name: "Custom")
        preset.exposure = exposure
        preset.contrast = contrast
        // ...
        
        wallpaper.filterPreset = preset
        try? modelContext.save()
        
        // TODO: 调用后端应用滤镜（后续集成）
        // FilterEngine.shared.applyFilter(preset, to: wallpaper)
        
        dismiss()
    }
}
```

---

## 任务 3: 完善 LibraryView.swift

### 要求
1. **数据查询**：
   ```swift
   @Query(sort: \Wallpaper.importDate, order: .reverse) 
   private var allWallpapers: [Wallpaper]
   
   @Query private var tags: [Tag]
   ```

2. **筛选和搜索**：
   - 顶部筛选栏：全部、收藏、按标签
   - 搜索框：实时搜索壁纸名称
   - 排序：按导入时间、名称、最近使用

3. **网格布局**：
   - 使用 `LazyVGrid`
   - 自适应列宽（最小 320px）
   - 显示缩略图、名称、类型、大小等信息

4. **右键菜单**：
   - 设为壁纸
   - 色彩调节
   - 收藏/取消收藏
   - 删除

### 参考代码结构
```swift
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallpaper.importDate, order: .reverse) 
    private var allWallpapers: [Wallpaper]
    
    @State private var searchText = ""
    @State private var selectedTag: Tag?
    @State private var sortOrder: SortOrder = .importDate
    
    var filteredWallpapers: [Wallpaper] {
        // 实现筛选逻辑
    }
    
    var body: some View {
        VStack {
            // 筛选栏
            // 网格
        }
    }
}
```

---

## 任务 4: 创建 MonitorSelectorView.swift

### 要求
这是一个弹层，用于选择将壁纸应用到哪个显示器。

1. **接收参数**：
   ```swift
   struct MonitorSelectorView: View {
       let wallpaper: Wallpaper
       let screens: [ScreenInfo] // 后端提供
       @Environment(\.dismiss) var dismiss
   }
   ```

2. **显示所有显示器**：
   - 网格布局展示所有显示器
   - 每个显示器显示：名称、分辨率、主副屏标识
   - 显示壁纸预览

3. **选择交互**：
   - 单选某个显示器
   - "应用到所有显示器"按钮
   - "取消"按钮

4. **应用逻辑**：
   ```swift
   func applyToScreen(_ screen: ScreenInfo) {
       // TODO: 调用后端设置壁纸
       // WallpaperEngine.shared.setWallpaper(wallpaper, for: screen)
       dismiss()
   }
   ```

---

## 任务 5: 创建 ImportModalView.swift

### 要求
导入中心弹层。

1. **拖拽区域**：
   - 支持文件拖拽
   - 显示支持的格式（MP4, MOV, HEIC）

2. **文件选择按钮**：
   - "选择文件"按钮
   - "选择文件夹"按钮

3. **进度显示**：
   - 导入进度条
   - 当前处理的文件名
   - "请勿关闭应用"提示

4. **导入逻辑**：
   ```swift
   func importFiles(_ urls: [URL]) {
       // TODO: 调用后端导入
       // Task {
       //     let wallpapers = try await FileImporter.shared.importFiles(urls: urls)
       //     // 更新 UI
       // }
   }
   ```

---

## 任务 6: 创建 WallpaperDetailView.swift

### 要求
全屏预览页。

1. **全屏展示壁纸**
2. **关闭按钮**（左上角）
3. **可选：显示壁纸信息**（名称、分辨率等）

---

## 交付要求

### 文件结构
```
PlumWallPaper/Sources/UI/
├── Theme.swift                     ✅ 已有
├── Views/
│   ├── HomeView.swift              ✅ 已有
│   ├── SettingsView.swift          ⏳ 待完善
│   ├── ColorAdjustView.swift       ⏳ 待完善
│   ├── LibraryView.swift           ⏳ 待创建
│   ├── MonitorSelectorView.swift   ⏳ 待创建
│   ├── ImportModalView.swift       ⏳ 待创建
│   └── WallpaperDetailView.swift   ⏳ 待创建
└── Components/
    └── (可选的通用组件)
```

### 代码规范
1. 所有视图使用 `@Query` 获取数据
2. 所有修改通过 `modelContext.save()` 保存
3. 使用 `Theme` 定义的颜色和字体
4. 保持你之前的视觉风格和动画
5. 添加必要的注释

### 测试要点
1. 数据绑定正确
2. 所有交互有反馈
3. 动画流畅
4. 布局响应式

---

## 注意事项

1. **后端接口暂时用 TODO 注释**：
   ```swift
   // TODO: 调用后端 API
   // WallpaperEngine.shared.setWallpaper(...)
   ```
   后续我会实现这些后端接口并集成。

2. **Mock 数据**：
   如果需要测试，可以在 `onAppear` 中创建 mock 数据。

3. **错误处理**：
   暂时可以简单处理，后续会统一错误处理机制。

---

## 完成后
把所有文件的完整代码发给我，我会：
1. 集成到项目中
2. 实现后端接口
3. 连接前后端
4. 测试完整流程
