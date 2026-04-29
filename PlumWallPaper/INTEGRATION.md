# PlumWallPaper 架构说明

> 更新日期: 2026-04-29

## 整体架构

```
┌─────────────────────────────────────────────────────┐
│  WebView (plumwallpaper.html)                       │
│  React 单文件 · Babel 编译 · 全部 UI 逻辑          │
└────────────────────┬────────────────────────────────┘
                     │ window.webkit.messageHandlers
                     │ + evaluateJavaScript callback
┌────────────────────▼────────────────────────────────┐
│  WebBridge.swift                                     │
│  JS↔Swift 消息路由 · 所有前端操作的后端入口         │
└────────────────────┬────────────────────────────────┘
                     │
     ┌───────────────┼───────────────┬────────────────┐
     ▼               ▼               ▼                ▼
WallpaperEngine  PauseStrategy  Performance    FileImporter
(渲染 + 恢复)    Manager        Monitor        (导入 + 帧率)
```

## 数据流

1. **设置变更**: 前端 → WebBridge.updateSettings → PreferencesStore → PauseStrategyManager.reevaluate()
2. **设壁纸**: 前端 → WebBridge.setWallpaper → WallpaperEngine → RestoreManager.saveSession
3. **性能轮询**: 前端 setInterval → WebBridge.getPerformanceMetrics → PerformanceMonitor.getCurrentMetrics()
4. **启动恢复**: App launch → RestoreManager.restoreSession → WallpaperEngine → PauseStrategyManager.reevaluate()

## 关键模块

### WallpaperEngine
- 管理所有屏幕的 `BasicVideoRenderer` / `HEICRenderer`
- 支持独立/全景模式
- FPS 上限通过调整 `AVQueuePlayer.rate` 实现
- 新渲染器启动后立即继承当前 pause 状态

### PauseStrategyManager
- 事件驱动（NSWorkspace 通知）+ 10s 兜底轮询
- 支持 7 种暂停条件 + 应用规则黑名单
- `reevaluate()` 供外部在设置变更后立即触发

### PerformanceMonitor
- FPS: `WallpaperEngine.getActualFPS()` = `player.rate * nominalFrameRate`
- GPU: IOKit `IOAccelerator` → `PerformanceStatistics`
- 内存: `mach_task_basic_info`
- 1.5s 轮询采样

### FrameRateBackfiller
- 启动时后台扫描 `frameRate == nil` 的视频壁纸
- 用 `AVAssetTrack.nominalFrameRate` 检测并回写

## 数据模型 (SwiftData)

| Model | 关键字段 |
|-------|---------|
| Wallpaper | id, name, filePath, type, resolution, fileSize, duration, frameRate, tags, filterPreset |
| Settings | 暂停策略开关、fpsLimit、colorSpace、appRulesJSON、音频配置 |
| Tag | name, wallpapers (多对多) |
| FilterPreset | 9 个滤镜参数 |

## 新增源文件注意事项

Xcode 项目不会自动发现新 `.swift` 文件。必须手动修改 `project.pbxproj`：
1. 新增 `PBXFileReference`
2. 新增 `PBXBuildFile`
3. 加入对应 group 的 `children`
4. 加入 `Sources` build phase 的 `files`
