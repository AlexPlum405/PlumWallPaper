import SwiftUI
import AppKit

// MARK: - 主标签类型 (画廊版)
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
        case .home: return "safari"
        case .wallpaper: return "rectangle.on.rectangle.angled"
        case .media: return "film.stack"
        case .myLibrary: return "archivebox"
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
            // 左侧避让区
            Color.clear.frame(width: 80, height: controlHeight)

            Spacer()

            // 核心控制区 (修复：材质与圆角绝对对齐)
            artisanTabControl
            
            Spacer()

            // 右侧功能区
            HStack(spacing: 12) {
                TopBarCircleButton(icon: "magnifyingglass", size: controlHeight) { onSearch() }
                TopBarCircleButton(icon: "slider.horizontal.3", size: controlHeight) { onOpenSettings() }
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var artisanTabControl: some View {
        HStack(spacing: 32) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.gallerySpring) { selectedTab = tab }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon).font(.system(size: 11, weight: .medium))
                            Text(tab.title).font(.system(size: 13, weight: .bold)).kerning(1.5)
                        }
                        .foregroundStyle(selectedTab == tab ? LiquidGlassColors.textPrimary : LiquidGlassColors.textQuaternary)
                        
                        if selectedTab == tab {
                            Capsule().fill(LiquidGlassColors.primaryPink).frame(width: 14, height: 2)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Capsule().fill(Color.clear).frame(width: 14, height: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
        // 修复：强制剪裁与材质同步，消除硬边
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
