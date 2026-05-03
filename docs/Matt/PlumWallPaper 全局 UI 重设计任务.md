PlumWallPaper 全局 UI 重设计任务

  项目背景

  PlumWallPaper 是一个 macOS 动态壁纸管理应用，目标是成为 macOS 最好的动态壁纸软件。

  当前 UI 基本来源于 WaifuX，缺乏独特的品牌特色和设计一致性。我希望通过 huashu-design skill 进行全局 UI 重设计，形成统一的设计语言。

  项目架构（重要）

  本项目的 UI 代码和业务逻辑已经物理隔离：

  - XXX.swift — UI 代码（你可以修改）
  - XXX+Logic.swift — 业务逻辑（绝对禁止修改）

  例如：
  HomeView.swift          ← 可以修改（UI）
  HomeView+Logic.swift    ← 禁止修改（业务逻辑）

  UI 文件中的函数通过 Swift extension 调用 Logic 文件中的函数。你只需要关心 UI 文件中的 View body 和样式代码。

  任务分为两个阶段

  阶段 1：设计方案（不写代码）

  使用 /huashu-design skill 为 PlumWallPaper 设计 3-5 套完整的 UI 设计方案。

  每套方案必须包含：

  1. 设计理念

  - 核心设计哲学
  - 为什么这套设计适合动态壁纸管理应用
  - 与竞品（Wallpaper Engine、Lively Wallpaper）的差异化

  2. 视觉特点

  - 整体视觉风格描述
  - 关键视觉元素（圆角、阴影、模糊、渐变等）
  - 动效风格（弹性、流畅、快速等）

  3. 色彩系统

  - 主色调（保留或改进当前的粉紫渐变）
  - 辅助色
  - 语义色（成功、警告、错误、信息）
  - 背景色层级
  - 文字颜色层级

  4. 排版规则

  - 字体家族
  - 字号体系（标题、正文、辅助文字）
  - 行高、字间距

  5. 组件风格

  - 按钮样式（主要、次要、文字按钮）
  - 卡片样式（圆角、边框、阴影、背景）
  - 输入框样式
  - 导航栏样式
  - Toast/Alert 样式

  6. 布局系统

  - 间距体系
  - 网格系统

  7. 页面示例

  为以下关键页面提供文字描述（不是代码）：
  - 首页（HomeView）
  - 库页面（MyLibraryView）
  - 详情页（WallpaperDetailView）
  - 设置页（SettingsView）
  - 应用规则页（AppRulesTabV2）

  阶段 2：全局重绘（写代码）

  在我选择了一套方案后，按照该方案逐个文件重绘所有 UI。

  重绘顺序：
  1. 设计系统基础（LiquidGlassDesignSystem.swift、LiquidGlassExtensions.swift）
  2. 基础组件（WallpaperCard.swift、TopNavigationBar.swift、FilterChips.swift、ToastView.swift、LiquidGlassComponents.swift）
  3. 主要页面（HomeView.swift、MyLibraryView.swift、WallpaperDetailView.swift）
  4. 设置页面（SettingsView.swift、AppRulesTabV2.swift）
  5. 辅助页面（WallpaperExploreView.swift、MediaExploreView.swift、ImportWallpaperSheet.swift、TagManagerSheet.swift）
  6. 其他（MenuBarView.swift、ShaderEditorView.swift、ContentView.swift）

  核心约束（必须遵守）

  1. 文件权限表

  ✅ 可以修改的文件（UI 代码）：
  Sources/Views/ContentView.swift
  Sources/Views/Home/HomeView.swift
  Sources/Views/Library/LibraryView.swift
  Sources/Views/Library/MyLibraryView.swift
  Sources/Views/Library/ImportWallpaperSheet.swift
  Sources/Views/Library/TagManagerSheet.swift
  Sources/Views/Detail/WallpaperDetailView.swift
  Sources/Views/Explore/WallpaperExploreView.swift
  Sources/Views/Explore/MediaExploreView.swift
  Sources/Views/Settings/SettingsView.swift
  Sources/Views/Settings/AppRulesTabV2.swift
  Sources/Views/ShaderEditor/ShaderEditorView.swift
  Sources/Views/MenuBar/MenuBarView.swift
  Sources/Views/Components/WallpaperCard.swift
  Sources/Views/Components/TopNavigationBar.swift
  Sources/Views/Components/FilterChips.swift
  Sources/Views/Components/ToastView.swift
  Sources/Views/Components/ToastConfig.swift
  Sources/Views/Components/LiquidGlassComponents.swift
  Sources/Views/Components/GrainTextureOverlay.swift
  Sources/Views/Components/WindowAccessor.swift
  Sources/Views/DesignSystem/LiquidGlassDesignSystem.swift
  Sources/Views/DesignSystem/LiquidGlassExtensions.swift
  Sources/Views/Preview/PreviewView.swift

  🚫 绝对禁止修改的文件（业务逻辑 + 数据层）：
  Sources/Views/Home/HomeView+Logic.swift
  Sources/Views/Library/MyLibraryView+Logic.swift
  Sources/Views/Library/ImportWallpaperSheet+Logic.swift
  Sources/Views/Detail/WallpaperDetailView+Logic.swift
  Sources/Views/Explore/WallpaperExploreView+Logic.swift
  Sources/Views/Explore/MediaExploreView+Logic.swift
  Sources/Views/Settings/AppRulesTabV2+Logic.swift
  Sources/Storage/*（所有文件）
  Sources/ViewModels/*（所有文件）
  Sources/Core/*（所有文件）
  Sources/App/*（所有文件）

  2. 代码修改规则

  在可修改的 UI 文件中，你也有限制：

  可以改：
  - View 的 body 属性
  - 私有的 View 组件（headerSection、cardView 等返回 some View 的属性和函数）
  - 颜色值、字体大小、间距、圆角、阴影等样式参数
  - 动画参数（.spring()、.easeInOut() 等）
  - 布局方式（VStack、HStack、LazyVGrid 等）
  - 添加新的纯 UI 组件

  不能改：
  - struct 的属性声明（var viewModel、@Binding var toast 等）
  - @State var 变量声明（名称和类型不能改）
  - 对 Logic 文件中函数的调用方式（函数名和参数不能改）
  - ToastConfig(message:type:) 的调用方式
  - ForEach 中的数据源（configuredRules、filteredRecommendations 等）

  3. 必须保留的设计特点

  1. 深色主题 — 背景色 #1C1C1E 或类似深色
  2. 品牌色 — 粉紫渐变作为品牌主色调（可以微调色值）
  3. Toast 通知 — 保留 ToastConfig(message:type:) 接口

  4. 常见编译错误提醒

  - 不要在 SwiftUI 字符串中使用中文引号 "" ，用 「」 或英文引号代替
  - VisualEffectView 是 private 的，用 LiquidGlassBackgroundView 代替
  - FlowLayout 已在 LiquidGlassComponents.swift 中全局定义，不要重复定义
  - View body 不要太复杂，避免 Swift 编译器类型推断超时

  设计方案要求

  3-5 套方案应该有明显的风格差异。每套方案用 Markdown 格式输出，包含上述 7 个部分。

  工作流程

  第一步：设计方案阶段

  我：开始设计方案阶段

  你：[调用 /huashu-design skill]
  [输出 3-5 套完整的设计方案]

  我：我选择方案 B

  你：确认方案，列出重绘顺序，等待我的指令开始

  第二步：全局重绘阶段

  我：开始重绘 LiquidGlassDesignSystem.swift

  你：[输出完整的文件代码]

  我：[满意] 继续下一个
  我：[不满意] 回滚，重新设计

  注意事项

  1. 设计方案阶段不要写代码，只输出设计文档
  2. 重绘阶段每次只输出一个完整文件，不要省略
  3. 保持设计一致性，所有页面必须遵循同一套设计语言
  4. 可以回滚，如果某个文件不满意，我会 git checkout 回滚
  5. +Logic.swift 文件不能碰，只改 UI 文件

  开始

  现在，请使用 /huashu-design skill 开始设计方案阶段，为 PlumWallPaper 提供 3-5 套完整的 UI 设计方案。

  记住：
  - 现在只输出设计方案文档，不要写代码
  - 每套方案要有明显的风格差异
  - 方案要详细、具体、可执行
  - 考虑 macOS 平台的设计规范
  - 强化 Plum 的品牌特色