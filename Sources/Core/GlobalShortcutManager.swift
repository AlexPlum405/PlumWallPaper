import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    private var localMonitor: Any?
    private var globalMonitor: Any?
    var onNextWallpaper: (() -> Void)?
    var onPrevWallpaper: (() -> Void)?
    var onTogglePlayback: (() -> Void)?
    var onToggleMute: (() -> Void)?
    var onShowWindow: (() -> Void)?
    var onToggleFavorite: (() -> Void)?

    private init() {}

    func start() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleLocalKeyEvent(event) == true { return nil }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }

    func stop() {
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
    }

    @discardableResult
    private func handleLocalKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        // Space 不在本地监听器中处理，避免干扰文本输入
        // 只处理带修饰键的快捷键

        // ⌥ + → : next wallpaper
        if flags == .option && keyCode == kVK_RightArrow {
            onNextWallpaper?()
            return true
        }
        // ⌥ + ← : prev wallpaper
        if flags == .option && keyCode == kVK_LeftArrow {
            onPrevWallpaper?()
            return true
        }
        // ⌥ + M : toggle mute
        if flags == .option && keyCode == kVK_ANSI_M {
            onToggleMute?()
            return true
        }
        // ⌥ + P : show window
        if flags == .option && keyCode == kVK_ANSI_P {
            onShowWindow?()
            return true
        }
        // ⌘ + Shift + F : toggle favorite
        if flags == [.command, .shift] && keyCode == kVK_ANSI_F {
            onToggleFavorite?()
            return true
        }

        return false
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        // ⌃ + ⌥ + Space : toggle playback (不常用的组合，不会冲突)
        if flags == [.control, .option] && keyCode == kVK_Space {
            onTogglePlayback?()
            return true
        }

        // 其他快捷键也在全局监听器中处理（用户在其他应用时也能用）
        return handleLocalKeyEvent(event)
    }
}
