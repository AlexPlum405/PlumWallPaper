import SwiftUI
import AppKit

/// 应用规则管理页面
struct AppRulesTabV2: View {
    var viewModel: SettingsViewModel
    @Binding var toast: ToastConfig?

    @State private var searchText = ""
    @State private var selectedRuleId: String?
    @State private var showAdvancedSettings = false

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                if !configuredRules.isEmpty { configuredRulesSection }
                if !filteredRecommendations.isEmpty { recommendedRulesSection }
                if configuredRules.isEmpty && filteredRecommendations.isEmpty { emptyStateView }
            }
            .padding(40)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                LiquidGlassSectionHeader(title: "应用专属策略", icon: "app.badge.shield", color: LiquidGlassColors.tertiaryBlue)
                Text("当检测到特定应用运行时，自动调整 Plum 的渲染行为")
                    .font(.system(size: 12))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
            Spacer()
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                    TextField("搜索应用", text: $searchText).textFieldStyle(.plain).font(.system(size: 13))
                }
                .padding(.horizontal, 12).padding(.vertical, 8).frame(width: 200)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 1))

                Button { selectApplication() } label: {
                    HStack(spacing: 6) { Image(systemName: "plus"); Text("添加应用") }
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(LiquidGlassColors.primaryPink)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 1))
                }.buttonStyle(.plain)

                Button { importAllRecommended() } label: {
                    Text("导入预设").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: - Configured Rules

    private var configuredRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("已配置规则 (\(configuredRules.count))")
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(.white.opacity(0.6)).textCase(.uppercase).tracking(1)
                Spacer()
                Button("全部启用") { toggleAllRules(enabled: true) }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(LiquidGlassColors.onlineGreen).buttonStyle(.plain)
                Button("全部禁用") { toggleAllRules(enabled: false) }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.4)).buttonStyle(.plain)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 20)], spacing: 20) {
                ForEach(configuredRules) { rule in
                    AppRuleCard(
                        rule: rule, isActive: isRuleActive(rule),
                        onToggle: { toggleRule(rule) },
                        onActionChange: { updateRuleAction(rule, action: $0) },
                        onDelete: { deleteRule(rule) }
                    )
                }
            }
        }
    }

    // MARK: - Recommended Rules

    private var recommendedRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("推荐配置 (\(filteredRecommendations.count))")
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(.white.opacity(0.6)).textCase(.uppercase).tracking(1)
                Spacer()
                Button("一键添加全部") { addAllRecommended() }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(LiquidGlassColors.primaryPink).buttonStyle(.plain)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 20)], spacing: 20) {
                ForEach(filteredRecommendations, id: \.bundleId) { app in
                    RecommendedAppCard(appName: app.name, bundleId: app.bundleId, recommendedAction: app.action, category: app.category) {
                        addRecommendedRule(app)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            ZStack {
                Circle().fill(.white.opacity(0.03)).frame(width: 120, height: 120)
                Image(systemName: "app.badge.shield").font(.system(size: 48, weight: .ultraLight)).foregroundStyle(LiquidGlassColors.tertiaryBlue.opacity(0.3))
            }
            VStack(spacing: 8) {
                Text("尚未配置任何应用规则").font(.system(size: 18, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                Text("点击上方添加应用或导入预设开始配置").font(.system(size: 14)).foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var configuredRules: [AppRule] {
        let rules = viewModel.settings?.appRules ?? []
        if searchText.isEmpty { return rules }
        return rules.filter { $0.appName.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredRecommendations: [(bundleId: String, name: String, action: RuleAction, category: String)] {
        let existingBundleIds = Set((viewModel.settings?.appRules ?? []).map { $0.bundleIdentifier })
        let available = recommendedApps.filter { !existingBundleIds.contains($0.bundleId) }
        if searchText.isEmpty { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func isRuleActive(_ rule: AppRule) -> Bool { false }

    // MARK: - Actions

    private func selectApplication() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.message = "选择要添加规则的应用"
        panel.prompt = "选择"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                let bundle = Bundle(url: url)
                let bundleId = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let appName = url.deletingPathExtension().lastPathComponent
                if let rules = viewModel.settings?.appRules, rules.contains(where: { $0.bundleIdentifier == bundleId }) {
                    toast = ToastConfig(message: "该应用已在规则列表中", type: .warning)
                    return
                }
                let newRule = AppRule(id: "rule_\(Date().timeIntervalSince1970)", bundleIdentifier: bundleId, appName: appName, action: .pause)
                var rules = viewModel.settings?.appRules ?? []
                rules.append(newRule)
                viewModel.settings?.appRules = rules
                viewModel.save()
                toast = ToastConfig(message: "已添加 \(appName)", type: .success)
            }
        }
    }

    private func addRecommendedRule(_ app: (bundleId: String, name: String, action: RuleAction, category: String)) {
        let newRule = AppRule(id: "rule_\(Date().timeIntervalSince1970)", bundleIdentifier: app.bundleId, appName: app.name, action: app.action)
        var rules = viewModel.settings?.appRules ?? []
        rules.append(newRule)
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: "已添加 \(app.name)", type: .success)
    }

    private func addAllRecommended() {
        let existingBundleIds = Set((viewModel.settings?.appRules ?? []).map { $0.bundleIdentifier })
        let newRules = recommendedApps.filter { !existingBundleIds.contains($0.bundleId) }.map {
            AppRule(id: "rule_\(Date().timeIntervalSince1970)_\($0.bundleId)", bundleIdentifier: $0.bundleId, appName: $0.name, action: $0.action)
        }
        guard !newRules.isEmpty else { toast = ToastConfig(message: "所有推荐规则已存在", type: .info); return }
        var rules = viewModel.settings?.appRules ?? []
        rules.append(contentsOf: newRules)
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: "已导入 \(newRules.count) 条预设规则", type: .success)
    }

    private func importAllRecommended() { addAllRecommended() }

    private func toggleRule(_ rule: AppRule) {
        guard var rules = viewModel.settings?.appRules else { return }
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].enabled.toggle()
            viewModel.settings?.appRules = rules
            viewModel.save()
            toast = ToastConfig(message: "\(rule.appName) \(rules[index].enabled ? "已启用" : "已禁用")", type: .success)
        }
    }

    private func toggleAllRules(enabled: Bool) {
        guard var rules = viewModel.settings?.appRules else { return }
        for i in rules.indices { rules[i].enabled = enabled }
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: enabled ? "已全部启用" : "已全部禁用", type: .success)
    }

    private func updateRuleAction(_ rule: AppRule, action: RuleAction) {
        guard var rules = viewModel.settings?.appRules else { return }
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            var r = AppRule(id: rule.id, bundleIdentifier: rule.bundleIdentifier, appName: rule.appName, action: action, enabled: rules[index].enabled)
            r.triggerCount = rules[index].triggerCount
            r.lastTriggered = rules[index].lastTriggered
            rules[index] = r
            viewModel.settings?.appRules = rules
            viewModel.save()
            toast = ToastConfig(message: "已更新 \(rule.appName) 的规则", type: .success)
        }
    }

    private func deleteRule(_ rule: AppRule) {
        guard var rules = viewModel.settings?.appRules else { return }
        rules.removeAll { $0.id == rule.id }
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: "已删除 \(rule.appName) 的规则", type: .success)
    }
}

// MARK: - App Rule Card

private struct AppRuleCard: View {
    let rule: AppRule
    let isActive: Bool
    let onToggle: () -> Void
    let onActionChange: (RuleAction) -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.05))
                    Image(systemName: "app.fill").font(.system(size: 20)).foregroundStyle(LiquidGlassColors.tertiaryBlue)
                }.frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.appName).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                    HStack(spacing: 4) {
                        Circle().fill(isActive ? LiquidGlassColors.onlineGreen : (rule.enabled ? .white.opacity(0.3) : .red.opacity(0.5))).frame(width: 6, height: 6)
                        Text(isActive ? "正在生效" : (rule.enabled ? "已启用" : "已禁用"))
                            .font(.system(size: 10, weight: isActive ? .bold : .medium))
                            .foregroundStyle(isActive ? LiquidGlassColors.onlineGreen : (rule.enabled ? .white.opacity(0.5) : .red.opacity(0.7)))
                    }
                }
                Spacer()
            }
            // Action picker
            Menu {
                Button("暂停壁纸") { onActionChange(.pause) }
                Button("静音壁纸") { onActionChange(.mute) }
                Button("降低到 30fps") { onActionChange(.limitFPS30) }
                Button("降低到 15fps") { onActionChange(.limitFPS15) }
            } label: {
                HStack {
                    Text(actionLabel(rule.action)).font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 1))
            }.menuStyle(.borderlessButton)

            HStack(spacing: 16) {
                statItem(icon: "clock", label: "触发", value: "\(rule.triggerCount) 次")
                statItem(icon: "bolt.fill", label: "最后", value: lastTriggeredText(rule.lastTriggered))
            }

            Divider().background(.white.opacity(0.1))

            HStack(spacing: 12) {
                Button { onToggle() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "power").font(.system(size: 11))
                        Text(rule.enabled ? "禁用" : "启用").font(.system(size: 11, weight: .medium))
                    }.foregroundStyle(.white.opacity(0.6)).frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.05)))
                }.buttonStyle(.plain)

                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(.red.opacity(0.7))
                        .frame(width: 32, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.05)))
                }.buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(isHovered ? 0.06 : 0.04)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isActive ? LiquidGlassColors.onlineGreen.opacity(0.3) : .white.opacity(0.08), lineWidth: 1))
        .shadow(color: isActive ? LiquidGlassColors.onlineGreen.opacity(0.1) : .clear, radius: 10)
        .onHover { isHovered = $0 }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { onDelete() }
        } message: { Text("确定要删除 \(rule.appName) 的规则吗？") }
    }

    private func statItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(.white.opacity(0.4))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                Text(value).font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.8))
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionLabel(_ action: RuleAction) -> String {
        switch action {
        case .pause: return "暂停壁纸"; case .mute: return "静音壁纸"
        case .limitFPS30: return "降低到 30fps"; case .limitFPS15: return "降低到 15fps"; case .none: return "无操作"
        }
    }

    private func lastTriggeredText(_ date: Date?) -> String {
        guard let date = date else { return "从未" }
        let s = Date().timeIntervalSince(date)
        if s < 60 { return "刚刚" } else if s < 3600 { return "\(Int(s/60))分钟前" }
        else if s < 86400 { return "\(Int(s/3600))小时前" } else { return "\(Int(s/86400))天前" }
    }
}

// MARK: - Recommended App Card

private struct RecommendedAppCard: View {
    let appName: String
    let bundleId: String
    let recommendedAction: RuleAction
    let category: String
    let onAdd: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.3)))
                    Image(systemName: "app.fill").font(.system(size: 20)).foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.5))
                }.frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appName).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                    Text(category).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "star.fill").font(.system(size: 14)).foregroundStyle(LiquidGlassColors.primaryPink)
            }
            HStack {
                Text("推荐：\(actionLabel(recommendedAction))").font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
            Button { onAdd() } label: {
                HStack(spacing: 6) { Image(systemName: "plus"); Text("添加规则") }
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .leading, endPoint: .trailing)))
            }.buttonStyle(.plain)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(isHovered ? 0.04 : 0.02)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 6])).foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.2)))
        .onHover { isHovered = $0 }
    }

    private func actionLabel(_ action: RuleAction) -> String {
        switch action {
        case .pause: return "暂停壁纸"; case .mute: return "静音壁纸"
        case .limitFPS30: return "降低到 30fps"; case .limitFPS15: return "降低到 15fps"; case .none: return "无操作"
        }
    }
}

