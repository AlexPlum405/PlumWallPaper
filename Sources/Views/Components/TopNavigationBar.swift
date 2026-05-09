import SwiftUI
import AppKit

// MARK: - 主标签类型 (工作台版)
enum MainTab: Int, CaseIterable {
    case home           // 精选
    case wallpaper      // 静态
    case media          // 动态
    case myLibrary      // 本地

    var title: String {
        switch self {
        case .home: return "精选"
        case .wallpaper: return "静态"
        case .media: return "动态"
        case .myLibrary: return "本地"
        }
    }

    var icon: String {
        switch self {
        case .home: return "sparkles"
        case .wallpaper: return "rectangle.grid.2x2"
        case .media: return "play.rectangle.on.rectangle"
        case .myLibrary: return "square.stack.3d.up"
        }
    }
}

// MARK: - 匠心导航栏 (Artisan Navigation - 精致圆角修复版)
struct TopNavigationBar: View {
    @Binding var selectedTab: MainTab
    let onSearch: () -> Void
    let onOpenSettings: () -> Void
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    let onZoom: () -> Void

    private let controlHeight: CGFloat = 40

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Color.clear.frame(width: 80, height: controlHeight)

            Spacer()

            studioTabControl

            Spacer()

            HStack(spacing: 12) {
                TopBarCircleButton(icon: "magnifyingglass", size: controlHeight) { onSearch() }
                    .help("搜索内容")
                TopBarCircleButton(icon: "slider.horizontal.3", size: controlHeight) { onOpenSettings() }
                    .help("打开设置")
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var studioTabControl: some View {
        HStack(spacing: 28) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.gallerySpring) { selectedTab = tab }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 7) {
                            Image(systemName: tab.icon).font(.system(size: 11, weight: .semibold))
                            Text(tab.title).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary)

                        Capsule()
                            .fill(selectedTab == tab ? LiquidGlassColors.primaryPink : Color.clear)
                            .frame(width: selectedTab == tab ? 18 : 14, height: 2)
                            .animation(.gallerySpring, value: selectedTab)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .background(Capsule().fill(Color.white.opacity(0.02)))
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        .clipShape(Capsule())
    }

}

struct TopBarCircleButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    @State private var isHovered = false
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 13, weight: .medium))
                .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textSecondary)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .background(Circle().fill(isHovered ? Color.white.opacity(0.08) : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.galleryEase, value: isHovered)
    }
}
