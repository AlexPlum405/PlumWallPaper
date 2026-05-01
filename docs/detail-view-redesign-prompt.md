# Gemini 任务：WallpaperDetailView 重构为 Artisan Horizon HUD

## ⛔ 铁律约束（违反任何一条立即停止）

1. **只改这两个文件**：`Sources/Views/Detail/WallpaperDetailView.swift` 和 `Sources/Views/Detail/WallpaperDetailView+Logic.swift`
2. **禁止触碰任何其他文件**——不改 HomeView、ContentView、ShaderEditorView、pbxproj、任何 Settings 文件、任何 Components 文件
3. **禁止删除现有代码后全量重写**——在现有文件基础上改造
4. **禁止引入新依赖、新文件、新组件**
5. **所有 UI 文案必须使用中文**
6. **改完后必须执行 `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build` 确认编译通过**
7. **保留现有的 BuiltInPreset enum 和所有滤镜 State 变量，不要删除或重命名**

---

## 🎯 设计理念

全屏沉浸式壁纸鉴赏厅。100% 视野，底部 Dock 交互，极致沉浸。

**核心原则：没有右侧边栏。** 调色器/特效配置通过底部 Dock 上的"实验室"按钮触发，面板从 Dock 上方升起，横向排列，不遮挡壁纸主体。

---

## 📐 ZStack 层级架构

```
ZStack {
    // 1. 底层：纯净画布（100% 视野）
    fullscreenCanvas

    // 2. 交互辅助层：透明拖拽与背景点击
    Color.clear.contentShape(Rectangle()).windowDragGesture()

    // 3. 侧翼导航（左右两侧边缘感应）
    sideNavigationArrows

    // 4. 标题 HUD（左上角，极简感应）
    artisanTitleHUD
        .padding(.leading, 80).padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

    // 5. 核心地平线 HUD（Dock + Studio，底部居中）
    VStack(spacing: 24) {
        Spacer()

        // 次地平线：调节工作室（点击"实验室"按钮后升起）
        if isStudioActive {
            artisanStudioHUD
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
        }

        // 地平线底座：主控 Dock
        artisanMainDock
    }
    .padding(.bottom, 40)

    // 6. 关闭按钮（右上角）
    closeButtonHUD
}
.frame(minWidth: 1200, minHeight: 800)
.preferredColorScheme(.dark)
```

---

## 📦 State 变量清单

```swift
@Environment(\.dismiss) private var dismiss
let wallpaper: Wallpaper
var onPrevious: (() -> Void)?
var onNext: (() -> Void)?

// 状态驱动
@State internal var isStudioActive = false      // 实验室面板是否展开
@State internal var studioTab = 0               // 0: 预设, 1: 光学, 2: 风格, 3: 粒子
@State internal var isApplying = false           // 应用壁纸中

// 侧翼导航悬停
@State internal var isLeftEdgeHovered = false
@State internal var isRightEdgeHovered = false

// 滤镜参数（9 个，保留现有变量名）
@State internal var exposure: Double = 100
@State internal var contrast: Double = 100
@State internal var saturation: Double = 100
@State internal var hue: Double = 0
@State internal var blur: Double = 0
@State internal var grain: Double = 0
@State internal var vignette: Double = 0
@State internal var grayscale: Double = 0
@State internal var invert: Double = 0
@State internal var currentPresetName: String = "原图"
```

---

## 📦 各组件详细规格

### 1. 全屏画布 (fullscreenCanvas)

```swift
private var fullscreenCanvas: some View {
    ZStack {
        if let url = URL(string: wallpaper.filePath) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fit) // .fit 确保不裁切
                } else { Color.black }
            }
        } else { Color.black }
        // 径向暗角
        RadialGradient(colors: [.clear, .black.opacity(0.3)], center: .center, startRadius: 300, endRadius: 1000)
    }
    .background(Color.black)
    .ignoresSafeArea()
}
```

### 2. 侧翼导航 (sideNavigationArrows)

左右两侧边缘感应区，鼠标靠近边缘时箭头浮现。不是上下箭头，是左右侧翼。

**左侧翼：**
```swift
ZStack(alignment: .leading) {
    // 透明感应区（100pt 宽）
    Rectangle().fill(Color.white.opacity(0.001)).frame(width: 100)

    HStack(spacing: 0) {
        // 装饰性竖线指示器
        ZStack {
            RoundedRectangle(cornerRadius: 2).fill(.ultraThinMaterial)
                .frame(width: 4, height: 160)
                .overlay(RoundedRectangle(cornerRadius: 2)
                    .stroke(LiquidGlassColors.primaryPink.opacity(isLeftEdgeHovered ? 0.6 : 0.2), lineWidth: 0.5))

            // 刻度线装饰
            VStack(spacing: 4) {
                ForEach(0..<6) { i in
                    Rectangle().fill(.white.opacity(isLeftEdgeHovered ? 0.4 : 0.2))
                        .frame(width: i == 3 ? 10 : 6, height: 1)
                }
            }.offset(x: 10)
        }
        .offset(x: isLeftEdgeHovered ? 20 : 0)

        // 箭头 + 文字
        VStack(spacing: 12) {
            Image(systemName: "chevron.left.circle.fill")
                .font(.system(size: 24, weight: .thin))
            Text("上一张").font(.system(size: 9, weight: .bold))
                .opacity(isLeftEdgeHovered ? 0.8 : 0)
        }
        .foregroundStyle(isLeftEdgeHovered ? LiquidGlassColors.primaryPink : .white.opacity(0.4))
        .offset(x: isLeftEdgeHovered ? 30 : 10)
    }
}
.contentShape(Rectangle())
.onHover { hovering in withAnimation(.gallerySpring) { isLeftEdgeHovered = hovering } }
.onTapGesture { onPrevious?() }
.zIndex(100)
```

右侧翼镜像对称，使用 `chevron.right.circle.fill` 和 "下一张"。

### 3. 标题 HUD (artisanTitleHUD)

左上角，显示壁纸信息。始终可见（不需要悬停触发）。

```swift
private var artisanTitleHUD: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("精选画廊")
            .font(.system(size: 12, weight: .black)).kerning(5)
            .foregroundStyle(LiquidGlassColors.primaryPink)

        Text(wallpaper.name)
            .artisanTitleStyle(size: 48, kerning: 1)
            .shadow(color: .black.opacity(0.5), radius: 20)

        HStack(spacing: 20) {
            metadataTag(icon: "ruler", text: wallpaper.resolution ?? "8K 超清")
            metadataTag(icon: "cpu", text: "全动态渲染")
        }
    }
}

private func metadataTag(icon: String, text: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon).font(.system(size: 10))
        Text(text).font(.system(size: 10, weight: .bold))
    }
    .foregroundStyle(.white.opacity(0.6))
    .padding(.horizontal, 12).padding(.vertical, 6)
    .background(Capsule().fill(Color.white.opacity(0.05)))
}
```

### 4. 主控 Dock (artisanMainDock) ⭐ 核心组件

底部居中的胶囊形操作栏。包含 4 个按钮，外层毛玻璃胶囊。

```swift
private var artisanMainDock: some View {
    HStack(spacing: 24) {
        // 1. 收藏按钮（圆形）
        actionCircleButton(
            icon: wallpaper.isFavorite ? "heart.fill" : "heart",
            color: wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white.opacity(0.6)
        ) { /* 收藏逻辑 */ }

        // 2. 应用壁纸（主按钮，粉色胶囊）
        Button(action: {
            isApplying = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isApplying = false }
        }) {
            HStack(spacing: 16) {
                if isApplying { CustomProgressView(tint: .white, scale: 0.8) }
                else { Text("设为壁纸").font(.system(size: 14, weight: .bold)).kerning(2) }
            }
            .padding(.horizontal, 60).frame(height: 52)
            .background(LiquidGlassColors.primaryPink)
            .clipShape(Capsule())
            .foregroundStyle(.black)
            .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 20)
        }.buttonStyle(.plain)

        // 3. 实验室按钮（圆形，toggle 控制 isStudioActive）⭐
        Button(action: { withAnimation(.gallerySpring) { isStudioActive.toggle() } }) {
            VStack(spacing: 4) {
                Image(systemName: "camera.aperture").font(.system(size: 18))
                Text("实验室").font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(isStudioActive ? LiquidGlassColors.primaryPink : .white.opacity(0.6))
            .frame(width: 52, height: 52)
            .background(Circle().fill(Color.white.opacity(0.05)))
            .overlay(Circle().stroke(
                isStudioActive ? LiquidGlassColors.primaryPink.opacity(0.5) : Color.white.opacity(0.1),
                lineWidth: 1
            ))
        }.buttonStyle(.plain)

        // 4. 下载按钮（圆形）
        actionCircleButton(icon: "arrow.down.to.line.compact", color: .white.opacity(0.6)) { }
    }
    .padding(12)
    .background(.ultraThinMaterial, in: Capsule())
    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    .artisanShadow(color: .black.opacity(0.2), radius: 30)
}

// 圆形按钮通用样式
private func actionCircleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            .frame(width: 52, height: 52)
            .background(Circle().fill(Color.white.opacity(0.05)))
            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }.buttonStyle(.plain)
}
```

### 5. 实验室面板 (artisanStudioHUD) ⭐ 核心组件

点击 Dock 上的"实验室"按钮后，从 Dock 上方升起的横向面板。**不是侧边栏，是底部横向面板。**

**关键设计决策：** 面板在底部横向展开，壁纸上方大部分区域仍然可见，用户可以实时看到滤镜/粒子效果。

```swift
private var artisanStudioHUD: some View {
    HStack(spacing: 40) {
        // === 左侧：Tab 切换按钮（竖排） ===
        VStack(spacing: 12) {
            ArtisanHorizonTab(icon: "grid", label: "预设", isSelected: studioTab == 0) { studioTab = 0 }
            ArtisanHorizonTab(icon: "camera.filters", label: "光学", isSelected: studioTab == 1) { studioTab = 1 }
            ArtisanHorizonTab(icon: "crop", label: "风格", isSelected: studioTab == 2) { studioTab = 2 }
            ArtisanHorizonTab(icon: "sparkles", label: "粒子", isSelected: studioTab == 3) { studioTab = 3 }
        }

        Divider().frame(height: 140).opacity(0.1)

        // === 中间：对应 Tab 的内容区（横向滚动） ===
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 32) {
                if studioTab == 0 {
                    // 预设 Tab：快速滤镜网格
                    presetTabContent
                } else if studioTab == 1 {
                    // 光学 Tab：曝光/对比度/饱和度/色相
                    ArtisanRulerDial(label: "曝光", value: $exposure, range: 0...200, unit: "ev")
                    ArtisanRulerDial(label: "对比度", value: $contrast, range: 50...150, unit: "%")
                    ArtisanRulerDial(label: "饱和度", value: $saturation, range: 0...200, unit: "%")
                    ArtisanRulerDial(label: "色相", value: $hue, range: -180...180, unit: "°")
                } else if studioTab == 2 {
                    // 风格 Tab：模糊/噪点/暗角/黑白/反相
                    ArtisanRulerDial(label: "模糊", value: $blur, range: 0...40, unit: "px")
                    ArtisanRulerDial(label: "噪点", value: $grain, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "暗角", value: $vignette, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "黑白", value: $grayscale, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "反相", value: $invert, range: 0...100, unit: "%")
                } else if studioTab == 3 {
                    // 粒子 Tab：发射源/粒子样式/色彩演化/速率/寿命/尺寸/重力/扰动
                    particleTabContent
                }
            }
            .padding(.vertical, 10)
        }
        .frame(maxWidth: 750)

        Divider().frame(height: 140).opacity(0.1)

        // === 右侧：重置/应用按钮 ===
        VStack(spacing: 16) {
            Button(action: { resetFilters() }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise.circle.fill").font(.system(size: 20))
                    Text("重置").font(.system(size: 8, weight: .bold))
                }.foregroundStyle(.white.opacity(0.4))
            }.buttonStyle(.plain)

            Button(action: { /* 应用 */ }) {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                    Text("应用").font(.system(size: 8, weight: .bold))
                }.foregroundStyle(LiquidGlassColors.primaryPink)
            }.buttonStyle(.plain)
        }
    }
    .padding(.horizontal, 32).padding(.vertical, 24)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    .artisanShadow(color: .black.opacity(0.4), radius: 50)
}
```

#### 预设 Tab 内容

```swift
private var presetTabContent: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("快速滤镜").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3))
        LazyHGrid(rows: [GridItem(.fixed(32)), GridItem(.fixed(32))], spacing: 10) {
            ForEach(BuiltInPreset.allCases) { preset in
                Button(action: { applyPreset(preset) }) {
                    Text(preset.name).font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 16).frame(height: 32)
                        .background(currentPresetName == preset.name
                            ? LiquidGlassColors.primaryPink
                            : Color.white.opacity(0.08))
                        .foregroundStyle(currentPresetName == preset.name ? Color.black : .white)
                        .clipShape(Capsule())
                }.buttonStyle(.plain)
            }
        }
    }
}
```

#### 粒子 Tab 内容

```swift
private var particleTabContent: some View {
    HStack(spacing: 40) {
        // 发射源
        VStack(spacing: 8) {
            Text("发射源").font(.system(size: 8, weight: .bold)).opacity(0.3)
            Button(action: {}) {
                Circle().fill(LiquidGlassColors.primaryPink).frame(width: 36, height: 36)
                    .overlay(Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundStyle(.black))
            }.buttonStyle(.plain)
        }

        Divider().frame(height: 60).opacity(0.1)

        // 粒子样式选择
        VStack(alignment: .leading, spacing: 12) {
            Text("粒子样式").font(.system(size: 8, weight: .bold)).opacity(0.3)
            HStack(spacing: 12) {
                ForEach(["circle.fill", "star.fill", "sparkles", "leaf.fill", "drop.fill"], id: \.self) { icon in
                    Image(systemName: icon).font(.system(size: 14))
                        .foregroundStyle(icon == "circle.fill" ? LiquidGlassColors.primaryPink : .white.opacity(0.4))
                        .frame(width: 32, height: 32)
                        .background(icon == "circle.fill" ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Circle())
                }
            }
        }

        Divider().frame(height: 60).opacity(0.1)

        // 色彩演化
        VStack(alignment: .leading, spacing: 12) {
            Text("色彩演化").font(.system(size: 8, weight: .bold)).opacity(0.3)
            HStack(spacing: 12) {
                ColorPicker("", selection: .constant(Color.white)).labelsHidden()
                Image(systemName: "arrow.right").font(.system(size: 8)).opacity(0.2)
                ColorPicker("", selection: .constant(LiquidGlassColors.primaryPink)).labelsHidden()
            }
        }

        Divider().frame(height: 60).opacity(0.1)

        // 粒子参数旋钮
        ArtisanRulerDial(label: "速率", value: .constant(60), range: 1...300, unit: "p/s")
        ArtisanRulerDial(label: "寿命", value: .constant(3), range: 0.1...10, unit: "s")
        ArtisanRulerDial(label: "尺寸", value: .constant(4), range: 1...40, unit: "px")
        ArtisanRulerDial(label: "重力", value: .constant(9.8), range: -20...20, unit: "m/s²")
        ArtisanRulerDial(label: "扰动", value: .constant(2), range: 0...20, unit: "px")
    }
}
```

### 6. 关闭按钮 (closeButtonHUD)

右上角，始终可见或联动显示。

```swift
private var closeButtonHUD: some View {
    VStack {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.4)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
            .buttonStyle(.plain).padding(40)
        }
        Spacer()
    }.zIndex(110)
}
```

---

## 🎨 设计系统引用

必须使用项目已有的 Artisan Gallery 设计语言，这些已经在项目中定义好了：

- **颜色**：`LiquidGlassColors.primaryPink`、`.textPrimary`、`.textSecondary`、`.textQuaternary`、`.tertiaryBlue`、`.glassBorder`
- **动画**：`.gallerySpring`、`.galleryEase`
- **阴影**：`.artisanShadow(color:radius:)`
- **标题**：`.artisanTitleStyle(size:kerning:)` — Georgia Bold
- **材质**：`.ultraThinMaterial`
- **组件**：`ArtisanHorizonTab`、`ArtisanRulerDial`、`CustomProgressView`、`FlowLayout` — 这些组件已存在于项目中，直接使用

---

## 🔑 与旧版的核心区别（不要搞混）

| 方面 | ❌ 旧版（当前代码） | ✅ 新版（目标） |
|------|-------------------|----------------|
| 调色器位置 | 右侧边栏 320pt | 底部横向面板，Dock 上方升起 |
| 触发方式 | 鼠标悬停右侧边缘 | 点击 Dock 上"实验室"按钮 toggle |
| 导航方向 | 上下箭头 | 左右侧翼（边缘感应） |
| 面板布局 | 纵向 ScrollView | 横向 Tab + 横向 ScrollView |
| 标题位置 | 左侧悬停显示 | 左上角固定显示 |
| 关闭按钮 | 左上角 | 右上角 |
| 底部操作 | 悬停显示 | 始终可见的 Dock |

---

## ✅ 验收标准

1. 全屏壁纸视野，无右侧边栏
2. 底部 Dock 包含：收藏 / 设为壁纸 / 实验室 / 下载，四个按钮
3. 点击"实验室"按钮 → 面板从 Dock 上方升起（带动画）；再点 → 收起
4. 实验室面板有 4 个 Tab：预设、光学、风格、粒子
5. 光学 Tab 有 4 个参数旋钮：曝光、对比度、饱和度、色相
6. 风格 Tab 有 5 个参数旋钮：模糊、噪点、暗角、黑白、反相
7. 预设 Tab 有滤镜快速选择网格（使用现有 BuiltInPreset）
8. 粒子 Tab 有发射源、粒子样式、色彩演化、速率/寿命/尺寸/重力/扰动
9. 左右侧翼导航：鼠标靠近左/右边缘 → 箭头浮现，点击切换壁纸
10. 左上角标题 HUD：壁纸名称 + 元数据
11. 右上角关闭按钮
12. 所有文案中文
13. 编译通过，无 warning
14. **不改动任何其他文件**
