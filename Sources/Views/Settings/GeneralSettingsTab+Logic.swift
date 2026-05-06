import SwiftUI
import AppKit

extension GeneralSettingsTab {
    // MARK: - 业务逻辑

    func setLaunchAtLogin(_ enabled: Bool) {
        viewModel.setLaunchAtLogin(enabled)
    }

    func setMenuBarEnabled(_ enabled: Bool) {
        viewModel.setMenuBarEnabled(enabled)
    }

    func changeLibraryPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "选择"
        panel.message = "选择 PlumWallPaper 的资源存储目录"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                viewModel.setLibraryPath(url.path)
            }
        }
    }

    func clearCache() {
        Task {
            await viewModel.clearCaches()
        }
    }

    func resetAllShortcuts() {
        GlobalShortcutManager.shared.stop()
        GlobalShortcutManager.shared.start()
    }

    func setProxyMode(_ mode: ProxyMode) {
        viewModel.setProxyMode(mode)
    }

    func setProxyHost(_ host: String) {
        viewModel.setProxyHost(host)
    }

    func setProxyPort(_ port: Int) {
        viewModel.setProxyPort(port)
    }

    var proxyModeDescription: String {
        switch viewModel.settings?.proxyMode ?? .system {
        case .system: return "使用系统代理设置"
        case .manual: return "手动指定代理服务器"
        case .direct: return "不使用任何代理，直接连接"
        }
    }
}
