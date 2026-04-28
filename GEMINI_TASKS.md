# PlumWallPaper 100% 视觉对齐审计与还原手册 (Fidelity Audit)

**目标**：确保 SwiftUI 实现与 `ui-prototype/plumwallpaper-v5.html` 在像素、颜色、动效上完全一致。

> **核心准则**：
> 1. **严禁擅改**：未经用户指令，严禁修改任何代码。
> 2. **1:1 验收**：每项任务完成后，必须将产物截图/运行效果与原型进行 1:1 叠加对比，确认还原度达到 100% 后，方可在本项目中标记为 [x]。
> 3. **数值优先**：所有 UI 参数必须优先参考原型 CSS 代码中的数值（如 `blur`, `opacity`, `tracking`）。

---

## 🎨 0. 全局设计规范 (Design Tokens)
- [x] **背景色校对**: 已确认 `Theme.bg` 为 `#0D0E12`。
- [x] **强调色校对**: 已确认 `Theme.accent` 为 `#E03E3E`。
- [ ] **字体规范**:
    - [x] Display: `Cormorant Garamond` (Italic)。
    - [ ] UI: `Inter` 校对（目前部分使用系统 Rounded 字体，需确认是否替换为 Inter）。
- [ ] **全局阴影 (Shadows)**: 需在 `Theme` 中统一定义三层叠加投影。

---

## 🟡 1. Header & Navigation (顶部导航栏) - [已完成 1:1 校对]
- [x] **Logo 玻璃核心**:
    - [x] 外圆/方: 44x44, `border: 0.5px`, 背景 `White(0.05)`。
    - [x] 核心: 实现双层发光 `shadow` (半径 8 + 半径 10)，模拟灯管效果。
- [x] **品牌文字**:
    - [x] "Plum": 28px, 斜体, `tracking(-0.5)`。
    - [x] "WALLPAPER": 9px, `font-weight: 300`, `tracking(4)`。
- [x] **Pill Tab (首页/壁纸库切换)**:
    - [x] 背景: 选中态 `rgba(255,255,255,0.08)`, `blur(20px)`。
    - [x] 动效: `interactiveSpring` 弹性切换。

---

## 🟠 2. HomeView (首页 Hero 区域) - [已完成 1:1 校对]
- [x] **Hero 渐变蒙版**: 已对齐 `linear-gradient(to top, #0D0E12 0%, transparent 80%)`，高度 400px。
- [x] **Jewel 标签**: 
    - [x] 颜色: `#E03E3E`。
    - [x] 动效: 实现 `hueRotation` 360度 4s 循环流光。
- [x] **视觉质感**: 增加 0.03 不透明度底噪图层。
- [ ] **网格卡片 (Grid Card)**:
    - [x] **Aura Glow**: 实现 `onContinuousHover` 鼠标跟随。
    - [ ] **自定义右键菜单 (重难点)**: 尚未实现 Overlay 菜单，目前仍为系统样式。

---

## 🔴 3. ColorAdjustView (色彩调节沉浸页) - [已完成 1:1 校对]
- [x] **75:25 黄金布局**: 实现 `GeometryReader` 比例切割，左侧预览，右侧面板。
- [x] **控制面板 (Right Panel)**:
    - [x] 背景: `blur(40px)` + `opacity(0.4)` 叠加。
    - [x] 边框: 实现左侧 `1px` 单边线对齐。
- [x] **返回按钮重做**: 48x48 圆形悬浮毛玻璃按钮，左上角固定。
- [x] **Apply 按钮动效**: 实现红色微光呼吸 shadow 动画。

---

## 🟣 4. SettingsView & Performance (设置中心) - [进行中]
- [ ] **性能图表 (Performance Metrics)**: 尚未开始。
- [ ] **排版基准线**: 140px 垂直基准线对齐尚未开始。

---

## ⚪ 5. 交互与动效细节
- [ ] **自定义 Context Menu (右键菜单)**: 计划作为 Phase 3 的核心。
- [ ] **全屏转场**: `Home -> ColorAdjust` 的缩放式转场需替换当前的 `.sheet`。
