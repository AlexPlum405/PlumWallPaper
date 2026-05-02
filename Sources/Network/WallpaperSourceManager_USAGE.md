# WallpaperSourceManager 使用指南

## 概述

`WallpaperSourceManager` 管理 Wallhaven 和 4K Wallpapers 两个数据源之间的自动切换。

## 初始化

在 `AppDelegate.applicationDidFinishLaunching` 中：

```swift
// 1. 恢复持久化状态
WallpaperSourceManager.shared.restoreState()

// 2. 启动时选择数据源（异步）
Task {
    await WallpaperSourceManager.shared.performStartupSourceSelection()
}
```

## 核心功能

### 1. 获取当前数据源

```swift
let currentSource = WallpaperSourceManager.shared.currentSource()
switch currentSource {
case .wallhaven:
    // 使用 Wallhaven API
case .fourKWallpapers:
    // 使用 4K Wallpapers API
}
```

### 2. 手动切换数据源

```swift
// 用户在设置中手动选择
WallpaperSourceManager.shared.switchTo(.fourKWallpapers)
```

### 3. 检查功能支持

```swift
// 检查当前源是否支持 NSFW 筛选
if WallpaperSourceManager.shared.currentSourceSupportsNSFW {
    // 显示 NSFW 选项
}

// 检查是否支持颜色筛选
if WallpaperSourceManager.shared.currentSourceSupportsColorFilter {
    // 显示颜色选择器
}
```

### 4. 监听数据源变更

```swift
NotificationCenter.default.addObserver(
    forName: .wallpaperDataSourceChanged,
    object: nil,
    queue: .main
) { _ in
    // 重新加载数据
    self.reloadWallpapers()
}
```

### 5. 自动降级

当 Wallhaven 不可用时，系统会自动切换到 4K Wallpapers：

```swift
// 记录失败并尝试降级
if let fallbackSource = WallpaperSourceManager.shared.recordCurrentSourceFailedAndDowngrade() {
    print("Switched to fallback: \(fallbackSource.displayName)")
}
```

## 启动流程

1. **VPN 检测**：如果检测到 VPN，保持使用 Wallhaven
2. **Google Ping**：如果没有 VPN，ping Google 检测网络
   - Google 可达 → 使用 Wallhaven
   - Google 不可达 → 使用 4K Wallpapers

## 注意事项

- ⚠️ 不要在 `init()` 中读取 UserDefaults（macOS 26+ 会崩溃）
- ⚠️ 必须在 AppDelegate 中调用 `restoreState()`
- ⚠️ 数据源切换会发送 `.wallpaperDataSourceChanged` 通知
