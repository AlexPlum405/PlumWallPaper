import SwiftUI
import AppKit

// MARK: - 主标签类型 (重构版 - 4个 Tab)
enum MainTab: String, CaseIterable {
    case home           // 首页
    case wallpaper      // 壁纸
    case media          // 媒体
    case myLibrary      // 我的

    var title: String {
        switch self {
        case .home: return "首页"
        case .wallpaper: return "壁纸"
        case .media: return "媒体"
        case .myLibrary: return "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .wallpaper: return "photo.on.rectangle"
        case .media: return "play.rectangle.on.rectangle.fill"
        case .myLibrary: return "person.crop.circle"
        }
    }
}

// MARK: - 顶部导航栏组件
struct TopNavigationBar: View {
    @Binding var selectedTab: MainTab
    let onOpenSettings: () -> Void
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    let onZoom: () -> Void
    
    private let controlHeight: CGFloat = 34

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 左侧红绿灯占位（macOS 原生控制按钮）
            Color.clear
                .frame(width: 80, height: controlHeight, alignment: Alignment.center)

            Spacer()

            // 中间 Tabs - 核心复刻 WaifuX
            TopBarSegmentedControl(
                selectedTab: $selectedTab,
                controlHeight: controlHeight
            )
            .frame(height: controlHeight, alignment: .center)

            Spacer()

            // 右侧设置按钮
            TopBarCircleButton(icon: "gearshape", size: controlHeight) {
                onOpenSettings()
            }
            .frame(width: 48, height: controlHeight, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
}

// MARK: - 子组件 (保持 internal，不使用 public)

struct TopBarSegmentedControl: View {
    @Binding var selectedTab: MainTab
    let controlHeight: CGFloat

    @Namespace private var selectionNamespace
    @State private var hoveredTab: MainTab?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12))
                        Text(tab.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(labelColor(for: tab))
                    .padding(.horizontal, 16)
                    .frame(height: controlHeight)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .matchedGeometryEffect(id: "selectedTab", in: selectionNamespace)
                        } else if hoveredTab == tab {
                            Capsule()
                                .fill(Color.white.opacity(0.05))
                        }
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredTab = hovering ? tab : nil
                    }
                }
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }

    private func labelColor(for tab: MainTab) -> Color {
        if selectedTab == tab {
            return .white
        }
        return .white.opacity(0.6)
    }
}

struct TopBarCircleButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(isHovered ? 1.0 : 0.7))
                .frame(width: size + 10, height: size + 10)
                .background {
                    Circle()
                        .fill(isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
