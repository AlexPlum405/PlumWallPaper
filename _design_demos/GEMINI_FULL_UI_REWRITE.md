# Gemini - 全面 UI 重构指令

**忽略之前所有的阶段划分，这是一份全新的、完整的 UI 重构任务。**

## 核心目标

PlumWallPaper 和 WaifuX 是同类产品（macOS 壁纸应用），功能高度重合。你的任务是：**在 Plum 架构下，高保真复刻 WaifuX 的全部 UI**，只做以下调整：
- 移除动漫相关功能（AnimeExplore、AnimeDetail、AnimePlayer、弹幕）
- 着色器编辑器不放在顶部 Tab，而是作为壁纸详情页的子功能
- 设置页内容适配 Plum 的功能（暂停策略、性能监控等）

---

## Tab 结构对比

```
WaifuX 的 Tab：  首页 | 壁纸 | 媒体 | 动漫 | 我的
Plum 的 Tab：    首页 | 壁纸 | 媒体 | 我的
```

只少了"动漫"这一个 Tab，其余完全一致。

**修改 `MainTab` 枚举**：
```swift
enum MainTab: String, CaseIterable {
    case home           // 首页
    case wallpaper      // 壁纸（静态壁纸探索）
    case media          // 媒体（动态壁纸探索）
    case myLibrary      // 我的（收藏/下载/历史）

    var title: String {
        switch self {
        case .home: return "首页"
        case .wallpaper: return "壁纸"
        case .media: return "媒体"
        case .myLibrary: return "我的"
        }
    }
}
```

---

## 每个页面的实现要求

### 1. 首页（HomeView）— 对标 WaifuX 首页

**参考文件**：`/Users/Alex/AI/project/WaifuX/Views/HomeContentView.swift`

**必须包含**：
- **Hero 轮播区**：全宽大图，占屏幕上半部分（约 50-60% 高度）
  - 图片上叠加底部渐变遮罩（渐变到背景色）
  - 左下角：分类标签 + 大号衬线体标题 + "查看壁纸"按钮
  - 左右箭头切换 + 底部圆点指示器
  - 用 3-5 张不同渐变色块模拟轮播内容，每张配 mock 标题
- **"最新壁纸"分区**：标题 + ">" 箭头 + 横向滚动卡片列表
- **"热门动态壁纸"分区**：同上结构
- 整体可垂直滚动

**创建文件**：`Sources/Views/Home/HomeView.swift`

### 2. 壁纸探索页（WallpaperExploreView）— 对标 WaifuX 壁纸页

**参考文件**：`/Users/Alex/AI/project/WaifuX/Views/WallpaperExploreContentView.swift`

**必须包含**：
- 顶部筛选芯片栏（分类、纯度、排序）
- 壁纸网格（LazyVGrid，3-4 列）
- 每张卡片使用升级后的 WallpaperCard
- 底部加载更多指示器
- 用 12-20 张 mock 壁纸数据填充

**创建文件**：`Sources/Views/Explore/WallpaperExploreView.swift`

### 3. 媒体探索页（MediaExploreView）— 对标 WaifuX 媒体页

**参考文件**：`/Users/Alex/AI/project/WaifuX/Views/MediaExploreContentView.swift`

**必须包含**：
- 顶部筛选芯片栏（分辨率、时长、排序）
- 动态壁纸网格
- 卡片左上角显示时长标签
- 用 12-20 张 mock 动态壁纸数据填充

**创建文件**：`Sources/Views/Explore/MediaExploreView.swift`

### 4. 我的库页（MyLibraryView）— 对标 WaifuX 我的页

**参考文件**：`/Users/Alex/AI/project/WaifuX/Views/MyLibraryContentView.swift`

**必须包含**：
- 顶部分段控制器：收藏 | 下载 | 历史
- 壁纸网格
- 编辑模式（多选 + 批量删除）
- 导入按钮（本地文件导入）
- 空状态提示

**创建文件**：`Sources/Views/Library/MyLibraryView.swift`

### 5. 设置页（SettingsView）— 基于 WaifuX 设置页 + Plum 功能

**参考文件**：`/Users/Alex/AI/project/WaifuX/Views/SettingsView.swift`

**设置页作为独立窗口打开（和 WaifuX 一样），不在 Tab 中。** 顶部导航栏右侧的齿轮图标点击后打开设置窗口。

**设置分组**：

```
播放设置
├── 循环模式（循环/单次）
├── 播放速率
├── 随机起始位置
└── 轮播设置（启用/间隔/顺序/来源）

音频设置
├── 全局音量
├── 默认静音
├── 仅预览时播放音频
└── 音频闪避

性能设置
├── FPS 上限
├── VSync
├── 实时性能监控图表（FPS/GPU/内存）
└── 色彩空间

智能暂停策略
├── 使用电池时暂停
├── 全屏应用时暂停
├── 低电量时暂停
├── 屏幕共享时暂停
├── 高负载时暂停
├── 失去焦点时暂停
├── 合盖时暂停
├── 睡眠前暂停
└── 被遮挡时暂停

显示设置
├── 显示拓扑（独立/镜像/全景）
├── 屏幕顺序
└── 壁纸透明度

外观设置
├── 主题模式（深色/浅色/跟随系统）
├── 缩略图大小
└── 动画效果

应用规则
├── 应用黑名单列表
└── 添加规则（选择应用 + 动作）

系统
├── 开机启动
├── 菜单栏图标
└── 媒体库路径
```

**每个分组用液态玻璃卡片包裹，和 WaifuX 设置页风格一致。**

**拆分为多个文件**：
- `Sources/Views/Settings/SettingsView.swift`（主容器 + 分组导航）
- `Sources/Views/Settings/PlaybackSettingsView.swift`
- `Sources/Views/Settings/AudioSettingsView.swift`
- `Sources/Views/Settings/PerformanceSettingsView.swift`
- `Sources/Views/Settings/PauseSettingsView.swift`
- `Sources/Views/Settings/DisplaySettingsView.swift`
- `Sources/Views/Settings/AppearanceSettingsView.swift`
- `Sources/Views/Settings/AppRulesView.swift`

### 6. 壁纸详情弹窗（WallpaperDetailSheet）

**参考文件**：`/Users/Alex/AI/project/WaifuX/Views/WallpaperDetailSheet.swift`

**必须包含**：
- 大图预览
- 壁纸信息（分辨率、文件大小、帧率、时长）
- "设为壁纸"按钮
- "编辑着色器"按钮（打开着色器编辑器）
- 收藏按钮
- 显示器选择（多屏时）

**创建文件**：`Sources/Views/Detail/WallpaperDetailSheet.swift`

### 7. 着色器编辑器（ShaderEditorView）

**不在顶部 Tab 中**，从壁纸详情页的"编辑着色器"按钮进入。

**保持现有实现**，但视觉风格要和其他页面统一（液态玻璃）。

**文件不变**：`Sources/Views/ShaderEditor/ShaderEditorView.swift`

---

## 卡片组件升级（最重要）

**参考文件**：`/Users/Alex/AI/project/WaifuX/Components/LiquidGlassWallpaperCard.swift`

当前的卡片只是灰色方块，必须升级为：

1. **玻璃背景**：`.ultraThinMaterial` 真正的玻璃质感
2. **渐变边框**：顶部亮（white 0.25）、底部暗（white 0.08）
3. **左上角标签**：分类胶囊（如"通用"、"SFW"、"4K"）
4. **右下角分辨率**：半透明背景 + 白色文字
5. **底部信息栏**：壁纸名称 + 爱心按钮 + 浏览数
6. **hover 效果**：发光边框 + 轻微放大（scale 1.02）
7. **缩略图占位**：用不同的渐变色块模拟（不是灰色图标），每张卡片随机渐变色
8. **圆角**：16-20pt

---

## 间距和排版规范

- 内容区左右内边距：40px
- 卡片间距：18pt
- 分区标题：18pt Bold
- Hero 标题：46pt Bold Serif
- 卡片标题：14pt Semibold
- 副标题/元数据：12pt Medium

---

## ContentView 结构

```swift
struct ContentView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack {
            LiquidGlassAtmosphereBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopNavigationBar(selectedTab: $selectedTab, ...)

                // 页面内容
                switch selectedTab {
                case .home:
                    HomeView()
                case .wallpaper:
                    WallpaperExploreView()
                case .media:
                    MediaExploreView()
                case .myLibrary:
                    MyLibraryView()
                }
            }
        }
    }
}
```

---

## 编码规范（必须遵守）

1. **不要用 `public` 修饰符** — 所有类型都是 internal
2. **不要给静态属性加 `@MainActor`** — 颜色常量不需要
3. **不要重复定义类型** — `MainTab` 只在 TopNavigationBar.swift 中定义一次
4. **ViewModel 用 `@Observable`**（不是 `@ObservableObject`）
5. **SwiftData 用 `@Environment(\.modelContext)`**
6. **`SettingsViewModel.settings` 是 Optional** — 访问用 `viewModel.settings?.xxx`
7. **每个文件改完后确保能编译**

---

## 文件清单（最终交付）

```
Sources/Views/
├── ContentView.swift                    # 主容器（ZStack + Tab 切换）
├── Home/
│   └── HomeView.swift                   # 首页（Hero 轮播 + 分区列表）
├── Explore/
│   ├── WallpaperExploreView.swift       # 壁纸探索（网格 + 筛选）
│   └── MediaExploreView.swift           # 媒体探索（网格 + 筛选）
├── Library/
│   └── MyLibraryView.swift              # 我的库（收藏/下载/历史）
├── Detail/
│   └── WallpaperDetailSheet.swift       # 壁纸详情弹窗
├── ShaderEditor/
│   └── ShaderEditorView.swift           # 着色器编辑器（已有，统一风格）
├── Settings/
│   ├── SettingsView.swift               # 设置主容器
│   ├── PlaybackSettingsView.swift
│   ├── AudioSettingsView.swift
│   ├── PerformanceSettingsView.swift
│   ├── PauseSettingsView.swift
│   ├── DisplaySettingsView.swift
│   ├── AppearanceSettingsView.swift
│   └── AppRulesView.swift
├── Components/
│   ├── TopNavigationBar.swift           # 顶部导航栏（修改 MainTab）
│   ├── WallpaperCard.swift              # 壁纸卡片（升级）
│   ├── FilterChips.swift                # 筛选芯片
│   ├── LiquidGlassComponents.swift
│   └── GrainTextureOverlay.swift
└── DesignSystem/
    ├── LiquidGlassDesignSystem.swift
    └── LiquidGlassExtensions.swift
```

---

## 执行顺序

1. **先改 MainTab 和 TopNavigationBar** — 4 个 Tab
2. **改 ContentView** — 接入新的 Tab 结构
3. **实现 HomeView** — Hero 轮播 + 分区列表（这是视觉核心）
4. **升级 WallpaperCard** — 玻璃质感 + hover 效果
5. **实现 WallpaperExploreView 和 MediaExploreView**
6. **实现 MyLibraryView**
7. **重写 SettingsView** — 拆分为 8 个子文件
8. **实现 WallpaperDetailSheet**
9. **构建验证**

**每完成一个大步骤就通知我构建验证，不要一口气全改完。**

---

## 构建命令

```bash
cd /Users/Alex/AI/project/PlumWallPaper
xcodegen generate
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

**开始吧，从 Step 1（MainTab + TopNavigationBar）开始。**
