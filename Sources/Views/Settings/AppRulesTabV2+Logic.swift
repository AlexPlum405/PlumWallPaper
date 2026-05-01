import SwiftUI
import AppKit

// MARK: - 业务逻辑
extension AppRulesTabV2 {

    // MARK: - 应用规则逻辑（已实现）

    func selectApplication() {
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
                    toast = ToastConfig(message: "该应用已在规则列表中", type: .warning)
                    return
                }
                var rules = viewModel.settings?.appRules ?? []
                rules.append(AppRule(id: "rule_\(Date().timeIntervalSince1970)", bundleIdentifier: bundleId, appName: appName, action: .pause))
                viewModel.settings?.appRules = rules
                viewModel.save()
                toast = ToastConfig(message: "已添加 \(appName)", type: .success)
            }
        }
    }

    func addRecommendedRule(_ app: (bundleId: String, name: String, action: RuleAction, category: String)) {
        var rules = viewModel.settings?.appRules ?? []
        rules.append(AppRule(id: "rule_\(Date().timeIntervalSince1970)", bundleIdentifier: app.bundleId, appName: app.name, action: app.action))
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: "已添加 \(app.name)", type: .success)
    }

    func addAllRecommended() {
        let existing = Set((viewModel.settings?.appRules ?? []).map { $0.bundleIdentifier })
        let newRules = recommendedApps.filter { !existing.contains($0.bundleId) }.map {
            AppRule(id: "rule_\(Date().timeIntervalSince1970)_\($0.bundleId)", bundleIdentifier: $0.bundleId, appName: $0.name, action: $0.action)
        }
        guard !newRules.isEmpty else {
            toast = ToastConfig(message: "所有推荐规则已存在", type: .info)
            return
        }
        var rules = viewModel.settings?.appRules ?? []
        rules.append(contentsOf: newRules)
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: "已导入 \(newRules.count) 条预设规则", type: .success)
    }

    func importAllRecommended() {
        addAllRecommended()
    }

    func toggleRule(_ id: String) {
        guard var rules = viewModel.settings?.appRules else { return }
        if let i = rules.firstIndex(where: { $0.id == id }) {
            rules[i].enabled.toggle()
            viewModel.settings?.appRules = rules
            viewModel.save()
            toast = ToastConfig(message: "\(rules[i].appName) \(rules[i].enabled ? "已启用" : "已禁用")", type: .success)
        }
    }

    func toggleAllRules(enabled: Bool) {
        guard var rules = viewModel.settings?.appRules else { return }
        for i in rules.indices {
            rules[i].enabled = enabled
        }
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: enabled ? "已全部启用" : "已全部禁用", type: .success)
    }

    func updateRuleAction(_ id: String, action: RuleAction) {
        guard var rules = viewModel.settings?.appRules else { return }
        if let i = rules.firstIndex(where: { $0.id == id }) {
            var r = AppRule(id: rules[i].id, bundleIdentifier: rules[i].bundleIdentifier, appName: rules[i].appName, action: action, enabled: rules[i].enabled)
            r.triggerCount = rules[i].triggerCount
            r.lastTriggered = rules[i].lastTriggered
            rules[i] = r
            viewModel.settings?.appRules = rules
            viewModel.save()
            toast = ToastConfig(message: "已更新 \(rules[i].appName) 的规则", type: .success)
        }
    }

    func deleteRule(_ id: String) {
        guard var rules = viewModel.settings?.appRules else { return }
        let name = rules.first(where: { $0.id == id })?.appName ?? ""
        rules.removeAll { $0.id == id }
        viewModel.settings?.appRules = rules
        viewModel.save()
        toast = ToastConfig(message: "已删除 \(name) 的规则", type: .success)
    }

    func isRuleActive(_ id: String) -> Bool {
        false
    }

    // MARK: - 全局暂停策略（占位，由 Claude 后续实现）

    func setPauseOnBattery(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnBattery: \(enabled)")
    }

    func setPauseOnFullscreen(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnFullscreen: \(enabled)")
    }

    func setPauseOnLowBattery(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnLowBattery: \(enabled)")
    }

    func setLowBatteryThreshold(_ threshold: Int) {
        // TODO: 由 Claude 实现
        print("setLowBatteryThreshold: \(threshold)")
    }

    func setPauseOnScreenSharing(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnScreenSharing: \(enabled)")
    }

    func setPauseOnHighLoad(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnHighLoad: \(enabled)")
    }

    func setPauseOnLostFocus(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnLostFocus: \(enabled)")
    }

    func setPauseOnLidClosed(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnLidClosed: \(enabled)")
    }

    func setPauseBeforeSleep(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseBeforeSleep: \(enabled)")
    }

    func setPauseOnOcclusion(_ enabled: Bool) {
        // TODO: 由 Claude 实现
        print("setPauseOnOcclusion: \(enabled)")
    }
}
