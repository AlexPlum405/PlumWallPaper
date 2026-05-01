# Gemini - PlumWallPaper v2.0 UI 实现任务（三阶段）

你好 Gemini！这是一个全新的任务，请忽略之前的所有尝试。

## 🎯 任务目标

为 PlumWallPaper v2.0（macOS 动态壁纸应用）实现完整的 UI 层，分三个阶段：
1. **阶段 1**：在 PlumWallPaper 架构下复刻 WaifuX 的全部视觉设计
2. **阶段 2**：根据功能差异，增加 Plum 需要的 UI，移除不需要的 UI
3. **阶段 3**：使用 huashu-design skill 进行风格一致性优化和创新升级

---

## 📋 必读文档

1. **技术指南**：`/Users/Alex/AI/project/PlumWallPaper/docs/task4-gemini-prompt.md`
   - PlumWallPaper 架构、数据模型、ViewModel API

2. **实现计划**：`/Users/Alex/AI/project/PlumWallPaper/docs/superpowers/plans/2026-04-30-phase1-implementation-plan.md`
   - Task 4 部分（line 802-868）

3. **WaifuX 参考**：
   - 源码：`/Users/Alex/AI/project/WaifuX/`
   - 截图：`/Users/Alex/AI/project/WaifuX/screenshots/`
   - 设计系统：`/Users/Alex/AI/project/WaifuX/DesignSystem/LiquidGlassDesignSystem.swift`

---

## 🚀 阶段 1：复刻 WaifuX 视觉设计

### 目标
在 PlumWallPaper 的架构（@Observable + SwiftData）下，完整复刻 WaifuX 的视觉设计。

### WaifuX 视觉特征（必须保留）

**设计系统**：
- **液态玻璃效果**：半透明背景 + 模糊 + 边框高光
- **配色方案**：
  - 主色：`#FF3366` (primaryPink)
  - 辅色：`#8B5CF6` (secondaryViolet), `#3B8BFF` (tertiaryBlue)
  - 背景：`#0D0D0D` (deepBackground), `#12121F` (midBackground)
- **间距系统**：contentHorizontalInset=26, cardSpacing=18
- **字体层级**：
  - Hero 标题：46pt Bold Serif
  - 分区标题：18pt Bold
  - 卡片标题：14pt Semibold

**导航结构**：
- 顶部 Tab 导航栏（5 个 Tab）
- Keep-Alive 模式（访问过的 Tab 保留子树）

**核心页面**：
1. **Home**：轮播 + 最新壁纸 + 热门动态
2. **WallpaperExplore**：壁纸网格 + 筛选芯片
3. **MediaExplore**：动态壁纸网格 + 分辨率筛选
4. **MyLibrary**：收藏 + 下载 + 历史
5. **Settings**：设置页

### 实现步骤

#### Step 1.1: 复制设计系统

从 WaifuX 复制以下文件到 PlumWallPaper：

```bash
# 创建设计系统目录
mkdir -p /Users/Alex/AI/project/PlumWallPaper/Sources/Views/DesignSystem

# 复制文件（你需要手动创建这些文件）
# 源文件：/Users/Alex/AI/project/WaifuX/DesignSystem/LiquidGlassDesignSystem.swift
# 目标：/Users/Alex/AI/project/PlumWallPaper/Sources/Views/DesignSystem/LiquidGlassDesignSystem.swift
```

**关键内容**：
- `LiquidGlassColors`：所有颜色定义
- `LiquidGlassLevel`：玻璃效果等级
- `LiquidGlassModifier`：液态玻璃修饰器
- 间距常量、字体扩展

#### Step 1.2: 复制核心组件

从 WaifuX 复制以下组件到 PlumWallPaper（需要适配架构）：

```
WaifuX 组件 → PlumWallPaper 组件
├── LiquidGlassComponents.swift → Sources/Views/Components/LiquidGlassComponents.swift
├── LiquidGlassWallpaperCard.swift → Sources/Views/Components/WallpaperCard.swift
├── TopNavigationBar.swift → Sources/Views/Components/TopNavigationBar.swift
├── ExploreChips.swift → Sources/Views/Components/FilterChips.swift
└── LoadingAnimations.swift → Sources/Views/Components/LoadingAnimations.swift
```

**⚠️ 架构适配要求**：

WaifuX 使用 `@ObservableObject`，PlumWallPaper 使用 `@Observable`。复制时必须改写：

```swift
// ❌ WaifuX 的代码（不能直接用）
class WallpaperViewModel: ObservableObject {
    @Published var wallpapers: [Wallpaper] = []
}

struct LibraryView: View {
    @StateObject var viewModel = WallpaperViewModel()
}

// ✅ PlumWallPaper 的代码（必须改成这样）
@Observable
final class LibraryViewModel {
    var wallpapers: [Wallpaper] = []
}

struct LibraryView: View {
    @State var viewModel = LibraryViewModel()
}
```

#### Step 1.3: 实现核心页面

基于 WaifuX 的视觉设计，实现以下页面：

**1. ContentView（主容器）**
- 文件：`Sources/Views/ContentView.swift`
- 参考：`/Users/Alex/AI/project/WaifuX/Views/ContentView.swift`
- 功能：顶部 Tab 导航 + 页面切换 + Keep-Alive

**2. LibraryView（壁纸库）**
- 文件：`Sources/Views/Library/LibraryView.swift`
- 参考：`/Users/Alex/AI/project/WaifuX/Views/WallpaperExploreContentView.swift`
- 功能：网格布局 + 筛选芯片 + 搜索

**3. PreviewView（预览页）**
- 文件：`Sources/Views/Preview/PreviewView.swift`
- 参考：`/Users/Alex/AI/project/WaifuX/Views/WallpaperDetailSheet.swift`
- 功能：全屏预览 + 播放控制

**4. SettingsView（设置页）**
- 文件：`Sources/Views/Settings/SettingsView.swift`
- 参考：`/Users/Alex/AI/project/WaifuX/Views/SettingsView.swift`
- 功能：分组设置 + 液态玻璃卡片

**5. ShaderEditorView（着色器编辑器）**
- 文件：`Sources/Views/ShaderEditor/ShaderEditorView.swift`
- 参考：无（WaifuX 没有此功能，但使用相同视觉风格）
- 功能：Pass 列表 + 参数面板 + 预览

#### Step 1.4: 数据模型映射

WaifuX 和 PlumWallPaper 的数据模型不同，需要创建适配层：

```swift
// Sources/ViewModels/LibraryViewModel.swift

@Observable
final class LibraryViewModel {
    var wallpapers: [Wallpaper] = []  // PlumWallPaper 的 Wallpaper
    
    // 将 PlumWallPaper Wallpaper 转换为 UI 需要的格式
    var displayWallpapers: [WallpaperDisplayModel] {
        wallpapers.map { wallpaper in
            WallpaperDisplayModel(
                id: wallpaper.id,
                name: wallpaper.name,
                thumbnailURL: URL(fileURLWithPath: wallpaper.thumbnailPath ?? ""),
                resolution: wallpaper.resolution ?? "未知",
                isFavorite: wallpaper.isFavorite,
                // WaifuX 有 views/favorites/downloads，PlumWallPaper 没有
                // 可以用占位数据或隐藏这些字段
                views: 0,
                favorites: 0
            )
        }
    }
}

struct WallpaperDisplayModel: Identifiable {
    let id: UUID
    let name: String
    let thumbnailURL: URL
    let resolution: String
    let isFavorite: Bool
    let views: Int
    let favorites: Int
}
```

### 阶段 1 完成标准

- ✅ 所有页面使用液态玻璃设计系统
- ✅ 配色、间距、字体与 WaifuX 一致
- ✅ 导航结构与 WaifuX 一致
- ✅ 使用 PlumWallPaper 的架构（@Observable + SwiftData）
- ✅ 能够编译通过（允许有运行时错误，因为后端未完成）

---

## 🔧 阶段 2：功能差异调整

### 目标
在阶段 1 的基础上，增加 Plum 需要的功能 UI，移除不需要的功能 UI。

### 需要移除的功能（WaifuX 有，Plum 不需要）

**1. 动漫模块（整个删除）**
- ❌ AnimeExploreView（动漫探索页）
- ❌ AnimeDetailView（动漫详情页）
- ❌ AnimePlayerWindow（动漫播放器）
- ❌ AnimeRulesMarketView（动漫规则市场）
- ❌ DanmakuView（弹幕组件）
- ❌ AnimePortraitCard（动漫卡片）

**2. 导航调整**
```swift
// ❌ WaifuX 的 5 个 Tab
enum MainTab {
    case home, wallpaperExplore, mediaExplore, animeExplore, myMedia
}

// ✅ PlumWallPaper 的 3 个 Tab
enum SidebarItem {
    case library        // 壁纸库（合并 home + wallpaperExplore + mediaExplore）
    case shaderEditor   // 着色器编辑器（新增）
    case settings       // 设置
}
```

### 需要增加的功能（Plum 独有）

**1. 着色器编辑器（核心功能）**
- 文件：`Sources/Views/ShaderEditor/ShaderEditorView.swift`
- 子组件：
  - `PassListView.swift`：Pass 列表（左侧）
  - `ParameterPanelView.swift`：参数面板（右侧）
  - `ShaderPreviewView.swift`：实时预览（中间）
- 视觉风格：使用液态玻璃设计系统

**2. 性能监控面板**
- 位置：SettingsView 的子页面
- 文件：`Sources/Views/Settings/PerformanceSettingsView.swift`
- 功能：FPS 图表 + GPU 使用率 + 内存占用
- 视觉：使用 WaifuX 的图表样式

**3. 智能暂停策略设置**
- 位置：SettingsView 的子页面
- 文件：`Sources/Views/Settings/PauseSettingsView.swift`
- 功能：9 个暂停策略开关 + 应用规则黑名单
- 视觉：使用 WaifuX 的设置卡片样式

**4. 本地文件导入**
- 位置：LibraryView 的导入按钮
- 文件：`Sources/Views/Library/ImportSheet.swift`
- 功能：文件选择器 + 重复检测 + 进度显示
- 视觉：使用 WaifuX 的弹窗样式

### 实现步骤

#### Step 2.1: 移除动漫模块

删除以下文件和代码：
- 所有包含 "Anime" 的 View 文件
- `DanmakuView.swift`
- `MainTab.animeExplore` 相关代码
- `AnimeViewModel` 相关代码

#### Step 2.2: 调整导航结构

```swift
// Sources/Views/ContentView.swift

enum SidebarItem: String, CaseIterable, Identifiable {
    case library = "壁纸库"
    case shaderEditor = "着色器编辑器"
    case settings = "设置"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .library: return "photo.on.rectangle"
        case .shaderEditor: return "slider.horizontal.3"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .library
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .liquidGlass(level: .regular)  // 使用液态玻璃效果
        } detail: {
            switch selectedItem {
            case .library:
                LibraryView()
            case .shaderEditor:
                ShaderEditorView()
            case .settings:
                SettingsView()
            case nil:
                Text("选择一个页面")
            }
        }
    }
}
```

#### Step 2.3: 实现 Plum 独有功能

按照上述"需要增加的功能"清单，实现 4 个新功能的 UI。

### 阶段 2 完成标准

- ✅ 移除所有动漫相关 UI
- ✅ 导航改为 3 个 Tab（壁纸库/着色器编辑器/设置）
- ✅ 着色器编辑器 UI 完成
- ✅ 性能监控面板 UI 完成
- ✅ 智能暂停策略 UI 完成
- ✅ 本地文件导入 UI 完成
- ✅ 所有新增 UI 使用液态玻璃设计系统

---

## 🎨 阶段 3：风格一致性优化和创新升级

### 目标
使用 `huashu-design` skill 对整个 UI 进行风格一致性优化和创新升级，避免被指抄袭。

### 为什么需要这个阶段？

阶段 2 完成后，UI 会出现以下问题：
1. **结构混乱**：WaifuX 的 5 Tab 导航 + Plum 的 3 Tab 导航混合
2. **功能不匹配**：WaifuX 的"首页轮播"在 Plum 中没有意义
3. **视觉不统一**：新增的着色器编辑器可能与其他页面风格不一致
4. **抄袭风险**：直接复刻 WaifuX 的视觉可能被指抄袭

### 实现步骤

#### Step 3.1: 调用 huashu-design skill

```
/skill huashu-design
```

向 huashu-design 提供以下信息：

**当前状态**：
- 已完成阶段 1 和阶段 2
- UI 基于 WaifuX 的液态玻璃设计系统
- 功能已调整为 Plum 的需求（壁纸库/着色器编辑器/设置）
- 存在风格不统一和抄袭风险

**优化目标**：
1. **风格一致性**：确保所有页面使用统一的设计语言
2. **创新升级**：在液态玻璃基础上，加入独特的设计元素
3. **避免抄袭**：与 WaifuX 有明显的视觉差异

**设计方向建议**：
- 保留液态玻璃的核心特征（半透明、模糊、高光）
- 调整配色方案（主色从粉色改为梅花色系）
- 优化间距和布局（更紧凑或更宽松）
- 加入独特的动画效果
- 优化着色器编辑器的视觉层级

#### Step 3.2: 实施 huashu-design 的建议

根据 huashu-design 的输出，修改以下内容：

**1. 配色方案调整**
```swift
// 从 WaifuX 的粉紫色系 → Plum 的梅花色系
primaryPink      = #FF3366  →  plumPrimary      = #DC143C  // 梅红
secondaryViolet  = #8B5CF6  →  plumSecondary    = #9370DB  // 梅紫
tertiaryBlue     = #3B8BFF  →  plumTertiary     = #4682B4  // 梅蓝
```

**2. 布局优化**
- 调整卡片间距（从 18pt 改为 16pt 或 20pt）
- 调整内容内边距（从 26pt 改为 24pt 或 28pt）
- 优化着色器编辑器的三栏布局比例

**3. 动画效果**
- 加入独特的 hover 动画
- 优化页面切换过渡
- 加入微交互反馈

**4. 字体层级**
- 调整标题字体大小
- 优化字重层级

#### Step 3.3: 创建设计文档

创建 `Sources/Views/DesignSystem/PlumDesignSystem.md`，记录：
- Plum 的设计理念
- 与 WaifuX 的差异点
- 配色方案和使用场景
- 间距系统和布局规范
- 动画效果和交互规范

### 阶段 3 完成标准

- ✅ 所有页面风格统一
- ✅ 配色方案与 WaifuX 有明显差异
- ✅ 布局和间距有独特性
- ✅ 加入独特的动画效果
- ✅ 创建完整的设计文档
- ✅ 通过 huashu-design 的专家评审

---

## 📁 文件清单（最终交付）

### 设计系统（2 个文件）
- `Sources/Views/DesignSystem/LiquidGlassDesignSystem.swift`
- `Sources/Views/DesignSystem/PlumDesignSystem.md`

### 核心组件（6 个文件）
- `Sources/Views/Components/LiquidGlassComponents.swift`
- `Sources/Views/Components/WallpaperCard.swift`
- `Sources/Views/Components/TopNavigationBar.swift`
- `Sources/Views/Components/FilterChips.swift`
- `Sources/Views/Components/LoadingAnimations.swift`
- `Sources/Views/Components/PerformanceChart.swift`

### 主视图（1 个文件）
- `Sources/Views/ContentView.swift`

### 壁纸库（5 个文件）
- `Sources/Views/Library/LibraryView.swift`
- `Sources/Views/Library/WallpaperCard.swift`
- `Sources/Views/Library/FilterBar.swift`
- `Sources/Views/Library/ImportSheet.swift`
- `Sources/Views/Library/TagManagerSheet.swift`

### 预览（2 个文件）
- `Sources/Views/Preview/PreviewView.swift`
- `Sources/Views/Preview/PreviewControls.swift`

### 着色器编辑器（4 个文件）
- `Sources/Views/ShaderEditor/ShaderEditorView.swift`
- `Sources/Views/ShaderEditor/PassListView.swift`
- `Sources/Views/ShaderEditor/ParameterPanelView.swift`
- `Sources/Views/ShaderEditor/ShaderPreviewView.swift`

### 设置（8 个文件）
- `Sources/Views/Settings/SettingsView.swift`
- `Sources/Views/Settings/PlaybackSettingsView.swift`
- `Sources/Views/Settings/AudioSettingsView.swift`
- `Sources/Views/Settings/PerformanceSettingsView.swift`
- `Sources/Views/Settings/PauseSettingsView.swift`
- `Sources/Views/Settings/DisplaySettingsView.swift`
- `Sources/Views/Settings/AppearanceSettingsView.swift`
- `Sources/Views/Settings/AppRulesView.swift`

### 菜单栏（1 个文件）
- `Sources/Views/MenuBar/MenuBarView.swift`

**总计：29 个文件**

---

## ⚠️ 关键注意事项

### 架构适配（必须遵守）

**1. ViewModel 绑定**
```swift
// ❌ 错误（WaifuX 的方式）
@StateObject var viewModel = LibraryViewModel()

// ✅ 正确（PlumWallPaper 的方式）
@State var viewModel = LibraryViewModel()
```

**2. 数据模型访问**
```swift
// ⚠️ PlumWallPaper 的 SettingsViewModel.settings 是 Optional
viewModel.settings?.globalVolume  // ✅ 正确
viewModel.settings.globalVolume   // ❌ 编译错误
```

**3. SwiftData 注入**
```swift
// PlumWallPaper 使用 SwiftData
@Environment(\.modelContext) private var modelContext

// WaifuX 使用自定义 Service（不要复制这种方式）
@EnvironmentObject var wallpaperService: WallpaperService
```

### 构建验证

每个阶段完成后，运行构建验证：

```bash
cd /Users/Alex/AI/project/PlumWallPaper
xcodegen generate
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

**允许的错误**：
- ✅ 运行时错误（后端未完成）
- ✅ 数据为空（SwiftData 未初始化）

**不允许的错误**：
- ❌ 编译错误
- ❌ 类型不匹配
- ❌ 缺少文件

---

## 📞 完成后

每个阶段完成后，通知用户：

**阶段 1 完成**：
> "阶段 1 完成：已在 PlumWallPaper 架构下复刻 WaifuX 的全部视觉设计。所有页面使用液态玻璃设计系统，配色、间距、字体与 WaifuX 一致。请审查代码。"

**阶段 2 完成**：
> "阶段 2 完成：已移除动漫模块，增加着色器编辑器、性能监控、智能暂停策略等 Plum 独有功能。导航改为 3 Tab。请审查代码。"

**阶段 3 完成**：
> "阶段 3 完成：已使用 huashu-design 进行风格一致性优化和创新升级。配色方案改为梅花色系，布局和动画有独特性，与 WaifuX 有明显差异。请审查代码和设计文档。"

---

**开始吧！从阶段 1 开始，逐步完成三个阶段。** 🚀
