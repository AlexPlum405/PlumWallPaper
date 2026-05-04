# 添加 SwiftSoup 依赖

> **说明**: 本文中的手动添加步骤主要适用于早期未纳入 XcodeGen 的阶段。当前仓库已经在 `project.yml` 中声明了 SwiftSoup 依赖，优先做法是运行 `xcodegen generate` 并直接用项目构建，而不是手动改 `project.pbxproj`。

MediaService 需要 SwiftSoup 来解析 HTML。请按以下步骤添加：

## 方法 1：通过 Xcode（推荐）

1. 在 Xcode 中打开 `PlumWallPaper.xcodeproj`
2. 选择项目文件（左侧导航栏最顶部）
3. 选择 "PlumWallPaper" target
4. 点击 "Package Dependencies" 标签
5. 点击 "+" 按钮
6. 输入 URL: `https://github.com/scinfu/SwiftSoup.git`
7. 选择版本规则：Up to Next Major Version，从 2.0.0 开始
8. 点击 "Add Package"
9. 确认将 SwiftSoup 添加到 PlumWallPaper target

## 方法 2：手动编辑（如果方法1不可用）

编辑 `PlumWallPaper.xcodeproj/project.pbxproj`，添加以下内容到 package dependencies 部分：

```
XCRemoteSwiftPackageReference "SwiftSoup" {
    repositoryURL = "https://github.com/scinfu/SwiftSoup.git";
    requirement = {
        kind = upToNextMajorVersion;
        minimumVersion = 2.0.0;
    };
}
```

## 验证

添加后，在 MediaService.swift 顶部应该能看到：
```swift
import SwiftSoup
```

如果编译通过，说明依赖添加成功。
