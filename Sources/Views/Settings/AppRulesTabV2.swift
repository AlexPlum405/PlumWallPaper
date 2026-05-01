import SwiftUI
import AppKit

// MARK: - Artisan Strategy Matrix (Scheme C: Artisan Gallery)
// 这里是 Plum 的智慧中枢，每一条逻辑流都清晰如画。

struct AppRulesTabV2: View {
    var viewModel: SettingsViewModel
    @Binding var toast: ToastConfig?

    @State private var searchText = ""
    @State private var selectedCategory: String = "全部"
    
    // 推荐分类 (维持原样)
    private let categories = ["全部", "视频编辑", "3D 渲染", "开发工具", "音频制作"]

    // 推荐应用列表 (禁止修改内容)
    let recommendedApps: [(bundleId: String, name: String, action: RuleAction, category: String)] = [
        ("com.apple.FinalCut", "Final Cut Pro", .pause, "视频编辑"),
        ("com.blackmagic-design.DaVinciResolve", "DaVinci Resolve", .pause, "视频编辑"),
        ("com.adobe.PremierePro", "Premiere Pro", .pause, "视频编辑"),
        ("com.adobe.AfterEffects", "After Effects", .pause, "视频编辑"),
        ("org.blender.blender", "Blender", .limitFPS30, "3D 渲染"),
        ("com.unity3d.UnityEditor5.x", "Unity", .pause, "游戏引擎"),
        ("com.epicgames.UnrealEngine", "Unreal Engine", .pause, "游戏引擎"),
        ("com.maxon.cinema4d", "Cinema 4D", .limitFPS30, "3D 渲染"),
        ("com.apple.logic10", "Logic Pro", .mute, "音频制作"),
        ("com.ableton.live", "Ableton Live", .mute, "音频制作"),
        ("com.apple.dt.Xcode", "Xcode", .pause, "开发工具"),
        ("com.jetbrains.intellij", "IntelliJ IDEA", .pause, "开发工具")
    ]

    // 已配置的规则
    var configuredRules: [AppRule] {
        viewModel.settings?.appRules.filter { rule in
            searchText.isEmpty || rule.appName.localizedCaseInsensitiveContains(searchText)
        } ?? []
    }

    // 过滤后的推荐列表
    var filteredRecommendations: [(bundleId: String, name: String, action: RuleAction, category: String)] {
        recommendedApps.filter { app in
            let notInRules = !(viewModel.settings?.appRules.contains(where: { $0.bundleIdentifier == app.bundleId }) ?? false)
            let matchSearch = searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)
            let matchCategory = selectedCategory == "全部" || app.category == selectedCategory
            return notInRules && matchSearch && matchCategory
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 顶部 Header 与 搜索
            artisanHeaderSection
                .padding(.horizontal, 32)
                .padding(.top, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 48) {
                    
                    // ===== 新增：全局暂停策略区域 (GLOBAL PAUSE TRIGGERS) =====
                    globalPauseStrategiesSection
                        .padding(.horizontal, 32)
                    
                    // 2. 活跃逻辑单元
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .firstTextBaseline) {
                            LiquidGlassSectionHeader(title: "智慧调度策略", icon: "bolt.shield.fill", color: LiquidGlassColors.primaryPink)
                            Text("LOGIC MATRIX").font(.system(size: 10, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
                            Spacer()
                            if !configuredRules.isEmpty {
                                Button("全部停用") { toggleAllRules(enabled: false) }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(LiquidGlassColors.primaryPink)
                                    .buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 32)
                        
                        if !configuredRules.isEmpty {
                            VStack(spacing: 16) {
                                ForEach(configuredRules) { rule in
                                    ArtisanAppRuleRow(rule: rule, 
                                                    isActive: isRuleActive(rule.id),
                                                    onUpdate: { updateRuleAction(rule.id, action: $0) },
                                                    onDelete: { deleteRule(rule.id) })
                                }
                            }.padding(.horizontal, 32)
                        } else if searchText.isEmpty {
                            artisanEmptyState
                        }
                    }
                    
                    // 3. 智能发现网格
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .firstTextBaseline) {
                            LiquidGlassSectionHeader(title: "智能发现", icon: "sparkles", color: LiquidGlassColors.tertiaryBlue)
                            Text("SMART DISCOVERY").font(.system(size: 10, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
                            Spacer()
                            Button("全量导入") { addAllRecommended() }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.tertiaryBlue)
                                .buttonStyle(.plain)
                        }.padding(.horizontal, 32)
                        
                        // 分类筛选
                        FlowLayout(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                FilterChip(title: cat, isSelected: selectedCategory == cat) {
                                    withAnimation(.gallerySpring) { selectedCategory = cat }
                                }
                            }
                        }.padding(.horizontal, 32)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                            ForEach(filteredRecommendations, id: \.bundleId) { app in
                                ArtisanRecommendedTile(app: app) { addRecommendedRule(app) }
                            }
                        }.padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .background(LiquidGlassColors.deepBackground)
    }

    // MARK: - 新增：全局暂停策略 UI
    private var globalPauseStrategiesSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline) {
                LiquidGlassSectionHeader(title: "全局暂停策略", icon: "power", color: LiquidGlassColors.warningOrange)
                Text("GLOBAL PAUSE TRIGGERS").font(.system(size: 10, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                pauseStrategyCard(icon: "battery.100.bolt", title: "电池供电", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnBattery ?? true }, 
                                            set: { setPauseOnBattery($0) }))

                pauseStrategyCard(icon: "arrow.up.left.and.arrow.down.right", title: "全屏应用", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnFullscreen ?? true }, 
                                            set: { setPauseOnFullscreen($0) }))

                pauseStrategyCardWithThreshold(
                    icon: "battery.25", 
                    title: "低电量", 
                    isOn: Binding(get: { viewModel.settings?.pauseOnLowBattery ?? true }, 
                                set: { setPauseOnLowBattery($0) }),
                    threshold: Binding(get: { viewModel.settings?.lowBatteryThreshold ?? 20 }, 
                                     set: { setLowBatteryThreshold($0) })
                )

                pauseStrategyCard(icon: "rectangle.on.rectangle", title: "屏幕共享", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnScreenSharing ?? false }, 
                                            set: { setPauseOnScreenSharing($0) }))

                pauseStrategyCard(icon: "cpu", title: "高负载", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnHighLoad ?? true }, 
                                            set: { setPauseOnHighLoad($0) }))

                pauseStrategyCard(icon: "eye.slash", title: "失去焦点", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnLostFocus ?? false }, 
                                            set: { setPauseOnLostFocus($0) }))

                pauseStrategyCard(icon: "laptopcomputer", title: "合盖暂停", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnLidClosed ?? true }, 
                                            set: { setPauseOnLidClosed($0) }))

                pauseStrategyCard(icon: "moon.zzz", title: "睡眠前夕", 
                                isOn: Binding(get: { viewModel.settings?.pauseBeforeSleep ?? true }, 
                                            set: { setPauseBeforeSleep($0) }))

                pauseStrategyCard(icon: "square.stack", title: "被遮挡时", 
                                isOn: Binding(get: { viewModel.settings?.pauseOnOcclusion ?? false }, 
                                            set: { setPauseOnOcclusion($0) }))
            }
        }
    }

    private func pauseStrategyCard(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isOn.wrappedValue ? LiquidGlassColors.warningOrange : LiquidGlassColors.textQuaternary)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LiquidGlassColors.textPrimary)

            Spacer()

            artisanToggle(isOn: isOn)
        }
        .padding(20)
        .galleryCardStyle(radius: 16, padding: 0)
    }

    private func pauseStrategyCardWithThreshold(icon: String, title: String, isOn: Binding<Bool>, threshold: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isOn.wrappedValue ? LiquidGlassColors.warningOrange : LiquidGlassColors.textQuaternary)
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textPrimary)

                Spacer()

                artisanToggle(isOn: isOn)
            }

            if isOn.wrappedValue {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("触发阈值").font(.system(size: 11, weight: .medium)).foregroundStyle(LiquidGlassColors.textSecondary)
                        Spacer()
                        Text("\(threshold.wrappedValue)%").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(LiquidGlassColors.warningOrange)
                    }
                    Slider(value: Binding(get: { Double(threshold.wrappedValue) }, set: { threshold.wrappedValue = Int($0) }), in: 5...50, step: 5)
                        .tint(LiquidGlassColors.warningOrange)
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .galleryCardStyle(radius: 16, padding: 0)
    }

    private func artisanToggle(isOn: Binding<Bool>) -> some View {
        Button { withAnimation(.gallerySpring) { isOn.wrappedValue.toggle() } } label: {
            ZStack {
                Capsule().fill(isOn.wrappedValue ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1)).frame(width: 36, height: 20)
                Circle().fill(Color.white).frame(width: 16, height: 16).shadow(color: .black.opacity(0.2), radius: 2).offset(x: isOn.wrappedValue ? 8 : -8)
            }
        }.buttonStyle(.plain)
    }

    // MARK: - 原有 UI 组件
    
    private var artisanHeaderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("智慧调度矩阵").artisanTitleStyle(size: 24)
                    Text("Plum 会在这些应用活跃时自动优化性能。").font(.system(size: 12)).foregroundStyle(LiquidGlassColors.textSecondary)
                }
                Spacer()
                Button(action: { selectApplication() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.app.fill")
                        Text("手动添加")
                    }
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 20).frame(height: 38)
                    .background(Capsule().fill(LiquidGlassColors.primaryPink)).artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3))
                }.buttonStyle(.plain)
            }
            HStack {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(LiquidGlassColors.textQuaternary)
                TextField("检索逻辑库...", text: $searchText).textFieldStyle(.plain).font(.system(size: 13))
            }.padding(.horizontal, 16).frame(height: 38).galleryCardStyle(radius: 12, padding: 0)
        }
    }

    private var artisanEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash").font(.system(size: 40, weight: .ultraLight)).foregroundStyle(LiquidGlassColors.textQuaternary)
            Text("尚未定义任何逻辑流。").font(.system(size: 13)).italic().foregroundStyle(LiquidGlassColors.textQuaternary)
        }.frame(maxWidth: .infinity).padding(.vertical, 60).galleryCardStyle(radius: 24, padding: 0)
    }
}

// MARK: - 精准 UI 单元
private struct ArtisanAppRuleRow: View {
    let rule: AppRule
    let isActive: Bool
    let onUpdate: (RuleAction) -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.04))
                    Image(systemName: "app.fill").font(.system(size: 22)).foregroundStyle(LinearGradient(colors: [.white, .white.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                }.frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.appName).font(.system(size: 14, weight: .bold))
                    Text(rule.bundleIdentifier).font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(LiquidGlassColors.textQuaternary)
                }
            }.padding(.leading, 20)
            Spacer()
            Image(systemName: "arrow.right").font(.system(size: 11, weight: .black)).foregroundStyle(LiquidGlassColors.textQuaternary).padding(.horizontal, 16)
            HStack(spacing: 8) {
                artisanActionChip(action: .pause, icon: "pause.fill", label: "暂停")
                artisanActionChip(action: .limitFPS30, icon: "gauge.medium", label: "30")
                artisanActionChip(action: .limitFPS15, icon: "gauge.low", label: "15")
                artisanActionChip(action: .mute, icon: "speaker.slash.fill", label: "静音")
                Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 1, height: 24).padding(.horizontal, 8)
                Button(action: onDelete) {
                    Image(systemName: "trash.fill").font(.system(size: 12)).foregroundStyle(LiquidGlassColors.errorRed.opacity(isHovered ? 0.8 : 0.2))
                        .frame(width: 32, height: 32).background(Circle().fill(isHovered ? LiquidGlassColors.errorRed.opacity(0.1) : Color.clear))
                }.buttonStyle(.plain)
            }.padding(.trailing, 16)
        }
        .frame(height: 76).background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(isHovered ? 0.06 : 0.02)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(isHovered ? LiquidGlassColors.glassBorder : Color.white.opacity(0.04), lineWidth: 0.5))
        .onHover { isHovered = $0 }.animation(.gallerySpring, value: isHovered)
    }
    
    private func artisanActionChip(action: RuleAction, icon: String, label: String) -> some View {
        let isSelected = rule.action == action
        return Button { onUpdate(action) } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 13))
                Text(label).font(.system(size: 8, weight: .black)).kerning(0.5)
            }
            .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : LiquidGlassColors.textQuaternary)
            .frame(width: 46, height: 42)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(isSelected ? LiquidGlassColors.primaryPink.opacity(0.08) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(isSelected ? LiquidGlassColors.primaryPink.opacity(0.4) : Color.clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

private struct ArtisanRecommendedTile: View {
    let app: (bundleId: String, name: String, action: RuleAction, category: String)
    let onAdd: () -> Void
    @State private var isHovered = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.04))
                    Image(systemName: "app.fill").font(.system(size: 16)).foregroundStyle(LiquidGlassColors.tertiaryBlue)
                }.frame(width: 32, height: 32)
                Spacer()
                Button(action: onAdd) { Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(LiquidGlassColors.primaryPink) }.buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.system(size: 12, weight: .bold)).lineLimit(1).foregroundStyle(LiquidGlassColors.textPrimary)
                Text(app.category).font(.system(size: 9, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
        }
        .padding(14).background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(isHovered ? 0.08 : 0.03)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isHovered ? LiquidGlassColors.glassBorder : Color.clear, lineWidth: 1))
        .onHover { isHovered = $0 }.animation(.gallerySpring, value: isHovered)
    }
}
