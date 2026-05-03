import SwiftUI
import AppKit

// MARK: - Artisan Strategy Matrix (Scheme C: Artisan Gallery)
// 这里是 Plum 的智慧中枢，每一条逻辑流都清晰如画。

struct AppRulesTabV2: View {
    var viewModel: SettingsViewModel
    @Binding var toast: ToastConfig?

    @State private var searchText = ""
    @State private var selectedCategory: String = "全部"
    @State private var isSlideshowExpanded = true
    
    // 推荐分类 (维持原样)
    private let categories = ["全部", "视频编辑", "3D 渲染", "开发工具", "音频制作"]
    private let mockTags = ["全量作品", "收藏精选", "4K UHD", "视觉诗篇", "极简空间"]

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
                    slideshowAutomationSection
                    
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
                .padding(.top, 32)
                .padding(.bottom, 60)
            }
        }
        .background(LiquidGlassColors.deepBackground)
    }

    // MARK: - 原有 UI 组件
    private var slideshowAutomationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                LiquidGlassSectionHeader(title: "自动轮播", icon: "shuffle", color: LiquidGlassColors.primaryPink)
                Text("SLIDESHOW AUTOMATION").font(.system(size: 10, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
                Spacer()
            }
            .padding(.horizontal, 32)

            VStack(spacing: 0) {
                artisanSettingsRow(title: "启用自动轮播", subtitle: "按规则自动切换桌面动态壁纸", showDivider: viewModel.settings?.slideshowEnabled ?? false) {
                    artisanToggle(isOn: Binding(
                        get: { viewModel.settings?.slideshowEnabled ?? false },
                        set: { setSlideshowEnabled($0) }
                    ))
                }

                if viewModel.settings?.slideshowEnabled ?? false {
                    Button {
                        withAnimation(.gallerySpring) { isSlideshowExpanded.toggle() }
                    } label: {
                        HStack {
                            Label("轮播规则", systemImage: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.textSecondary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .rotationEffect(.degrees(isSlideshowExpanded ? 180 : 0))
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.02))
                    }
                    .buttonStyle(.plain)

                    if isSlideshowExpanded {
                        VStack(spacing: 0) {
                            artisanSettingsRow(title: "轮播间隔", subtitle: "每次切换之间的时间跨度") {
                                HStack(spacing: 12) {
                                    Text(formatInterval(viewModel.settings?.slideshowInterval ?? 3600))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(LiquidGlassColors.primaryPink)
                                        .frame(width: 60)
                                    Slider(value: Binding(
                                        get: { viewModel.settings?.slideshowInterval ?? 3600 },
                                        set: { setSlideshowInterval($0) }
                                    ), in: 60...7200, step: 60)
                                    .tint(LiquidGlassColors.primaryPink)
                                    .frame(width: 110)
                                }
                            }

                            artisanSettingsRow(title: "播放顺序", subtitle: "决定作品出现逻辑") {
                                Picker("", selection: Binding(
                                    get: { viewModel.settings?.slideshowOrder ?? .random },
                                    set: { setSlideshowOrder($0) }
                                )) {
                                    Text("顺序").tag(SlideshowOrder.sequential)
                                    Text("随机").tag(SlideshowOrder.random)
                                    Text("收藏优先").tag(SlideshowOrder.favoritesFirst)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 190)
                            }

                            artisanSettingsRow(title: "资源来源", subtitle: "限定自动轮播范围", showDivider: viewModel.settings?.slideshowSource == .tag) {
                                Picker("", selection: Binding(
                                    get: { viewModel.settings?.slideshowSource ?? .all },
                                    set: { setSlideshowSource($0) }
                                )) {
                                    Text("全部").tag(SlideshowSource.all)
                                    Text("收藏").tag(SlideshowSource.favorites)
                                    Text("标签").tag(SlideshowSource.tag)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 170)
                            }

                            if viewModel.settings?.slideshowSource == .tag {
                                artisanSettingsRow(title: "目标标签", subtitle: "从选定分类中挑选", showDivider: false) {
                                    Picker("", selection: Binding(
                                        get: { viewModel.settings?.slideshowTagId ?? "" },
                                        set: { setSlideshowTagId($0) }
                                    )) {
                                        ForEach(mockTags, id: \.self) { Text($0).tag($0) }
                                    }
                                    .frame(width: 150)
                                }
                            }
                        }
                        .background(Color.black.opacity(0.1))
                    }
                }
            }
            .galleryCardStyle(radius: 20, padding: 0)
            .padding(.horizontal, 32)
        }
    }

    private func formatInterval(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        return minutes < 60 ? "\(minutes) 分钟" : "\(minutes / 60) 小时"
    }
    
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
