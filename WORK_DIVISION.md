# PlumWallPaper 前后端工作划分

## 前端工作（Gemini 负责）

### 1. 补全剩余视图组件
- [ ] **SettingsView.swift** - 完整实现
  - 集成 `@Query` 获取 Settings 模型
  - 绑定所有设置项到数据模型
  - 实现双栏布局和所有交互
  
- [ ] **ColorAdjustView.swift** - 完整实现
  - 集成 FilterPreset 模型
  - 绑定所有滑块到数据
  - 实现预设保存和加载
  - 实现应用/取消/重置逻辑

- [ ] **LibraryView.swift** - 完整实现（当前是占位）
  - 网格布局展示壁纸
  - 搜索和筛选 UI
  - 排序选项
  - 右键菜单

### 2. 创建通用组件
- [ ] **MonitorSelectorView.swift** - 多显示器选择弹层
  - 显示所有显示器
  - 选择交互
  - 应用/取消按钮
  
- [ ] **ImportModalView.swift** - 导入中心弹层
  - 拖拽区域
  - 文件选择按钮
  - 进度显示
  
- [ ] **ContextMenuView.swift** - 右键菜单
  - 设为壁纸
  - 色彩调节
  - 收藏/取消收藏
  - 删除

- [ ] **WallpaperDetailView.swift** - 全屏预览页
  - 全屏壁纸展示
  - 关闭按钮

### 3. 数据绑定和状态管理
- [ ] 在所有视图中使用 `@Query` 获取数据
- [ ] 使用 `@Environment(\.modelContext)` 进行数据操作
- [ ] 实现视图间的状态传递（通过 `@Binding` 或 `@State`）

### 4. UI 交互完善
- [ ] 所有按钮的点击事件
- [ ] 所有输入框的数据绑定
- [ ] 所有动画和过渡效果
- [ ] Hover 状态和反馈

### 5. 视觉细节打磨
- [ ] 确保所有间距符合设计规范
- [ ] 确保字体正确应用（Cormorant Garamond + Inter）
- [ ] 确保颜色使用 Theme 定义
- [ ] 确保动画流畅（60fps）

---

## 后端工作（我负责）

### 1. 渲染引擎完善
- [ ] **VideoRenderer** 完整实现
  - AVPlayer 配置
  - 硬件解码设置
  - 桌面窗口创建和管理
  - 循环播放逻辑
  - 性能优化

- [ ] **HEICRenderer** 完善
  - 系统 API 调用
  - 错误处理

### 2. 色彩滤镜系统
- [ ] **FilterEngine.swift** - 滤镜引擎
  - Core Image 滤镜链构建
  - AVVideoComposition 集成
  - 实时预览支持
  - GPU 加速

- [ ] **FilterPresetManager.swift** - 预设管理器
  - 预设加载
  - 预设保存
  - 预设应用

### 3. 多显示器管理
- [ ] **DisplayManager.swift** - 显示器管理器
  - 显示器检测
  - 显示器信息获取
  - 屏幕插拔监听
  - 拓扑管理

- [ ] **DisplayRenderer.swift** - 显示器渲染器
  - 为每个显示器创建独立渲染器
  - 渲染器生命周期管理

### 4. 文件导入系统
- [ ] **FileImporter.swift** - 文件导入器
  - 文件选择器集成
  - 拖拽处理
  - 文件验证（格式、大小）
  - 批量导入

- [ ] **ThumbnailGenerator.swift** - 缩略图生成器
  - 视频缩略图提取（AVAssetImageGenerator）
  - HEIC 缩略图生成
  - 缩存管理

- [ ] **FileHasher.swift** - 文件哈希计算
  - SHA256 哈希计算
  - 重复检测

### 5. 轮播调度器
- [ ] **PlaybackScheduler.swift** - 轮播调度器
  - 定时器管理
  - 顺序/随机/收藏优先逻辑
  - 过渡效果控制

### 6. 智能省电策略
- [ ] **PowerManager.swift** - 省电管理器
  - 系统事件监听
    - 电池状态
    - 全屏应用检测
    - 窗口遮挡检测
    - 应用焦点状态
    - 屏幕共享检测
    - 合盖检测
    - CPU 负载监控
    - 睡眠/唤醒
  - 自动暂停/恢复逻辑

### 7. 系统集成
- [ ] **DesktopBridge.swift** 完善
  - 桌面窗口层级管理
  - 壁纸设置 API 封装
  - 错误处理

- [ ] **MenuBarManager.swift** - 菜单栏管理
  - 菜单栏图标
  - 快捷操作菜单
  - 状态更新

### 8. 数据层完善
- [ ] **WallpaperStore.swift** 增强
  - 添加更多查询方法
  - 批量操作优化
  - 事务处理

- [ ] **CacheManager.swift** - 缓存管理
  - 缓存大小监控
  - 自动清理
  - 缓存策略

### 9. 性能优化
- [ ] 内存管理
- [ ] CPU 占用优化
- [ ] GPU 加速验证
- [ ] 启动时间优化

### 10. 错误处理和日志
- [ ] 统一错误处理机制
- [ ] 日志系统
- [ ] 崩溃报告

---

## 接口约定（前后端协作）

### 1. 数据模型（已定义）
前端通过 SwiftData 的 `@Query` 和 `@Environment(\.modelContext)` 直接访问：
- `Wallpaper`
- `Tag`
- `FilterPreset`
- `Settings`

### 2. 前端调用后端的方法

#### 设置壁纸
```swift
// 前端调用
WallpaperEngine.shared.setWallpaper(wallpaper, for: screen)

// 后端实现
class WallpaperEngine {
    func setWallpaper(_ wallpaper: Wallpaper, for screen: NSScreen)
}
```

#### 应用滤镜
```swift
// 前端调用
FilterEngine.shared.applyFilter(preset, to: wallpaper)

// 后端实现
class FilterEngine {
    func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper)
}
```

#### 导入文件
```swift
// 前端调用
FileImporter.shared.importFiles(urls: [URL])

// 后端实现
class FileImporter {
    func importFiles(urls: [URL]) async throws -> [Wallpaper]
}
```

#### 获取显示器列表
```swift
// 前端调用
let screens = DisplayManager.shared.availableScreens

// 后端实现
class DisplayManager {
    var availableScreens: [ScreenInfo]
}
```

### 3. 后端通知前端的事件

使用 Combine 或 NotificationCenter：

```swift
// 导入进度通知
NotificationCenter.default.post(
    name: .importProgress,
    object: nil,
    userInfo: ["progress": 0.5]
)

// 渲染状态变化
NotificationCenter.default.post(
    name: .renderingStateChanged,
    object: nil,
    userInfo: ["isPlaying": true]
)
```

---

## 工作流程

### Phase 1: 前端完善（Gemini）
1. 补全所有视图组件
2. 实现所有数据绑定
3. 完善所有交互逻辑
4. 视觉细节打磨

**交付物**：
- 所有 SwiftUI 视图文件
- 完整的 UI 交互
- 数据绑定代码

### Phase 2: 后端核心功能（我）
1. 渲染引擎
2. 色彩滤镜
3. 多显示器管理
4. 文件导入

**交付物**：
- 完整的渲染引擎
- 滤镜系统
- 显示器管理
- 文件导入系统

### Phase 3: 前后端联调
1. 集成渲染引擎到 UI
2. 集成滤镜系统到色彩调节页
3. 集成文件导入到导入弹层
4. 集成显示器管理到选择弹层

### Phase 4: 高级功能（我）
1. 轮播调度器
2. 智能省电策略
3. 菜单栏管理
4. 性能优化

### Phase 5: 测试和优化
1. 功能测试
2. 性能测试
3. UI 细节打磨
4. Bug 修复

---

## 当前状态

### 已完成
- ✅ 数据模型定义
- ✅ 存储层实现
- ✅ 应用入口和 SwiftData 配置
- ✅ Theme.swift
- ✅ HomeView.swift（基础版）
- ✅ PlumWallPaperApp.swift

### 进行中
- 🔄 前端视图补全（Gemini）
- 🔄 后端渲染引擎（我）

### 待开始
- ⏳ 色彩滤镜系统
- ⏳ 多显示器管理
- ⏳ 文件导入系统
- ⏳ 轮播调度器
- ⏳ 智能省电策略
