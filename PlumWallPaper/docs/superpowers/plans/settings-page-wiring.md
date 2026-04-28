# 设置页面 6 个菜单接入后端实现计划

> 当前状态：6 个菜单全部仅 UI 展示，后端 `getSettings` / `updateSettings` 已实现但前端未调用。

---

### 1. 通用

- [ ] "启动时自动运行" 开关接入 `updateSettings({ launchAtLogin: bool })`，并调用 `SMAppService` 注册登录项
- [ ] "菜单栏快捷入口" 开关接入设置持久化
- [ ] 显示器拓扑图：拖拽排列功能（低优先级，可后续迭代）

### 2. 外观

- [ ] 配色主题按钮组接入 `updateSettings({ themeMode })` 并切换 CSS 变量
- [ ] 强调色圆点接入 `updateSettings({ accentColor })` 并实时更新 `--accent`
- [ ] 缩略图尺寸按钮组接入 `updateSettings({ thumbnailSize })`
- [ ] 平滑动效开关接入 `updateSettings({ animationsEnabled })`

### 3. 性能

- [ ] GPU/FPS/内存仪表盘替换为真实数据（需新增 bridge action `getPerformanceStats`，或标记为模拟数据）
- [ ] 9 个智能暂停开关逐一接入对应 settings 字段：
  - `pauseOnBattery`、`pauseOnFullscreen`、`pauseOnOcclusion`、`pauseOnLowBattery`
  - `pauseOnScreenSharing`、`pauseOnLidClosed`、`pauseOnHighLoad`、`pauseOnLostFocus`、`pauseBeforeSleep`

### 4. 库管理

- [ ] 存储占用改为真实计算（遍历 libraryPath 统计视频/图片/缩略图大小）
- [ ] 标签列表从 `getTags` 动态拉取
- [ ] 标签删除（× 按钮）接入 `deleteTag`
- [ ] "+ 新增分类" 接入 `createTag`

### 5. 快捷键

- [ ] 当前为纯展示，后续可支持自定义绑定（低优先级）

### 6. 关于

- [ ] "检查更新" 按钮接入版本检查逻辑（或弹 toast 提示"已是最新版本"）
- [ ] "许可协议" 按钮打开本地或远程许可文档

---

*创建时间: 2026-04-28*
