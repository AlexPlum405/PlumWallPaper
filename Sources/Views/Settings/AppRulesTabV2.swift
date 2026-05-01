import SwiftUI
import AppKit

struct AppRulesTabV2: View {
    var viewModel: SettingsViewModel
    @Binding var toast: ToastConfig?

    @State private var searchText = ""
    @State private var selectedCategory: String = "全部"
    @State private var isHoveredAdd = false
    
    // 推荐分类
    private let categories = ["全部", "视频编辑", "3D 渲染", "开发工具", "音频制作"]

    // 推荐应用列表 (禁止修改内容)
    private let recommendedApps: [(bundleId: String, name: String, action: RuleAction, category: String)] = [
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

    // 已配置的规则 (禁止修改逻辑)
    private var configuredRules: [AppRule] {
        viewModel.settings?.appRules.filter { rule in
            searchText.isEmpty || rule.appName.localizedCaseInsensitiveContains(searchText)
        } ?? []
    }

    // 过滤后的推荐列表 (禁止修改逻辑)
    private var filteredRecommendations: [(bundleId: String, name: String, action: RuleAction, category: String)] {
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
            headerSection
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // 2. 已激活的策略卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("当前生效的策略", systemImage: "bolt.shield.fill")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                                .kerning(1)
                            Spacer()
                            if !configuredRules.isEmpty {
                                Button("全部禁用") { toggleAllRules(enabled: false) }
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(LiquidGlassColors.primaryPink)
                                    .buttonStyle(.plain)
                            }
                        }
                        
                        if !configuredRules.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(configuredRules) { rule in
                                    AppStrategyCard(rule: rule, 
                                                  isActive: isRuleActive(rule.id),
                                                  onToggle: { toggleRule(rule.id) },
                                                  onUpdate: { updateRuleAction(rule.id, action: $0) },
                                                  onDelete: { deleteRule(rule.id) })
                                }
                            }
                        } else if searchText.isEmpty {
                            emptyStateView
                        }
                    }
                    
                    // 3. 智能发现与一键导入
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("智能发现推荐", systemImage: "sparkles")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                                .kerning(1)
                            Spacer()
                            Button("一键导入所有") { addAllRecommended() }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.tertiaryBlue)
                                .buttonStyle(.plain)
                        }
                        
                        // 分类筛选
                        FlowLayout(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                FilterChip(title: cat, isSelected: selectedCategory == cat) {
                                    selectedCategory = cat
                                }
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 12) {
                            ForEach(filteredRecommendations, id: \.bundleId) { app in
                                RecommendedAppCard(app: app) {
                                    addRecommendedRule(app)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .background(Color(hex: "1C1C1E"))
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能渲染策略")
                        .font(.system(size: 22, weight: .bold))
                    Text("当检测到特定应用处于前台时，自动调整 Plum 的渲染行为以优化系统性能。")
                        .font(.system(size: 12))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                }
                Spacer()
                
                Button(action: { selectApplication() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("手动添加应用")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(
                        Capsule().fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                TextField("搜索已配置或推荐的应用...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.white.opacity(0.03)).frame(width: 80, height: 80)
                Image(systemName: "app.badge.shield")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            VStack(spacing: 6) {
                Text("专注于你的工作")
                    .font(.system(size: 14, weight: .bold))
                Text("添加如「Final Cut Pro」或「Blender」等专业软件，\n在运行它们时 Plum 会自动释放性能。")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            
            Button("从预设库导入常见应用") { importAllRecommended() }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(LiquidGlassColors.tertiaryBlue)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.02)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 逻辑函数
    private func selectApplication() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "选择要添加规则的应用"
        panel.prompt = "选择"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                let bundle = Bundle(url: url)
                let bundleId = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let appName = url.deletingPathExtension().lastPathComponent
                if let rules = viewModel.settings?.appRules, rules.contains(where: { $0.bundleIdentifier == bundleId }) {
                    toast = ToastConfig(message: "该应用已在规则列表中", type: .warning); return
                }
                var rules = viewModel.settings?.appRules ?? []
                rules.append(AppRule(id: "rule_\(Date().timeIntervalSince1970)", bundleIdentifier: bundleId, appName: appName, action: .pause))
                viewModel.settings?.appRules = rules; viewModel.save()
                toast = ToastConfig(message: "已添加 \(appName)", type: .success)
            }
        }
    }

    private func addRecommendedRule(_ app: (bundleId: String, name: String, action: RuleAction, category: String)) {
        var rules = viewModel.settings?.appRules ?? []
        rules.append(AppRule(id: "rule_\(Date().timeIntervalSince1970)", bundleIdentifier: app.bundleId, appName: app.name, action: app.action))
        viewModel.settings?.appRules = rules; viewModel.save()
        toast = ToastConfig(message: "已添加 \(app.name)", type: .success)
    }

    private func addAllRecommended() {
        let existing = Set((viewModel.settings?.appRules ?? []).map { $0.bundleIdentifier })
        let newRules = recommendedApps.filter { !existing.contains($0.bundleId) }.map {
            AppRule(id: "rule_\(Date().timeIntervalSince1970)_\($0.bundleId)", bundleIdentifier: $0.bundleId, appName: $0.name, action: $0.action)
        }
        guard !newRules.isEmpty else { toast = ToastConfig(message: "所有推荐规则已存在", type: .info); return }
        var rules = viewModel.settings?.appRules ?? []
        rules.append(contentsOf: newRules)
        viewModel.settings?.appRules = rules; viewModel.save()
        toast = ToastConfig(message: "已导入 \(newRules.count) 条预设规则", type: .success)
    }

    private func importAllRecommended() { addAllRecommended() }

    private func toggleRule(_ id: String) {
        guard var rules = viewModel.settings?.appRules else { return }
        if let i = rules.firstIndex(where: { $0.id == id }) {
            rules[i].enabled.toggle()
            viewModel.settings?.appRules = rules; viewModel.save()
            toast = ToastConfig(message: "\(rules[i].appName) \(rules[i].enabled ? "已启用" : "已禁用")", type: .success)
        }
    }

    private func toggleAllRules(enabled: Bool) {
        guard var rules = viewModel.settings?.appRules else { return }
        for i in rules.indices { rules[i].enabled = enabled }
        viewModel.settings?.appRules = rules; viewModel.save()
        toast = ToastConfig(message: enabled ? "已全部启用" : "已全部禁用", type: .success)
    }

    private func updateRuleAction(_ id: String, action: RuleAction) {
        guard var rules = viewModel.settings?.appRules else { return }
        if let i = rules.firstIndex(where: { $0.id == id }) {
            var r = AppRule(id: rules[i].id, bundleIdentifier: rules[i].bundleIdentifier, appName: rules[i].appName, action: action, enabled: rules[i].enabled)
            r.triggerCount = rules[i].triggerCount; r.lastTriggered = rules[i].lastTriggered
            rules[i] = r; viewModel.settings?.appRules = rules; viewModel.save()
            toast = ToastConfig(message: "已更新 \(rules[i].appName) 的规则", type: .success)
        }
    }

    private func deleteRule(_ id: String) {
        guard var rules = viewModel.settings?.appRules else { return }
        let name = rules.first(where: { $0.id == id })?.appName ?? ""
        rules.removeAll { $0.id == id }
        viewModel.settings?.appRules = rules; viewModel.save()
        toast = ToastConfig(message: "已删除 \(name) 的规则", type: .success)
    }

    private func isRuleActive(_ id: String) -> Bool { false }
}

// MARK: - 辅助子组件

private struct AppStrategyCard: View {
    let rule: AppRule
    let isActive: Bool
    let onToggle: () -> Void
    let onUpdate: (RuleAction) -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 应用身份
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.05))
                    Image(systemName: "app.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.appName).font(.system(size: 14, weight: .bold))
                    Text(rule.bundleIdentifier).font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(LiquidGlassColors.textQuaternary)
                }
            }
            .padding(.leading, 16)
            
            Spacer()
            
            // 策略选择芯片 (If -> Then 逻辑)
            HStack(spacing: 6) {
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .black)).foregroundStyle(LiquidGlassColors.textQuaternary).padding(.horizontal, 10)
                
                strategyChip(action: .pause, icon: "pause.circle.fill", label: "暂停")
                strategyChip(action: .mute, icon: "speaker.slash.fill", label: "静音")
                strategyChip(action: .limitFPS30, icon: "gauge.medium", label: "30FPS")
                strategyChip(action: .limitFPS15, icon: "gauge.low", label: "15FPS")
                strategyChip(action: .none, icon: "minus.circle", label: "无操作")
                
                Divider().frame(height: 24).background(Color.white.opacity(0.08)).padding(.horizontal, 8)
                
                // 快捷删除
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(isHovered ? 0.8 : 0.2))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(isHovered ? Color.red.opacity(0.1) : Color.clear))
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 16)
        }
        .frame(height: 76)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.05 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private func strategyChip(action: RuleAction, icon: String, label: String) -> some View {
        let isSelected = rule.action == action
        return Button { onUpdate(action) } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : LiquidGlassColors.textTertiary)
            .frame(width: 50, height: 44)
            .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? LiquidGlassColors.primaryPink.opacity(0.1) : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? LiquidGlassColors.primaryPink.opacity(0.3) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct RecommendedAppCard: View {
    let app: (bundleId: String, name: String, action: RuleAction, category: String)
    let onAdd: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05))
                    Image(systemName: "app.fill").font(.system(size: 16)).foregroundStyle(LiquidGlassColors.tertiaryBlue)
                }.frame(width: 32, height: 32)
                
                Spacer()
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                }.buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.system(size: 12, weight: .bold)).lineLimit(1).foregroundStyle(LiquidGlassColors.textPrimary)
                Text(app.category).font(.system(size: 9)).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(isHovered ? 0.08 : 0.04)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(isHovered ? 0.12 : 0.08), lineWidth: 1))
        .onHover { isHovered = $0 }
    }
}
