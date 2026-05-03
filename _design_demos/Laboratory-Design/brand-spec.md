# Laboratory HUD · Design Spec
> 采集日期：2026-05-03
> 任务：重构壁纸 App 实验室交互，提供 3 种视觉变体。

## 🎯 核心资产（一等公民）

### Logo
- Placeholder: `assets/logo.svg` (PlumWallPaper Icon)

### UI 背景
- 模拟壁纸：使用一张高保真 RWB Porsche 911 赛道图。

## 🎨 辅助资产

### 1. Artisan Frost (匠人冰态)
- **色板**: Primary: #FF7EB9 (Plum Pink), Glass: rgba(255,255,255,0.1), Border: rgba(255,255,255,0.2)
- **气质**: 原生、极简、高端。
- **细节**: 超大模糊半径 (40px)，极细 0.5px 描边。

### 2. Studio Pro (专业工作室)
- **色板**: Primary: #4CAF50 (Pro Green), background: #121212, Border: #333333
- **气质**: 精确、工业、参数化。
- **细节**: 像素级网格刻度，单色系。

### 3. Liquid Horizon (流体地平线)
- **色板**: Primary: #7C4DFF (Vibrant Violet), Surface: rgba(20,20,30,0.8)
- **气质**: 灵动、有机、游戏感。
- **细节**: 流体圆角 (32px+), 强烈的光晕效果。

### 字型
- Display: Georgia (Artisan Style)
- Body: -apple-system (macOS native)
- Mono: SF Mono / Menlo (Data HUD)

## 🏗️ 交互系统
- **架构**: 抽屉式扩展 (Popup Inspector)。
- **布局**: 3x2 静态网格，彻底消除横向滚动。
- **响应**: 鼠标点击滑块即时反馈，画面滤镜同步变化。
