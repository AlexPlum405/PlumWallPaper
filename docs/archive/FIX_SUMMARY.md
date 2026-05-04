# 数据加载问题修复总结

> **说明**: 本文用于保留一次修复过程的线索，其中启动方式和生命周期推断不一定还适用当前版本。特别是 `.build/.../PlumWallPaper` 的运行方式已不是主 UI 验证基线。

## 已修复的问题

### 1. 本地库显示 Mock 数据 ✅
**问题**: `LibraryViewModel` 初始化时创建了 6 个 Mock 壁纸，且 `configure()` 方法注释掉了 `loadWallpapers()`

**修复**:
```swift
// Sources/ViewModels/LibraryViewModel.swift
init() {
    // 初始化为空数组，等待从数据库加载
    self.wallpapers = []
}

func configure(modelContext: ModelContext) {
    self.store = WallpaperStore(modelContext: modelContext)
    loadWallpapers() // 从数据库加载真实数据
}
```

### 2. 添加调试功能 ✅
**添加的内容**:
1. 在 `HomeFeedViewModel.loadInitialData()` 中添加详细日志
2. 在 `WallpaperRepository.fetchLatest()` 中添加详细日志
3. 在 `WallhavenService.fetchLatest()` 中添加详细日志
4. 在 `HomeView` 中添加 `.onAppear` 和 NSLog
5. 在 `HomeView` 中添加"🔄 手动加载数据"按钮用于测试

### 3. 网络连接验证 ✅
**测试结果**:
- Wallhaven API 可正常访问
- HTTP 状态码: 200
- 返回数据: 24 个壁纸
- 网络层代码正确

## 可能的根本原因

### SwiftUI 生命周期问题
应用使用自定义 `main()` 函数：
```swift
@main
struct PlumWallPaperApp {
    static func main() {
        // 自定义窗口创建
    }
}
```

这可能导致 SwiftUI 的 `.task` 修饰符无法正常触发。

## 测试步骤

1. **启动应用**:
   ```bash
   cd /Users/Alex/AI/project/PlumWallPaper
   .build/arm64-apple-macosx/debug/PlumWallPaper
   ```

2. **测试首页**:
   - 切换到"首页"标签
   - 点击"🔄 手动加载数据"按钮
   - 观察是否能加载 Hero 轮播、最新壁纸、热门动态

3. **测试静态壁纸**:
   - 切换到"静态壁纸"标签
   - 观察是否自动加载壁纸网格

4. **测试动态壁纸**:
   - 切换到"动态壁纸"标签
   - 观察是否自动加载媒体网格

5. **测试本地库**:
   - 切换到"本地库"标签
   - 应该显示空状态（如果数据库为空）或真实数据

## 如果手动加载成功

说明问题确实是 `.task` 修饰符未被触发，需要：

### 方案 A: 改用 .onAppear（推荐）
在所有 View 中将 `.task` 改为 `.onAppear`:
```swift
.onAppear {
    Task {
        if viewModel.items.isEmpty {
            await viewModel.loadInitialData()
        }
    }
}
```

### 方案 B: 修改应用启动方式
将自定义 `main()` 改为标准 SwiftUI 结构：
```swift
@main
struct PlumWallPaperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
```

## 如果手动加载也失败

需要检查：
1. 控制台日志中的错误信息
2. 网络权限设置
3. Actor 隔离问题

## 文件修改清单

1. `Sources/ViewModels/LibraryViewModel.swift` - 移除 Mock 数据
2. `Sources/ViewModels/HomeFeedViewModel.swift` - 添加详细日志
3. `Sources/Repositories/WallpaperRepository.swift` - 添加详细日志
4. `Sources/Network/WallhavenService.swift` - 添加详细日志
5. `Sources/Views/Home/HomeView.swift` - 添加手动加载按钮和日志
6. `Sources/Views/Explore/WallpaperExploreView.swift` - 添加日志
7. `Sources/Views/Explore/MediaExploreView.swift` - 添加日志
8. `Sources/Views/ContentView.swift` - 添加初始化日志

## 下一步

请用户测试应用并反馈：
1. 手动加载按钮是否有效
2. 控制台是否有错误信息
3. 哪些标签页能正常工作，哪些不能
