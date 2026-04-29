# PlumWallPaper 项目约定

## 架构概览

- **UI 层**: SwiftUI (MVVM 模式)
- **渲染引擎**: Metal
- **数据持久化**: SwiftData
- **构建**: Xcode project (`PlumWallPaper.xcodeproj`)，macOS 14.0+
- **项目生成**: XcodeGen (`project.yml`)

## 关键路径

| 模块 | 路径 |
|------|------|
| 应用入口 | `Sources/App/PlumWallPaperApp.swift` |
| 应用代理 | `Sources/App/AppDelegate.swift` |
| 主视图 | `Sources/Views/ContentView.swift` |
| 数据模型 | `Sources/Storage/Models/` |
| 渲染引擎 | `Sources/Engine/` (待实现) |
| 显示管理 | `Sources/Core/DisplayManager/` (待实现) |
| 壁纸引擎 | `Sources/Core/WallpaperEngine/` (待实现) |
| 视图模型 | `Sources/ViewModels/` (待实现) |
| 系统集成 | `Sources/System/` (待实现) |

## 构建命令

```bash
# 生成 Xcode 项目（修改 project.yml 后）
xcodegen generate

# 构建
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

## 开发约定

- 使用 XcodeGen 管理项目结构，修改 `project.yml` 后运行 `xcodegen generate`
- 新增源文件放入 `Sources/` 对应子目录，XcodeGen 会自动包含
- SwiftUI 视图遵循 MVVM 模式，视图模型放在 `Sources/ViewModels/`
- SwiftData 模型放在 `Sources/Storage/Models/`，使用 `@Model` 宏
- Metal 着色器文件放在 `Sources/Engine/Shaders/`
- 资源文件放在 `Sources/Resources/`

## 项目状态（2026-04-30）

### Phase 1: SwiftUI + Metal 重写（进行中）

**已完成**:
- ✅ Task 1: Xcode 项目骨架
  - 目录结构
  - SwiftUI NavigationSplitView 骨架
  - SwiftData 模型占位符（Wallpaper, Tag, ShaderPreset, Settings）
  - AppIcon 资源
  - XcodeGen 配置

**待完成**:
- Task 2: SwiftData 模型层
- Task 3: Metal 渲染引擎
- Task 4: 壁纸库视图
- Task 5: 着色器编辑器
- Task 6: 设置页面
- Task 7: 多显示器支持
- Task 8: 性能监控

---
*上次更新: 2026-04-30*
