# 数据加载问题最终解决方案

> **说明**: 本文保留了一次针对数据加载问题的根因分析。像“最终解决方案”这样的命名不代表它仍是当前唯一正确结论，使用前请先核对现有 ViewModel、View 生命周期和运行日志。

## 🎯 根本原因

通过对比 WaifuX 的实现，发现问题在于：

**我们使用了 Swift 5.9+ 的 `@Observable` 宏，但它与自定义 `main()` 函数的 SwiftUI 生命周期不兼容。**

## 🔑 关键差异

| 项目 | 旧代码（错误） | WaifuX（正确） | 新代码（修复后） |
|------|--------------|---------------|----------------|
| ViewModel 协议 | `@Observable` | `ObservableObject` | `ObservableObject` |
| View 声明 | `@State var viewModel` | `@ObservedObject var viewModel` | `@StateObject var viewModel` |
| 属性包装器 | 无 | `@Published` | `@Published` |
| 数据加载触发 | `.task` | `.onAppear` | `.onAppear` |

## ✅ 已修复的文件

### ViewModels
1. **HomeFeedViewModel.swift**
   - 改为 `class HomeFeedViewModel: ObservableObject`
   - 所有状态属性添加 `@Published`
   - 添加 `import Combine`

2. **WallpaperExploreViewModel.swift**
   - 改为 `class WallpaperExploreViewModel: ObservableObject`
   - 所有状态属性添加 `@Published`

3. **MediaExploreViewModel.swift**
   - 改为 `class MediaExploreViewModel: ObservableObject`
   - 所有状态属性添加 `@Published`

### Views
1. **HomeView.swift**
   - 改为 `@StateObject var viewModel = HomeFeedViewModel()`
   - 将 `.task` 改为 `.onAppear { Task { await viewModel.loadInitialData() } }`

2. **WallpaperExploreView.swift**
   - 改为 `@StateObject private var viewModel = WallpaperExploreViewModel()`
   - 使用 `.onAppear` 触发数据加载

3. **MediaExploreView.swift**
   - 改为 `@StateObject var viewModel = MediaExploreViewModel()`
   - 使用 `.onAppear` 触发数据加载

### 其他修复
4. **LibraryViewModel.swift**
   - 移除 Mock 数据
   - 启用 `loadWallpapers()` 从数据库加载真实数据

## 📝 修复前后对比

### 修复前
```swift
@Observable
final class HomeFeedViewModel {
    var heroItems: [MediaItem] = []
    var isLoading = false
}

struct HomeView: View {
    @State var viewModel = HomeFeedViewModel()
    
    var body: some View {
        // ...
        .task {
            await viewModel.loadInitialData()
        }
    }
}
```

### 修复后
```swift
final class HomeFeedViewModel: ObservableObject {
    @Published var heroItems: [MediaItem] = []
    @Published var isLoading = false
}

struct HomeView: View {
    @StateObject var viewModel = HomeFeedViewModel()
    
    var body: some View {
        // ...
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
    }
}
```

## 🚀 启动应用

### 方法 1: 使用启动脚本
```bash
cd /Users/Alex/AI/project/PlumWallPaper
./run.sh
```

### 方法 2: 手动启动
```bash
cd /Users/Alex/AI/project/PlumWallPaper
pkill -9 PlumWallPaper
.build/arm64-apple-macosx/debug/PlumWallPaper &
```

## 📊 验证数据加载

启动应用后，你应该看到：

1. **首页（Home）**
   - Hero 轮播自动加载（8 个动态壁纸）
   - 最新壁纸自动加载（8 个静态壁纸）
   - 热门动态自动加载（8 个动态壁纸）

2. **静态壁纸（Wallpaper Explore）**
   - 切换到该标签时自动加载壁纸网格
   - 支持搜索、筛选、无限滚动

3. **动态壁纸（Media Explore）**
   - 切换到该标签时自动加载媒体网格
   - 支持来源切换（MotionBG）

4. **本地库（Library）**
   - 显示数据库中的真实数据
   - 如果为空则显示空状态

## 🔍 调试日志

应用启动时会输出以下日志：
```
[ContentView] 应用启动，准备初始化数据
[HomeView] .onAppear 被调用
[HomeView] 开始加载初始数据
[HomeFeedViewModel] 开始加载数据...
[HomeFeedViewModel] 加载 Hero 项目...
[HomeFeedViewModel] 加载最新壁纸...
[WallpaperRepository] fetchLatest() 开始
[WallhavenService] fetchLatest() 开始, limit=20
```

## 🎉 预期结果

- ✅ 首页自动加载 Hero 轮播、最新壁纸、热门动态
- ✅ 静态壁纸标签自动加载壁纸网格
- ✅ 动态壁纸标签自动加载媒体网格
- ✅ 本地库显示真实数据（非 Mock）
- ✅ 网络请求正常工作（已验证 Wallhaven API 可访问）

## 🐛 如果仍然没有数据

1. 点击首页的"🔄 手动加载数据"按钮
2. 检查控制台日志是否有错误
3. 确认网络连接正常
4. 检查是否有防火墙阻止网络请求

## 📚 参考

- WaifuX 实现: `/Users/Alex/AI/project/WaifuX/`
- 对比文件:
  - `WaifuX/ViewModels/WallpaperViewModel.swift`
  - `WaifuX/Views/WallpaperExploreContentView.swift`
