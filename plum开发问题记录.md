1.顶部不需要边框，纯透明，hero壁纸可以直接显示到顶部。顶部只保留红绿灯在透明背景上
2.背景颜色不是纯黑，复刻原型的背景颜色
3.副屏设置壁纸还是显示错误


  主要改哪些文件

  1. 页面样式主文件
    - Sources/Resources/Web/plumwallpaper.html
    - 这里基本包含了全部前端
  UI：TopNav、HomePage、LibraryPage、SettingsPage、动画、CSS、React 状态
    - 绝大多数视觉优化都应该只改这个文件
  2. WKWebView 和窗口渲染相关
    - Sources/Bridge/WebViewContainer.swift
    - 这里控制 WebView 的透明、resize snapshot、live resize 行为
    - 涉及“最大化动画丝滑度”“WebView 重绘”“透明内容区域”时改这里
  3. macOS 窗口 titlebar / 透明边框 / 拖拽
    - Sources/App/PlumWallPaperApp.swift
    - 这里控制 titlebarAppearsTransparent、fullSizeContentView、窗口行为
    - 涉及“白边”“拖不动窗口”“红绿灯区域”时改这里
  4. 不要随便动，除非要改桥接协议
    - Sources/Bridge/WebBridge.swift
    - 这里定义 bridge.call("xxx") 的 action 和参数
    - 改错最容易直接导致前端按钮失效、导入失效、收藏失效

  ---
  让 Gemini 优化但不容易报错的规则

  你可以直接把下面这段发给它：

  请只优化样式和前端结构，优先修改：
  - Sources/Resources/Web/plumwallpaper.html
  必要时可修改：
  - Sources/Bridge/WebViewContainer.swift
  - Sources/App/PlumWallPaperApp.swift

  严格遵守这些规则：
  1. 不要改 bridge.call 的 action 名称
  2. 不要改传给 bridge.call 的字段名，例如
  wallpaperId、screenId、paths、tag、favorite、name、settings
  3. 不要删除或重命名 React 组件对外依赖的 state / props
  4. 不要把 tag 当字符串直接渲染，tag 要用 tag.name
  5. 不要改 WebBridge.swift 的接口协议，除非前后端一起改
  6. 只做 UI/样式/布局优化，不改业务逻辑
  7. 不要新增打包体系，不要改成 npm/react 工程，当前是单文件 HTML + Babel 运行方式
  8. 不要把本地 file:// 路径改成网络 URL
  9. 如果要做窗口顶部透明化，请保留红绿灯区域，并明确设计一个可拖拽带
  10. 所有改动必须避免影响：收藏、导入、搜索、设为壁纸、右键菜单、设置页

  ---
  最稳的优化边界

  只让 Gemini 改 plumwallpaper.html，这是最安全的。
  因为这个项目现在前端几乎全在这个文件里，视觉、间距、颜色、卡片、导航、动画都在这里，改这里
  通常不会碰到 SwiftData、Bridge、桌面壁纸引擎这些容易炸的部分。

  ---
  如果你想让 Gemini 处理“顶部透明 + 可拖拽”

  要额外告诉它：

  目标不是去掉整个 titlebar，而是：
  - 顶部视觉透明
  - hero 壁纸延伸到顶部
  - 红绿灯保留
  - 必须保留一个可拖动窗口的安全区域
  - 不要让按钮区域变成拖拽区

  ---
  我建议它的职责这样分

  - Gemini 做：颜色、层级、透明材质、导航布局、间距、hover、字体、hero
  顶部延伸、拖拽带的前端留白
  - 我来做：PlumWallPaperApp.swift、WebViewContainer.swift、WebBridge.swift、WallpaperEngine
  .swift 这些跟 macOS 窗口、渲染、桥接、壁纸引擎有关的稳定性修复

  这样最不容易引入新报错。
  
  
  
  plumwallpaper-v5.html这个原型文件。复制v5原型的色彩设置页，然后基于此进行优化改造，
   在一个html里通过tab切换，给我三个不同的设计方案（都基于ui-prototype/demo-4-pure-transpare
   nt.html的纯粹悬浮风格。
   设计特点：面板背景完全透明（transparent）。去掉了所有的遮罩和色彩层，只有极其干净的滑
   动条和文字直接悬浮在壁纸上方。为了防止壁纸太亮导致看不清，仅对文字加了最细微的黑边文字阴影）
   
   
open "/Users/Alex/Library/Developer/Xcode/DerivedData/PlumWallPaper-daqsaqfuiprqyfgysecnui uutpto/Build/Products/Debug/PlumWallPaper.app"


1.导入视频时，新增分类点击保存后，应该直接排布在原来的分类列表里
2.



❯ 现在顺序为我解释，设置页所有功能和switch分别是什么功能，前后端是什么交互逻辑，当前怎么实
  现的。

⏺ 我先把设置页当前代码完整过一遍，确保解释基于最新状态。

  Read 1 file (ctrl+o to expand)

⏺ 现在我按 tab 顺序逐项解释每个功能的前后端交互逻辑：

  ---
  设置页功能详解（按 Tab 分组）

  📐 通用 Tab

  1. 显示器拓扑布局（纯展示）

  - 功能：可视化展示当前连接的所有显示器，主屏幕用红色边框高亮
  - 前端实现：从 monitors state 读取（来自 bridge.call('getScreens')），渲染显示器卡片
  - 后端实现：NSScreen.screens 获取所有屏幕信息（分辨率、是否主屏）
  - 交互逻辑：只读展示，未来可扩展拖拽排列功能

  2. 启动时自动运行（待接入）

  - 功能：macOS 开机后自动启动 PlumWallPaper
  - 当前状态：显示"待接入"标签，无实际功能
  - 需要实现：Swift 端使用 SMAppService 注册 Login Item

  3. 菜单栏快捷入口（待接入）

  - 功能：在 macOS 顶部菜单栏显示状态图标
  - 当前状态：显示"待接入"标签，无实际功能
  - 需要实现：Swift 端使用 NSStatusBar 创建 status item

  4. 显示模式（3 选 1 按钮组）

  - 功能：控制多显示器壁纸分配策略
    - 独立：每个显示器独立设置不同壁纸
    - 镜像：所有显示器显示相同壁纸
    - 全景：多个显示器拼接成一张超宽壁纸
  - 前端交互：
  onClick={() => updateSetting('displayTopology', 'independent')}
  - 后端持久化：
  // Settings.swift
  var displayTopology: DisplayTopology // enum: .independent / .mirror / .panorama
  - 数据流：
    a. 用户点击按钮 → updateSetting('displayTopology', value)
    b. 前端调用 bridge.call('updateSettings', { settings: { displayTopology: value } })
    c. Swift WebBridge 接收 → applySettingsUpdate 更新 Settings 模型
    d. SwiftData 自动持久化到本地数据库

  5. 色彩空间（3 选 1 按钮组）

  - 功能：选择壁纸渲染使用的色域
    - Display P3：Apple 广色域标准（默认）
    - sRGB：标准 RGB 色域
    - Adobe RGB：Adobe 专业色域
  - 前端交互：同上，updateSetting('colorSpace', 'p3')
  - 后端持久化：
  var colorSpace: ColorSpace // enum: .p3 / .srgb / .adobeRGB

  6. 垂直同步（Switch 开关）

  - 功能：启用 VSync 减少画面撕裂
  - 前端交互：
  <Switch
    active={s.vSyncEnabled !== false}
    onToggle={() => updateSetting('vSyncEnabled', !s.vSyncEnabled)}
  />
  - 后端持久化：
  var vSyncEnabled: Bool // 默认 true
  - 逻辑说明：!== false 表示默认开启（undefined 或 true 都视为开启）

  ---
  🔊 音频 Tab

  7. 全局壁纸音量（滑块 0-100）

  - 功能：控制所有有声动态壁纸的默认音量
  - 前端交互：
  <input
    type="range"
    min={0}
    max={100}
    value={s.globalVolume != null ? s.globalVolume : 50}
    onChange={e => updateSetting('globalVolume', Number(e.target.value))}
  />
  - 后端持久化：
  var globalVolume: Int? // 可选类型，默认 50
  - 实时显示：右上角大数字实时显示当前百分比

  8. 默认静音启动（Switch）

  - 功能：首次应用有声壁纸时默认不发声
  - 前端交互：updateSetting('defaultMuted', !s.defaultMuted)
  - 后端持久化：
  var defaultMuted: Bool? // 可选类型，默认 false
  - 逻辑说明：!!s.defaultMuted 将 undefined/null 转为 false

  9. 音频闪避 (Audio Ducking)（Switch）

  - 功能：当 Music/Spotify/浏览器播放音频时自动降低壁纸音量
  - 前端交互：updateSetting('audioDuckingEnabled', !s.audioDuckingEnabled)
  - 后端持久化：
  var audioDuckingEnabled: Bool // 默认 true
  - 需要实现：Swift 端监听系统音频会话变化（AVAudioSession）

  10. 仅预览时允许声音（Switch）

  - 功能：桌面常驻时静音，仅在预览和调色页允许试听
  - 前端交互：updateSetting('previewOnlyAudio', !s.previewOnlyAudio)
  - 后端持久化：
  var previewOnlyAudio: Bool? // 可选类型，默认 false

  ---
  ⚡ 性能 Tab

  11. 实时性能仪表盘（纯展示，模拟数据）

  - 功能：显示 GPU 渲染压力、动态帧率、系统内存占用
  - 当前实现：
  { label: 'GPU 渲染压力', value: (performanceData[23] / 5).toFixed(1) + '%' }
  { label: '动态帧率', value: (115 + Math.random() * 10).toFixed(0) }
  { label: '系统内存占用', value: (410 + Math.random() * 20).toFixed(0) }
  - 数据来源：performanceData 是前端模拟的 24 个随机数组
  - 需要实现：Swift 端使用 Metal API 获取真实 GPU 统计 + ProcessInfo 获取内存

  12-20. 智能暂停策略（9 个 Switch）

  所有开关都遵循相同的交互模式：

  前端交互：
  <Switch
    active={s.pauseOnBattery !== false}
    onToggle={() => updateSetting('pauseOnBattery', !s.pauseOnBattery)}
  />

  后端持久化（Settings.swift）：
  var pauseOnBattery: Bool          // 电池供电时暂停（默认 true）
  var pauseOnFullscreen: Bool       // 全屏应用时暂停（默认 true）
  var pauseOnOcclusion: Bool        // 壁纸被遮挡时休眠（默认 false）
  var pauseOnLowBattery: Bool       // 低电量模式时暂停（默认 true）
  var pauseOnScreenSharing: Bool    // 屏幕共享/录制时暂停（默认 false）
  var pauseOnLidClosed: Bool        // 笔记本盖子关闭时暂停（默认 true）
  var pauseOnHighLoad: Bool         // 高负载应用时暂停（默认 true）
  var pauseOnLostFocus: Bool        // 失去焦点时暂停（默认 false）
  var pauseBeforeSleep: Bool        // 睡眠前暂停（默认 true）

  需要实现的系统监听：
  - 电池状态：IOPSCopyPowerSourcesInfo
  - 全屏检测：NSApplication.shared.windows 检查 fullscreen
  - 遮挡检测：NSWindow.occlusionState
  - 低电量：ProcessInfo.processInfo.isLowPowerModeEnabled
  - 屏幕共享：CGDisplayStreamCreate 检测录制
  - 盖子状态：IOKit 监听 lid close 事件
  - CPU 负载：host_processor_info 获取 CPU 使用率
  - 焦点：NSApplication.didBecomeActiveNotification
  - 睡眠：NSWorkspace.willSleepNotification

  ---
  📦 库管理 Tab

  21. 资源库存储占用（纯展示，真实数据）

  - 功能：显示总占用空间、视频/静态壁纸分类统计
  - 数据来源：
  const storageStats = useMemo(() => {
    let video = 0, heic = 0;
    wallpapers.forEach(w => {
      if (w.type === 'video') video += w.fileSize;
      else heic += w.fileSize;
    });
    return { total: video + heic, video, heic };
  }, [wallpapers]);
  - 实现：前端从 wallpapers 数组计算，fileSize 来自后端 Wallpaper 模型

  22. 全局标签管理（CRUD 操作）

  创建标签：
  // 前端
  bridge.call('createTag', { name: '自然风光' })
    .then(() => bridge.call('getTags').then(tags => setAllTags(tags)))

  // 后端 WebBridge.swift
  case "createTag":
      let name = params["name"] as? String
      let tag = Tag(name: name)
      modelContext.insert(tag)
      try modelContext.save()

  删除标签：
  // 前端
  bridge.call('deleteTag', { tagId: t.id })
    .then(() => {
      bridge.call('getTags').then(tags => setAllTags(tags));
      // 同步清理 localStorage
      const stored = JSON.parse(localStorage.getItem('plum_custom_tags') || '[]');
      localStorage.setItem('plum_custom_tags', JSON.stringify(stored.filter(n => n !==
  t.name)));
    })

  // 后端 WebBridge.swift
  case "deleteTag":
      let tagId = params["tagId"] as? String
      let tag = try tagStore.findTag(by: tagId)
      modelContext.delete(tag)
      try modelContext.save()

  获取所有标签：
  // 前端
  bridge.call('getTags').then(tags => setAllTags(tags))

  // 后端返回格式
  [
    { id: "uuid-1", name: "自然风光" },
    { id: "uuid-2", name: "城市夜景" }
  ]

  23. 自动清理缓存（Switch）

  - 功能：当缓存超过阈值时自动清理旧缩略图
  - 前端交互：updateSetting('autoCleanEnabled', !s.autoCleanEnabled)
  - 后端持久化：
  var autoCleanEnabled: Bool // 默认 true
  var cacheThreshold: Int64  // 默认 2GB

  24. 资源库路径（按钮 + 文件选择器）

  - 功能：更改壁纸资源库存储位置
  - 前端交互：
  onClick={() =>
    bridge.call('selectLibraryPath')
      .then(result => {
        if (result && result.path)
          updateSetting('libraryPath', result.path);
      })
  }
  - 后端实现（WebBridge.swift）：
  case "selectLibraryPath":
      let panel = NSOpenPanel()
      panel.canChooseFiles = false
      panel.canChooseDirectories = true
      panel.message = "选择壁纸资源库存储位置"

      let response = await panel.beginSheetModal(for: NSApp.keyWindow!)
      if response == .OK, let url = panel.url {
          return success(["path": url.path])
      }
  - 数据流：
    a. 用户点击"更改" → 弹出 macOS 原生文件夹选择器
    b. 用户选择文件夹 → 返回路径字符串
    c. 前端调用 updateSetting('libraryPath', path) 持久化

  ---
  🎨 外观 Tab

  25. 配色主题（3 选 1 按钮组）

  - 功能：控制界面主题模式
    - 自动：跟随 macOS 系统外观
    - 浅色：强制浅色模式
    - 深色：强制深色模式
  - 前端交互：updateSetting('themeMode', 'auto')
  - 后端持久化：
  var themeMode: ThemeMode // enum: .auto / .light / .dark

  26. 强调色 (Accent)（5 个色块选择器）

  - 功能：控制界面全局交互高亮色
  - 可选颜色：
    - #E03E3E 红色（默认）
    - #2ECC71 绿色
    - #3498DB 蓝色
    - #F1C40F 黄色
    - #9B59B6 紫色
  - 前端交互：
  onClick={() => updateSetting('accentColor', '#2ECC71')}
  - 实时生效：
  useEffect(() => {
    if (settings.accentColor) {
      document.documentElement.style.setProperty('--accent', settings.accentColor);
    }
  }, [settings.accentColor]);
  - 后端持久化：
  var accentColor: String // 默认 "#E03E3E"

  27. 库缩略图尺寸（3 选 1 按钮组）

  - 功能：控制壁纸库网格缩略图大小
    - 小：更多列，信息密度高
    - 中：默认平衡
    - 大：更大预览，信息密度低
  - 前端交互：updateSetting('thumbnailSize', 'large')
  - 后端持久化：
  var thumbnailSize: ThumbnailSize // enum: .small / .medium / .large

  28. 平滑动效（Switch）

  - 功能：启用界面过渡与悬浮反馈动画
  - 前端交互：updateSetting('animationsEnabled', !s.animationsEnabled)
  - 后端持久化：
  var animationsEnabled: Bool // 默认 true

  ---
  ⌨️ 快捷键 Tab（纯展示）

  展示所有全局快捷键，当前无绑定逻辑：

  播放控制：
  - ⌥ + →：切换至下一张壁纸
  - ⌥ + ←：切换至上一张壁纸
  - Space：暂停/恢复播放
  - ⌥ + M：静音背景音

  系统与全局：
  - ⌥ + P：呼出主程序窗口
  - ⌘ + Enter：进入沉浸式预览
  - ⌘ + F：收藏当前壁纸
  - ⌘ + ,：打开偏好设置

  需要实现：Swift 端使用 NSEvent.addGlobalMonitorForEvents 监听全局快捷键

  ---
  ℹ️ 关于 Tab

  29. 检查更新（按钮）

  - 功能：打开 GitHub Releases 页面
  - 前端交互：
  onClick={() => bridge.call('openURL', {
    url: 'https://github.com/AlexPlum405/PlumWallPaper/releases'
  })}
  - 后端实现（WebBridge.swift）：
  case "openURL":
      let url = URL(string: params["url"])
      NSWorkspace.shared.open(url)

  30. 许可协议（按钮）

  - 功能：打开 GitHub LICENSE 页面
  - 前端交互：同上，URL 为 https://github.com/AlexPlum405/PlumWallPaper/blob/main/LICENSE

  ---
  核心交互逻辑总结

  前端 → 后端数据流

  用户操作（点击/滑动）
    ↓
  updateSetting(key, value)  // 前端统一入口
    ↓
  setSettings(prev => ({ ...prev, [key]: value }))  // 更新本地 state
    ↓
  bridge.call('updateSettings', { settings: { [key]: value } })  // 调用 bridge
    ↓
  WebBridge.swift 接收消息
    ↓
  applySettingsUpdate(settings, data)  // 解析并应用
    ↓
  Settings 模型字段更新
    ↓
  SwiftData 自动持久化到本地数据库

  后端 → 前端数据流

  App 启动
    ↓
  useEffect(() => {
    bridge.call('getSettings').then(data => setSettings(data))
  }, [])
    ↓
  WebBridge.swift 处理 'getSettings'
    ↓
  serializeSettings(settings)  // 序列化为 JSON
    ↓
  返回前端
    ↓
  前端 setSettings(data) 更新 UI

  关键代码位置

  前端：
  - 设置页组件：plumwallpaper.html 行 1405-1814
  - updateSetting 函数：行 1896-1899
  - 初始化加载：行 1869-1879

  后端：
  - Settings 模型：Sources/Storage/Models/Settings.swift
  - WebBridge 处理：Sources/Bridge/WebBridge.swift
    - getSettings：行 218-222
    - updateSettings：行 223-231
    - serializeSettings：行 404-434
    - applySettingsUpdate：行 453-482

  所有设置都通过这套统一的数据流实现前后端同步和持久化。

1. 补全显示模式
  - 独立：弹显示器选择器
  - 镜像：直接应用到全部，不弹选择器
  - 全景：弹一个“全景预览/拓扑确认”面板，但不是让用户点选单屏
  现在设置页里 displayTopology 只是保存设置值，见
  PlumWallPaper/Sources/Resources/Web/plumwallpaper.html:1600，后端也只是持久化，见
  PlumWallPaper/Sources/Bridge/WebBridge.swift:475 和 PlumWallPaper/Sources/Bridge/WebBridge
  .swift:525。当前项目里它还没真正反向影响“设为壁纸”的流程。进行补完。
  2. 色彩空间，目前基本没有实际效果。因为现在它只是设置值和 UI 按钮，前后端已打通，但还没真正驱动 WallpaperEngine渲染层。前端按钮在PlumWallPaper/Sources/Resources/Web/plumwallpaper.html:1603，后端只是存储在 PlumWallPaper/Sources/Bridge/WebBridge.swift:475、PlumWallPaper/Sources/Bridge/WebBridge.swift:526。
实现它：
  - 默认：自动 / Display P3
  - 进阶选项：sRGB
  - Adobe RGB 高级功能，普通用户不常使用，但是能提升软件调性
3. 垂直同步
改名 + 改语义
  - 把"垂直同步"改成"高性能模式 / 省电模式"
  - 开启时：60fps 全质量播放
  - 关闭时：30fps 或允许掉帧

4.制定后续高级功能实现方案，保存到本地。等我完成第一个稳定版本后，根据方案实施。
    - 实时生成内容（粒子系统、程序化动画、shader art）
    - 极致自定义滤镜（AVFoundation 的 Core Image 滤镜不够用）
    - 交互式壁纸（鼠标跟随、音频可视化）
