# PlumWallPaper 数据加载问题诊断报告

> **说明**: 本文是一次针对数据加载失败的诊断快照，记录了当时的假设和排查路径。它不是当前状态面板；涉及生命周期、actor 隔离或首页加载行为的判断，都需要重新对照现有代码验证。

## 问题描述
用户报告三个标签页无法获取数据：
1. 首页（Home）- Hero 轮播、最新壁纸、热门动态
2. 静态壁纸（Wallpaper Explore）
3. 动态壁纸（Media Explore）
4. 本地库（Library）显示 Mock 数据

## 已完成的诊断

### 1. 网络连接测试 ✅
- 测试脚本验证 Wallhaven API 可正常访问
- HTTP 状态码: 200
- 数据大小: 15697 bytes
- 壁纸总数: 615498

### 2. 代码结构检查 ✅
- Repository 层正确实现
- Service 层正确实现
- NetworkService 正确实现
- ViewModel 正确实现

### 3. 已修复的问题 ✅
- **LibraryViewModel Mock 数据**: 已移除 Mock 数据，启用从数据库加载

### 4. 添加的调试功能
- 在关键方法中添加了详细日志
- 在 HomeView 添加了"🔄 手动加载数据"按钮

## 可能的根本原因

### 原因 1: SwiftUI 生命周期问题
应用使用自定义 `main()` 函数而不是标准的 `@main` 结构：
```swift
@main
struct PlumWallPaperApp {
    static func main() {
        // 自定义初始化
    }
}
```

这可能导致 SwiftUI 的 `.task` 修饰符无法正常触发。

### 原因 2: Actor 隔离问题
- `NetworkService` 和 `MediaService` 是 `actor`
- `WallhavenService` 和 Repositories 使用 `@MainActor`
- 可能存在跨 actor 调用的同步问题

### 原因 3: 初始化时机问题
- ViewModels 可能在网络服务准备好之前就尝试加载数据
- 缓存可能返回空数据

## 建议的解决方案

### 方案 1: 修改应用启动方式（推荐）
将自定义 `main()` 改为标准 SwiftUI 结构：

```swift
@main
struct PlumWallPaperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
```

### 方案 2: 使用 .onAppear 替代 .task
在所有 View 中将 `.task` 改为 `.onAppear`：

```swift
.onAppear {
    Task {
        await viewModel.loadInitialData()
    }
}
```

### 方案 3: 手动初始化（临时方案）
在 ContentView 中手动触发数据加载：

```swift
.onAppear {
    Task {
        // 手动触发所有 ViewModel 的初始化
    }
}
```

## 下一步行动

1. **立即测试**: 用户点击"🔄 手动加载数据"按钮，查看是否能成功加载
2. **查看日志**: 检查控制台输出，确认哪个环节失败
3. **应用修复**: 根据测试结果应用相应的解决方案

## 临时解决方案（已实现）

在 HomeView 中添加了手动加载按钮，用户可以：
1. 启动应用
2. 切换到首页
3. 点击"🔄 手动加载数据"按钮
4. 观察是否能成功加载数据

如果手动加载成功，说明问题确实是 `.task` 修饰符未被触发。
