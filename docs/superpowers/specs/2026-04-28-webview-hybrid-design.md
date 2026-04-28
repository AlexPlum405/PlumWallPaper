# WKWebView 混合架构设计文档

日期：2026-04-28
状态：已确认，待实现

## 目标

将 PlumWallPaper 的前端从 SwiftUI 切换到 WKWebView + HTML，直接复用现有 HTML 原型（v5.html），后端 Swift Core 层完全不动。

## 关键决策

| 议题 | 选择 |
|------|------|
| 前端方案 | 直接用 v5.html（已含 React） |
| 离线依赖 | React/Babel JS 下载到本地 Resources |
| 本地文件访问 | `loadFileURL` 授权本地目录 |
| 设置页 | 也用 HTML，全部统一 |
| 通信协议 | `WKScriptMessageHandler` + `evaluateJavaScript` |

## 架构

```
┌──────────────────────────────────────────┐
│  WKWebView                               │
│  ┌────────────────────────────────────┐  │
│  │  plumwallpaper.html (v5 改造)       │  │
│  │  React 组件 (内嵌)                  │  │
│  │  本地 React/Babel JS               │  │
│  │                                    │  │
│  │  window.webkit.messageHandlers     │  │
│  │    .bridge.postMessage({...})      │  │
│  └────────────────────────────────────┘  │
│                                          │
│  webView.evaluateJavaScript(...)         │
├──────────────────────────────────────────┤
│  Swift Bridge Layer                      │
│  ┌────────────────────────────────────┐  │
│  │  WebBridge.swift                   │  │
│  │  - WKScriptMessageHandler          │  │
│  │  - 路由 action → AppViewModel      │  │
│  │  - 回调结果 → evaluateJavaScript   │  │
│  └────────────────────────────────────┘  │
├──────────────────────────────────────────┤
│  Swift Backend (完全不动)                │
│  AppViewModel / WallpaperEngine /        │
│  FilterEngine / FileImporter /           │
│  DisplayManager / RestoreManager         │
└──────────────────────────────────────────┘
```

## Bridge 接口

### JS → Swift

```javascript
// 壁纸管理
{ action: "getWallpapers", callbackId }
{ action: "importFiles", callbackId }
{ action: "setWallpaper", wallpaperId, screenId?, callbackId }
{ action: "toggleFavorite", wallpaperId, callbackId }
{ action: "deleteWallpaper", wallpaperId, callbackId }

// 滤镜
{ action: "applyFilter", wallpaperId, preset: {...}, callbackId }
{ action: "removeFilter", wallpaperId, callbackId }

// 显示器
{ action: "getScreens", callbackId }

// 设置
{ action: "getSettings", callbackId }
{ action: "updateSettings", settings: {...}, callbackId }

// 标签
{ action: "getTags", callbackId }
{ action: "createTag", name, color, callbackId }
{ action: "deleteTag", tagId, callbackId }
```

### Swift → JS

```javascript
window.__bridgeCallback(callbackId, { success: true, data: {...} })
window.__bridgeCallback(callbackId, { success: false, error: "..." })
```

### JS 侧封装

```javascript
window.bridge = {
  call: (action, params = {}) => {
    return new Promise((resolve, reject) => {
      const callbackId = `cb_${Date.now()}_${Math.random()}`;
      window.__pendingCallbacks = window.__pendingCallbacks || {};
      window.__pendingCallbacks[callbackId] = (result) => {
        if (result.success) resolve(result.data);
        else reject(result.error);
      };
      window.webkit.messageHandlers.bridge.postMessage({
        action, callbackId, ...params
      });
    });
  }
};
```

## 启动流程

1. `PlumWallPaperApp` 初始化 `ModelContainer` 和 `AppViewModel`
2. 创建 `WKWebView`，配置 `WKUserContentController` 注册 `bridge` handler
3. `loadFileURL(Resources/Web/plumwallpaper.html, allowingReadAccessTo: NSHomeDirectory())`
4. HTML 加载完成后，自动调用 `bridge.call('getWallpapers')` 初始化数据
5. `AppViewModel.restoreLastSession()` 恢复壁纸

## 文件路径映射

- Swift 侧存储绝对路径：`/Users/Alex/Pictures/PlumWallPaper/xxx.mp4`
- 传给 HTML 时：`file:///Users/Alex/Pictures/PlumWallPaper/xxx.mp4`
- HTML `<img src="file://...">` 直接显示（`allowingReadAccessTo` 已授权）

## 数据同步

- HTML 不缓存数据，每次切换页面调用 `getWallpapers` 重新拉取
- 后续优化：Swift 侧监听 SwiftData 变化，主动推送更新到 HTML

## 错误处理

| 场景 | 行为 |
|------|------|
| Bridge 调用失败 | Swift 返回 `{ success: false, error }`, HTML 显示 toast |
| 文件导入部分失败 | 返回成功列表 + 失败列表，HTML 显示汇总 |
| 本地字体加载失败 | 回退到系统 serif 字体 |
| WKWebView 加载失败 | 显示原生错误页 |

## 文件变更

### 新增

| 文件 | 说明 |
|------|------|
| `Sources/Bridge/WebBridge.swift` | WKScriptMessageHandler，路由 JS 调用 |
| `Sources/Bridge/WebViewContainer.swift` | NSViewRepresentable 包装 WKWebView |
| `Resources/Web/plumwallpaper.html` | v5.html 改造版 |
| `Resources/Web/bridge.js` | Promise 封装的 JS Bridge |
| `Resources/Web/react.production.min.js` | 本地 React |
| `Resources/Web/react-dom.production.min.js` | 本地 ReactDOM |
| `Resources/Web/babel.min.js` | 本地 Babel |

### 修改

| 文件 | 改动 |
|------|------|
| `Sources/App/PlumWallPaperApp.swift` | MainView → WebViewContainer |
| `Sources/UI/AppViewModel.swift` | 新增 webView 引用 |

### 删除

| 文件 | 原因 |
|------|------|
| `Sources/UI/Views/*.swift` (7 个) | 被 HTML 替代 |
| `Sources/UI/Components/*.swift` (2 个) | 被 HTML 替代 |
| `Sources/UI/Theme.swift` | 被 HTML CSS 替代 |

### 保留不动

| 目录 | 原因 |
|------|------|
| `Sources/Core/*` | 后端全部保留 |
| `Sources/Storage/*` | 存储层全部保留 |
| `Sources/System/*` | 系统桥接保留 |
| `Sources/UI/AppViewModel.swift` | Bridge 层调用它 |

## v5.html 改造要点

1. CDN 引用改为本地路径：
   - `https://unpkg.com/react@18/...` → `react.production.min.js`
   - `https://unpkg.com/react-dom@18/...` → `react-dom.production.min.js`
   - `https://unpkg.com/@babel/standalone/...` → `babel.min.js`
2. Google Fonts 改为本地字体 `@font-face`
3. `MOCK_WALLPAPERS` 删除，改为 `bridge.call('getWallpapers')` 获取
4. `MONITORS` 删除，改为 `bridge.call('getScreens')` 获取
5. 所有按钮事件改为 `bridge.call(...)` 调用
6. 设置页从 Mock 改为 `bridge.call('getSettings')` / `bridge.call('updateSettings')`

## 测试策略

手动验证 6 条路径：
1. 启动 → 首页显示壁纸列表（从 SwiftData 读取）
2. 点 + → NSOpenPanel → 导入 → 列表刷新
3. 点"设为壁纸" → 桌面变化
4. 色彩调节 → 应用 → 桌面变化
5. 设置页 → 修改选项 → 持久化
6. 重启 → 壁纸恢复

## 不在本轮范围

- Swift 主动推送数据变更到 HTML（后续优化）
- 预编译 JSX 去掉 Babel（后续优化）
- Service Worker 离线缓存
- 自动更新机制
