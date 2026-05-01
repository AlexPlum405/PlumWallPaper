import SwiftUI

struct ShortcutsTab: View {
    @State var recordingKey: String? = nil // 当前正在录制的快捷键 ID
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "系统快捷键 (GLOBAL HOTKEYS)") {
                    shortcutRow(id: "toggle", title: "播放 / 暂停", current: "⌘ ⌥ P")
                    shortcutRow(id: "prev", title: "上一张壁纸", current: "⌘ ⌥ [")
                    shortcutRow(id: "next", title: "下一张壁纸", current: "⌘ ⌥ ]")
                    shortcutRow(id: "settings", title: "打开设置中心", current: "⌘ ⌥ S")
                    shortcutRow(id: "library", title: "打开本地", current: "⌘ ⌥ L", showDivider: false)
                }
                
                Button(action: { resetAllShortcuts() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("重置所有快捷键")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.errorRed)
                    .padding(.horizontal, 20)
                    .frame(height: 38)
                    .galleryCardStyle(radius: 19, padding: 0)
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    private func shortcutRow(id: String, title: String, current: String, showDivider: Bool = true) -> some View {
        artisanSettingsRow(title: title, subtitle: "全局有效，即使应用在后台", showDivider: showDivider) {
            Button {
                withAnimation(.gallerySpring) {
                    recordingKey = (recordingKey == id) ? nil : id
                }
            } label: {
                ZStack {
                    if recordingKey == id {
                        Text("请按下快捷键...")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 100, minHeight: 28)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink.opacity(0.1)))
                            .overlay(Capsule().stroke(LiquidGlassColors.primaryPink.opacity(0.3), lineWidth: 1))
                    } else {
                        HStack(spacing: 8) {
                            Text(current)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(LiquidGlassColors.textSecondary)
                            
                            Image(systemName: "keyboard")
                                .font(.system(size: 10))
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                        }
                        .padding(.horizontal, 12)
                        .frame(minWidth: 100, minHeight: 28)
                        .background(Capsule().fill(Color.white.opacity(0.04)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
