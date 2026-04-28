# WKWebView 混合架构实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将前端从 SwiftUI 切换到 WKWebView + HTML 原型，后端 Swift Core 层完全不动。

**Architecture:** WKWebView 加载本地 HTML（从 v5.html 改造），通过 WKScriptMessageHandler 桥接到 AppViewModel，AppViewModel 调用现有后端单例。

**Tech Stack:** WKWebView, React (CDN local), Swift, SwiftData, AVFoundation, Core Image

---

## 文件结构

### 新增文件
- `PlumWallPaper/Sources/Bridge/WebBridge.swift` — WKScriptMessageHandler 路由层
- `PlumWallPaper/Sources/Bridge/WebViewContainer.swift` — NSViewRepresentable 包装 WKWebView
- `PlumWallPaper/Sources/Resources/Web/plumwallpaper.html` — v5.html 改造版
- `PlumWallPaper/Sources/Resources/Web/bridge.js` — JS Bridge 工具
- `PlumWallPaper/Sources/Resources/Web/react.production.min.js` — 本地 React
- `PlumWallPaper/Sources/Resources/Web/react-dom.production.min.js` — 本地 ReactDOM
- `PlumWallPaper/Sources/Resources/Web/babel.min.js` — 本地 Babel

### 修改文件
- `PlumWallPaper/Sources/App/PlumWallPaperApp.swift` — MainView 换成 WebViewContainer
- `PlumWallPaper/Sources/UI/AppViewModel.swift` — 新增 webView 引用和 JSON 序列化方法

### 删除文件
- `PlumWallPaper/Sources/UI/Views/HomeView.swift`
- `PlumWallPaper/Sources/UI/Views/LibraryView.swift`
- `PlumWallPaper/Sources/UI/Views/ColorAdjustView.swift`
- `PlumWallPaper/Sources/UI/Views/SettingsView.swift`
- `PlumWallPaper/Sources/UI/Views/ImportModalView.swift`
- `PlumWallPaper/Sources/UI/Views/MonitorSelectorView.swift`
- `PlumWallPaper/Sources/UI/Views/WallpaperDetailView.swift`
- `PlumWallPaper/Sources/UI/Components/AdjustComponents.swift`
- `PlumWallPaper/Sources/UI/Components/EdgeBorder.swift`
- `PlumWallPaper/Sources/UI/Theme.swift`

### 保留不动
- `PlumWallPaper/Sources/Core/*` — 后端全部保留
- `PlumWallPaper/Sources/Storage/*` — 存储层全部保留
- `PlumWallPaper/Sources/System/*` — 系统桥接保留

---

## Task 1: 下载 React/Babel JS 到本地 + 创建 bridge.js

**Files:**
- Create: `PlumWallPaper/Sources/Resources/Web/bridge.js`
- Create: `PlumWallPaper/Sources/Resources/Web/react.production.min.js`
- Create: `PlumWallPaper/Sources/Resources/Web/react-dom.production.min.js`
- Create: `PlumWallPaper/Sources/Resources/Web/babel.min.js`

- [ ] **Step 1: 下载 React/ReactDOM/Babel 到本地**

```bash
cd PlumWallPaper/Sources/Resources
mkdir -p Web
curl -o Web/react.production.min.js "https://unpkg.com/react@18/umd/react.production.min.js"
curl -o Web/react-dom.production.min.js "https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"
curl -o Web/babel.min.js "https://unpkg.com/@babel/standalone/babel.min.js"
```

- [ ] **Step 2: 创建 bridge.js**

```javascript
// bridge.js — JS ↔ Swift 通信桥
(function() {
  window.__pendingCallbacks = {};

  window.__bridgeCallback = function(callbackId, result) {
    const cb = window.__pendingCallbacks[callbackId];
    if (cb) {
      cb(result);
      delete window.__pendingCallbacks[callbackId];
    }
  };

  window.bridge = {
    call: function(action, params) {
      params = params || {};
      return new Promise(function(resolve, reject) {
        var callbackId = 'cb_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        window.__pendingCallbacks[callbackId] = function(result) {
          if (result.success) resolve(result.data);
          else reject(new Error(result.error || 'Unknown error'));
        };
        window.webkit.messageHandlers.bridge.postMessage(
          Object.assign({ action: action, callbackId: callbackId }, params)
        );
      });
    }
  };
})();
```

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/Resources/Web/
git commit -m "feat: add local React/Babel JS and bridge.js"
```

---

## Task 2: WebBridge.swift — JS → Swift 路由层

**Files:**
- Create: `PlumWallPaper/Sources/Bridge/WebBridge.swift`

## Task 2: WebBridge.swift — JS → Swift 路由层

**Files:**
- Create: `PlumWallPaper/Sources/Bridge/WebBridge.swift`

- [ ] **Step 1: 创建 WebBridge.swift 骨架**

```swift
import Foundation
import WebKit
import SwiftData

@MainActor
class WebBridge: NSObject, WKScriptMessageHandler {
    weak var viewModel: AppViewModel?
    weak var webView: WKWebView?
    weak var modelContext: ModelContext?
    
    init(viewModel: AppViewModel, modelContext: ModelContext) {
        self.viewModel = viewModel
        self.modelContext = modelContext
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String,
              let callbackId = body["callbackId"] as? String else {
            return
        }
        
        Task {
            await handleAction(action: action, params: body, callbackId: callbackId)
        }
    }
    
    private func handleAction(action: String, params: [String: Any], callbackId: String) async {
        // 路由逻辑在后续步骤补充
    }
    
    private func sendCallback(callbackId: String, success: Bool, data: Any? = nil, error: String? = nil) {
        var result: [String: Any] = ["success": success]
        if let data = data {
            result["data"] = data
        }
        if let error = error {
            result["error"] = error
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let js = "window.__bridgeCallback('\(callbackId)', \(jsonString))"
        webView?.evaluateJavaScript(js)
    }
}
```

- [ ] **Step 2: 实现 getWallpapers action**

在 `handleAction` 方法中添加：

```swift
private func handleAction(action: String, params: [String: Any], callbackId: String) async {
    guard let vm = viewModel, let ctx = modelContext else {
        sendCallback(callbackId: callbackId, success: false, error: "ViewModel or context not available")
        return
    }
    
    switch action {
    case "getWallpapers":
        do {
            let store = WallpaperStore(modelContext: ctx)
            let wallpapers = try store.fetchAllWallpapers()
            let data = wallpapers.map { wallpaperToDict($0) }
            sendCallback(callbackId: callbackId, success: true, data: data)
        } catch {
            sendCallback(callbackId: callbackId, success: false, error: error.localizedDescription)
        }
        
    default:
        sendCallback(callbackId: callbackId, success: false, error: "Unknown action: \(action)")
    }
}

private func wallpaperToDict(_ w: Wallpaper) -> [String: Any] {
    return [
        "id": w.id.uuidString,
        "name": w.name,
        "filePath": "file://\(w.filePath)",
        "thumbnailPath": "file://\(w.thumbnailPath)",
        "type": w.type == .video ? "video" : "image",
        "resolution": w.resolution,
        "fileSize": w.fileSize,
        "duration": w.duration ?? 0,
        "isFavorite": w.isFavorite,
        "tags": w.tags.map { ["id": $0.id.uuidString, "name": $0.name, "color": $0.color ?? ""] }
    ]
}
```

- [ ] **Step 3: 实现 importFiles action**

在 `switch action` 中添加：

```swift
case "importFiles":
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [.movie, .image]
    
    if panel.runModal() == .OK {
        await vm.importFiles(urls: panel.urls, context: ctx)
        sendCallback(callbackId: callbackId, success: true, data: ["imported": panel.urls.count])
    } else {
        sendCallback(callbackId: callbackId, success: false, error: "User cancelled")
    }
```

- [ ] **Step 4: 实现 setWallpaper action**

在 `switch action` 中添加：

```swift
case "setWallpaper":
    guard let wallpaperIdStr = params["wallpaperId"] as? String,
          let wallpaperId = UUID(uuidString: wallpaperIdStr) else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid wallpaperId")
        return
    }
    
    let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == wallpaperId })
    guard let wallpaper = try? ctx.fetch(descriptor).first else {
        sendCallback(callbackId: callbackId, success: false, error: "Wallpaper not found")
        return
    }
    
    if let screenIdStr = params["screenId"] as? String {
        if let screen = vm.display.availableScreens.first(where: { $0.id == screenIdStr }) {
            vm.setWallpaper(wallpaper, for: screen)
            sendCallback(callbackId: callbackId, success: true)
        } else {
            sendCallback(callbackId: callbackId, success: false, error: "Screen not found")
        }
    } else {
        vm.smartSetWallpaper(wallpaper)
        sendCallback(callbackId: callbackId, success: true)
    }
```

- [ ] **Step 5: 实现其余 actions（toggleFavorite, deleteWallpaper, applyFilter, getScreens, getSettings, updateSettings, getTags, createTag, deleteTag）**

在 `switch action` 中继续添加：

```swift
case "toggleFavorite":
    guard let wallpaperIdStr = params["wallpaperId"] as? String,
          let wallpaperId = UUID(uuidString: wallpaperIdStr) else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid wallpaperId")
        return
    }
    let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == wallpaperId })
    if let wallpaper = try? ctx.fetch(descriptor).first {
        wallpaper.isFavorite.toggle()
        try? ctx.save()
        sendCallback(callbackId: callbackId, success: true, data: ["isFavorite": wallpaper.isFavorite])
    } else {
        sendCallback(callbackId: callbackId, success: false, error: "Wallpaper not found")
    }

case "deleteWallpaper":
    guard let wallpaperIdStr = params["wallpaperId"] as? String,
          let wallpaperId = UUID(uuidString: wallpaperIdStr) else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid wallpaperId")
        return
    }
    do {
        let store = WallpaperStore(modelContext: ctx)
        try store.deleteWallpaper(id: wallpaperId)
        sendCallback(callbackId: callbackId, success: true)
    } catch {
        sendCallback(callbackId: callbackId, success: false, error: error.localizedDescription)
    }

case "applyFilter":
    guard let wallpaperIdStr = params["wallpaperId"] as? String,
          let wallpaperId = UUID(uuidString: wallpaperIdStr),
          let presetDict = params["preset"] as? [String: Any] else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid parameters")
        return
    }
    let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == wallpaperId })
    if let wallpaper = try? ctx.fetch(descriptor).first {
        let preset = FilterPreset(name: "Custom")
        preset.exposure = presetDict["exposure"] as? Double ?? 0
        preset.contrast = presetDict["contrast"] as? Double ?? 1
        preset.saturation = presetDict["saturation"] as? Double ?? 1
        preset.hue = presetDict["hue"] as? Double ?? 0
        preset.blur = presetDict["blur"] as? Double ?? 0
        preset.grain = presetDict["grain"] as? Double ?? 0
        preset.vignette = presetDict["vignette"] as? Double ?? 0
        preset.grayscale = presetDict["grayscale"] as? Bool ?? false
        preset.invert = presetDict["invert"] as? Bool ?? false
        
        wallpaper.filterPreset = preset
        try? ctx.save()
        vm.applyFilter(preset, to: wallpaper)
        sendCallback(callbackId: callbackId, success: true)
    } else {
        sendCallback(callbackId: callbackId, success: false, error: "Wallpaper not found")
    }

case "getScreens":
    let screens = vm.display.availableScreens.map { screen in
        return [
            "id": screen.id,
            "name": screen.name,
            "resolution": "\(Int(screen.frame.width))×\(Int(screen.frame.height))",
            "isMain": screen.isMain
        ]
    }
    sendCallback(callbackId: callbackId, success: true, data: screens)

case "getSettings":
    do {
        let descriptor = FetchDescriptor<Settings>()
        let settings = try ctx.fetch(descriptor).first ?? Settings()
        let data: [String: Any] = [
            "slideshowEnabled": settings.slideshowEnabled,
            "slideshowInterval": settings.slideshowInterval,
            "vSyncEnabled": settings.vSyncEnabled,
            "pauseOnBattery": settings.pauseOnBattery
            // 其余字段按需添加
        ]
        sendCallback(callbackId: callbackId, success: true, data: data)
    } catch {
        sendCallback(callbackId: callbackId, success: false, error: error.localizedDescription)
    }

case "updateSettings":
    guard let settingsDict = params["settings"] as? [String: Any] else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid settings")
        return
    }
    do {
        let descriptor = FetchDescriptor<Settings>()
        let settings = try ctx.fetch(descriptor).first ?? Settings()
        if let val = settingsDict["slideshowEnabled"] as? Bool {
            settings.slideshowEnabled = val
        }
        if let val = settingsDict["slideshowInterval"] as? TimeInterval {
            settings.slideshowInterval = val
        }
        // 其余字段按需更新
        try ctx.save()
        sendCallback(callbackId: callbackId, success: true)
    } catch {
        sendCallback(callbackId: callbackId, success: false, error: error.localizedDescription)
    }

case "getTags":
    do {
        let descriptor = FetchDescriptor<Tag>()
        let tags = try ctx.fetch(descriptor)
        let data = tags.map { ["id": $0.id.uuidString, "name": $0.name, "color": $0.color ?? ""] }
        sendCallback(callbackId: callbackId, success: true, data: data)
    } catch {
        sendCallback(callbackId: callbackId, success: false, error: error.localizedDescription)
    }

case "createTag":
    guard let name = params["name"] as? String else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid name")
        return
    }
    let tag = Tag(name: name, color: params["color"] as? String)
    ctx.insert(tag)
    try? ctx.save()
    sendCallback(callbackId: callbackId, success: true, data: ["id": tag.id.uuidString])

case "deleteTag":
    guard let tagIdStr = params["tagId"] as? String,
          let tagId = UUID(uuidString: tagIdStr) else {
        sendCallback(callbackId: callbackId, success: false, error: "Invalid tagId")
        return
    }
    let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == tagId })
    if let tag = try? ctx.fetch(descriptor).first {
        ctx.delete(tag)
        try? ctx.save()
        sendCallback(callbackId: callbackId, success: true)
    } else {
        sendCallback(callbackId: callbackId, success: false, error: "Tag not found")
    }
```

- [ ] **Step 6: 提交**

```bash
git add PlumWallPaper/Sources/Bridge/WebBridge.swift
git commit -m "feat: add WebBridge with all action handlers"
```
---

## Task 3: WebViewContainer.swift — WKWebView 包装

**Files:**
- Create: `PlumWallPaper/Sources/Bridge/WebViewContainer.swift`

## Task 3: WebViewContainer.swift — WKWebView 包装

**Files:**
- Create: `PlumWallPaper/Sources/Bridge/WebViewContainer.swift`

- [ ] **Step 1: 创建 WebViewContainer.swift**

```swift
import SwiftUI
import WebKit

struct WebViewContainer: NSViewRepresentable {
    let viewModel: AppViewModel
    let modelContext: ModelContext
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        let bridge = WebBridge(viewModel: viewModel, modelContext: modelContext)
        contentController.add(bridge, name: "bridge")
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        
        bridge.webView = webView
        viewModel.webView = webView
        
        if let htmlURL = Bundle.main.url(forResource: "plumwallpaper", withExtension: "html", subdirectory: "Resources/Web") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: NSHomeDirectory()))
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No-op
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add PlumWallPaper/Sources/Bridge/WebViewContainer.swift
git commit -m "feat: add WebViewContainer NSViewRepresentable"
```
---

## Task 4: 改造 PlumWallPaperApp.swift

**Files:**
- Modify: `PlumWallPaper/Sources/App/PlumWallPaperApp.swift`
- Modify: `PlumWallPaper/Sources/UI/AppViewModel.swift`

## Task 4: 改造 PlumWallPaperApp.swift + AppViewModel

**Files:**
- Modify: `PlumWallPaper/Sources/App/PlumWallPaperApp.swift`
- Modify: `PlumWallPaper/Sources/UI/AppViewModel.swift`

- [ ] **Step 1: 在 AppViewModel 添加 webView 引用**

在 `AppViewModel.swift` 的类定义顶部添加：

```swift
weak var webView: WKWebView?
```

- [ ] **Step 2: 改造 PlumWallPaperApp.swift 的 body**

将 `PlumWallPaperApp.swift` 的 `body` 改为：

```swift
var body: some Scene {
    WindowGroup {
        WebViewContainer(viewModel: viewModel, modelContext: modelContainer.mainContext)
            .preferredColorScheme(.dark)
            .task {
                await viewModel.restoreLastSession(context: modelContainer.mainContext)
            }
            .onAppear {
                if let window = NSApplication.shared.windows.first {
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.styleMask.insert(.fullSizeContentView)
                }
            }
    }
    .windowStyle(HiddenTitleBarWindowStyle())
    .commands {
        CommandGroup(replacing: .appTermination) {
            Button("退出 PlumWallPaper") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
```

删除原有的 `MainView` 结构体和 `NavActionBtn` 结构体。

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/App/PlumWallPaperApp.swift PlumWallPaper/Sources/UI/AppViewModel.swift
git commit -m "feat: replace SwiftUI MainView with WebViewContainer"
```
---

## Task 5: 改造 v5.html → plumwallpaper.html

**Files:**
- Create: `PlumWallPaper/Sources/Resources/Web/plumwallpaper.html`

## Task 5: 改造 v5.html → plumwallpaper.html

**Files:**
- Create: `PlumWallPaper/Sources/Resources/Web/plumwallpaper.html`

这是最核心的改造任务。从 `ui-prototype/plumwallpaper-v5.html` 复制，做以下修改：

- [ ] **Step 1: 复制 v5.html 并替换 CDN 引用**

```bash
cp ui-prototype/plumwallpaper-v5.html PlumWallPaper/Sources/Resources/Web/plumwallpaper.html
```

在 `plumwallpaper.html` 中替换 head 部分：

把：
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400;1,500;1,600&family=Inter:wght@100;200;300;400;500;600;700&display=swap" rel="stylesheet">

<script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
```

改为：
```html
<style>
  @font-face {
    font-family: 'Cormorant Garamond';
    src: url('../Fonts/CormorantGaramond-Italic.ttf') format('truetype');
    font-style: italic;
    font-weight: 300 500;
  }
  @font-face {
    font-family: 'Cormorant Garamond';
    src: url('../Fonts/CormorantGaramond-SemiBoldItalic.ttf') format('truetype');
    font-style: italic;
    font-weight: 600 700;
  }
</style>

<script src="react.production.min.js"></script>
<script src="react-dom.production.min.js"></script>
<script src="babel.min.js"></script>
<script src="bridge.js"></script>
```

- [ ] **Step 2: 删除 MOCK_WALLPAPERS 和 MONITORS，改为 Bridge 调用**

在 `<script type="text/babel">` 开头，删除 `MOCK_WALLPAPERS` 数组（第 79-88 行）和 `MONITORS` 数组（第 90-93 行）。

在 `App` 组件中，把：
```javascript
const [wallpapers, setWallpapers] = useState(MOCK_WALLPAPERS);
```

改为：
```javascript
const [wallpapers, setWallpapers] = useState([]);
const [activeMonitors, setActiveMonitors] = useState([]);

useEffect(() => {
  bridge.call('getWallpapers').then(data => setWallpapers(data));
  bridge.call('getScreens').then(data => setActiveMonitors(data));
}, []);

const refreshWallpapers = () => {
  bridge.call('getWallpapers').then(data => setWallpapers(data));
};
```

- [ ] **Step 3: 改造壁纸数据字段映射**

v5.html 的 Mock 数据用 `img` 字段，真实数据用 `thumbnailPath`。全局搜索替换：
- `w.img` → `w.thumbnailPath`
- `wallpaper.img` → `wallpaper.thumbnailPath`
- `hero.img` → `hero.thumbnailPath`

同时 `w.fav` → `w.isFavorite`，`w.type` 保持不变（后端已返回 "video" / "image"）。

`w.size` → 格式化 `w.fileSize`（后端返回字节数），在 HTML 中添加工具函数：
```javascript
const formatSize = (bytes) => {
  if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + 'GB';
  if (bytes >= 1048576) return (bytes / 1048576).toFixed(0) + 'MB';
  return (bytes / 1024).toFixed(0) + 'KB';
};

const formatDuration = (seconds) => {
  if (!seconds || seconds <= 0) return '-';
  const m = Math.floor(seconds / 60).toString().padStart(2, '0');
  const s = Math.floor(seconds % 60).toString().padStart(2, '0');
  return m + ':' + s;
};
```

- [ ] **Step 4: 改造按钮事件为 Bridge 调用**

"设为壁纸" 按钮：
```javascript
const handleSetWallpaper = (wallpaper) => {
  bridge.call('setWallpaper', { wallpaperId: wallpaper.id }).then(() => {
    addToast('已成功设为桌面壁纸');
  });
};
```

"导入" 按钮：
```javascript
const handleImport = () => {
  bridge.call('importFiles').then((result) => {
    addToast('已导入 ' + result.imported + ' 个壁纸');
    refreshWallpapers();
    setShowImport(false);
  }).catch(() => {});
};
```

"收藏" 按钮：
```javascript
const handleToggleFavorite = (wallpaper) => {
  bridge.call('toggleFavorite', { wallpaperId: wallpaper.id }).then((result) => {
    refreshWallpapers();
  });
};
```

"删除" 按钮：
```javascript
const handleDelete = (wallpaper) => {
  bridge.call('deleteWallpaper', { wallpaperId: wallpaper.id }).then(() => {
    addToast('已从库中移除');
    refreshWallpapers();
  });
};
```

MonitorSelector 的 onApply：
```javascript
const handleMonitorApply = (type, screenId) => {
  if (type === 'all') {
    bridge.call('setWallpaper', { wallpaperId: selectedWallpaper.id });
  } else {
    bridge.call('setWallpaper', { wallpaperId: selectedWallpaper.id, screenId: screenId });
  }
  setShowMonitorPopup(false);
  addToast(type === 'all' ? '已应用到所有显示器' : '已成功设为桌面壁纸');
};
```

- [ ] **Step 5: 改造设置页为 Bridge 调用**

设置页加载时：
```javascript
useEffect(() => {
  bridge.call('getSettings').then(data => setSettings(data));
}, []);
```

设置项变更时：
```javascript
const updateSetting = (key, value) => {
  const newSettings = { ...settings, [key]: value };
  setSettings(newSettings);
  bridge.call('updateSettings', { settings: newSettings });
};
```

- [ ] **Step 6: 改造色彩调节为 Bridge 调用**

应用滤镜：
```javascript
const handleApplyFilter = (wallpaper, preset) => {
  bridge.call('applyFilter', { wallpaperId: wallpaper.id, preset: preset }).then(() => {
    addToast('滤镜已应用');
  });
};
```

- [ ] **Step 7: 提交**

```bash
git add PlumWallPaper/Sources/Resources/Web/plumwallpaper.html
git commit -m "feat: convert v5.html to bridge-powered plumwallpaper.html"
```
---

## Task 6: 删除 SwiftUI 视图文件

**Files:**
- Delete: 10 个 SwiftUI 视图/组件/Theme 文件

## Task 6: 删除 SwiftUI 视图文件

**Files:**
- Delete: 10 个文件

- [ ] **Step 1: 删除 SwiftUI 视图和组件**

```bash
rm PlumWallPaper/Sources/UI/Views/HomeView.swift
rm PlumWallPaper/Sources/UI/Views/LibraryView.swift
rm PlumWallPaper/Sources/UI/Views/ColorAdjustView.swift
rm PlumWallPaper/Sources/UI/Views/SettingsView.swift
rm PlumWallPaper/Sources/UI/Views/ImportModalView.swift
rm PlumWallPaper/Sources/UI/Views/MonitorSelectorView.swift
rm PlumWallPaper/Sources/UI/Views/WallpaperDetailView.swift
rm PlumWallPaper/Sources/UI/Components/AdjustComponents.swift
rm PlumWallPaper/Sources/UI/Components/EdgeBorder.swift
rm PlumWallPaper/Sources/UI/Theme.swift
```

- [ ] **Step 2: 提交**

```bash
git add -A
git commit -m "refactor: remove SwiftUI views replaced by WKWebView HTML"
```
---

## Task 7: 重新生成 xcodeproj + 构建验证

**Files:**
- Modify: `PlumWallPaper/project.yml`

## Task 7: 更新 project.yml + 重新生成 xcodeproj + 构建验证

**Files:**
- Modify: `PlumWallPaper/project.yml`

- [ ] **Step 1: 更新 project.yml 的 sources 配置**

在 `project.yml` 的 `targets.PlumWallPaper.sources` 中，确保包含 `Resources/Web/` 目录：

```yaml
sources:
  - path: Sources
  - path: Resources
    type: folder
    buildPhase: resources
```

- [ ] **Step 2: 重新生成 xcodeproj**

```bash
cd PlumWallPaper
xcodegen generate
```

Expected: `Created project at /Users/Alex/AI/project/PlumWallPaper/PlumWallPaper/PlumWallPaper.xcodeproj`

- [ ] **Step 3: 清理并构建**

```bash
rm -rf .build
xcodebuild -project "PlumWallPaper.xcodeproj" -scheme "PlumWallPaper" -configuration Debug -derivedDataPath ".build/DerivedData" -arch arm64 build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 启动验证**

```bash
open ".build/DerivedData/Build/Products/Debug/PlumWallPaper.app"
```

Expected: App 启动，显示 HTML 界面，首页加载壁纸列表（如果 SwiftData 有数据）。

- [ ] **Step 5: 手动测试 6 条路径**

1. 启动 → 首页显示壁纸列表（从 SwiftData 读取）
2. 点 + → NSOpenPanel → 导入 → 列表刷新
3. 点"设为壁纸" → 桌面变化
4. 色彩调节 → 应用 → 桌面变化
5. 设置页 → 修改选项 → 持久化
6. 重启 → 壁纸恢复

- [ ] **Step 6: 提交**

```bash
git add PlumWallPaper/project.yml PlumWallPaper/PlumWallPaper.xcodeproj/
git commit -m "chore: update project.yml for WKWebView resources and regenerate xcodeproj"
```

---

## 完成标准

- [ ] 所有 7 个 Task 的步骤全部完成
- [ ] 构建成功（`BUILD SUCCEEDED`）
- [ ] App 启动显示 HTML 界面
- [ ] 6 条手动测试路径全部通过
- [ ] 所有变更已提交到 git
