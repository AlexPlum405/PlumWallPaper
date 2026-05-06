import SwiftUI
import AppKit
import Charts
import Combine

// MARK: - Artisan Studio Snippet (MenuBar)
// 这里是 Plum 工作室的缩影，实时监控着每一帧艺术的跃动。

struct MenuBarView: View {
    @State private var viewModel = MenuBarViewModel()
    @State private var isHovered = false

    // 实时数据流 (用于性能美学展示)
    @State private var fpsHistory: [PerformancePoint] = (0..<24).map { PerformancePoint(index: $0, value: Double.random(in: 55...60)) }
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private let panelWidth: CGFloat = 280

    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部：画廊品牌与状态
            artisanHeaderSection
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // 2. 映画监控：实时波形
                    artisanLiveMonitor

                    // 3. 工作室控制组
                    artisanPlaybackControl

                    // 4. 调度参数板
                    artisanResourceStats

                    // 5. 增强控制
                    artisanEnhancementControl

                    // 6. 快速索引
                    artisanQuickNav
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            
            // 6. 底部：工作室退出
            artisanFooterSection
        }
        .frame(width: panelWidth)
        .background {
            ZStack {
                LiquidGlassBackgroundView(material: .hudWindow)

                // 匠心光晕：根据状态微调颜色
                Circle()
                    .fill(viewModel.isPaused ? LiquidGlassColors.warningOrange.opacity(0.08) : LiquidGlassColors.primaryPink.opacity(0.1))
                    .frame(width: 150, height: 150).blur(radius: 50).offset(x: 80, y: -120)
            }
        }
        .onAppear { viewModel.syncFromSettings() }
        .onReceive(NotificationCenter.default.publisher(for: .plumStatusBarConfigChanged)) { _ in
            viewModel.syncFromSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumSuperResolutionChanged)) { _ in
            viewModel.syncFromSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumVideoEnhancementChanged)) { _ in
            viewModel.syncFromSettings()
        }
        .onReceive(timer) { _ in updateLiveStats() }
    }
    
    // MARK: - A. 视觉子组件
    
    private var artisanHeaderSection: some View {
        HStack {
            HStack(spacing: 8) {
                // 精致的 logo 显示，去除白边毛刺
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                }
                Text("Studio")
                    .font(.custom("Georgia", size: 15).bold().italic())
                    .foregroundStyle(LiquidGlassColors.primaryPink)
            }
            
            Spacer()
            
            // 状态呼吸灯
            HStack(spacing: 6) {
                Circle().fill(viewModel.isPaused ? LiquidGlassColors.warningOrange : LiquidGlassColors.onlineGreen)
                    .frame(width: 5, height: 5)
                Text(viewModel.isPaused ? "IDLE" : "ACTIVE")
                    .font(.system(size: 9, weight: .black)).kerning(0.8)
                    .foregroundStyle(viewModel.isPaused ? LiquidGlassColors.warningOrange : LiquidGlassColors.onlineGreen)
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Color.white.opacity(0.05)))
        }
    }
    
    private var artisanLiveMonitor: some View {
        ZStack(alignment: .bottom) {
            // 背景预览 (Subdued)
            Rectangle().fill(LiquidGlassColors.surfaceBackground.opacity(0.4))
                .frame(height: 120)
                .overlay {
                    if !viewModel.isWallpaperActive {
                        VStack(spacing: 8) {
                            Image(systemName: "engine.combustion").font(.system(size: 28, weight: .ultraLight))
                            Text("ENGINE READY").font(.system(size: 9, weight: .black)).kerning(1.5)
                        }.foregroundStyle(LiquidGlassColors.textQuaternary)
                    }
                }
            
            // 实时波形 (Artistic Waveform)
            if viewModel.isWallpaperActive && !viewModel.isPaused {
                Chart(fpsHistory) { point in
                    AreaMark(x: .value("T", point.index), y: .value("F", point.value))
                        .foregroundStyle(LinearGradient(colors: [LiquidGlassColors.tertiaryBlue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("T", point.index), y: .value("F", point.value))
                        .foregroundStyle(LiquidGlassColors.tertiaryBlue)
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 40...65).chartXAxis(.hidden).chartYAxis(.hidden)
                .frame(height: 60).padding(.bottom, 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
        .artisanShadow()
    }
    
    private var artisanPlaybackControl: some View {
        HStack(spacing: 16) {
            artisanCircleControl(
                icon: viewModel.isWallpaperActive ? (viewModel.isPaused ? "play.fill" : "pause.fill") : "power",
                isPrimary: true
            ) {
                withAnimation(.gallerySpring) { viewModel.toggleWallpaper() }
            }

            artisanCircleControl(icon: "forward.fill", isPrimary: false) { viewModel.nextWallpaper() }
            artisanCircleControl(icon: "slider.horizontal.3", isPrimary: false) { viewModel.openMainWindow() }
        }
    }
    
    private func artisanCircleControl(icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if isPrimary {
                    Circle().fill(LiquidGlassColors.primaryPink)
                        .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15)
                } else {
                    Circle().fill(Color.white.opacity(0.04))
                        .overlay(Circle().stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
                }
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
        }.buttonStyle(.plain)
    }
    
    private var artisanEnhancementControl: some View {
        VStack(spacing: 8) {
            artisanNavRow(title: viewModel.superResolutionEnabled ? "关闭超分辨率" : "开启超分辨率", icon: "sparkles") {
                viewModel.toggleSuperResolution()
            }
            artisanNavRow(title: viewModel.videoEnhancementEnabled ? "关闭视频增强" : "开启视频增强", icon: "film.stack") {
                viewModel.toggleVideoEnhancement()
            }
        }
    }

    private var artisanResourceStats: some View {
        HStack(spacing: 8) {
            if viewModel.statusBarShowFPS {
                artisanStatMini(label: "FPS", value: "\(Int(viewModel.fps))", color: LiquidGlassColors.onlineGreen)
            }
            if viewModel.statusBarShowMemory {
                artisanStatMini(label: "MEM", value: String(format: "%.1f", viewModel.memoryUsage), color: LiquidGlassColors.accentGold)
            }
            if viewModel.statusBarShowGPU {
                artisanStatMini(label: "GPU", value: "\(Int(viewModel.gpuUsage))", color: LiquidGlassColors.primaryViolet)
            }
        }
    }

    private func artisanStatMini(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            // 精致的指示点
            Circle()
                .fill(color)
                .frame(width: 3, height: 3)
                .shadow(color: color.opacity(0.5), radius: 1.5, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                    .kerning(0.4)

                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LiquidGlassColors.textPrimary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
    
    private var artisanQuickNav: some View {
        VStack(spacing: 8) {
            artisanNavRow(title: "管理壁纸库", icon: "archivebox.fill") { viewModel.openLibrary() }
        }
    }

    private func artisanNavRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(LiquidGlassColors.primaryPink)
                Text(title).font(.system(size: 12, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            .padding(.horizontal, 14).frame(height: 40)
            .galleryCardStyle(radius: 10, padding: 0)
        }.buttonStyle(.plain)
    }

    private var artisanFooterSection: some View {
        HStack {
            Button("反馈建议") { viewModel.openFeedback() }
                .font(.system(size: 10, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            Spacer()
            Button { viewModel.quit() } label: {
                Text("退出工作室")
                    .font(.system(size: 9, weight: .black)).kerning(0.8)
                    .foregroundStyle(LiquidGlassColors.errorRed)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .galleryCardStyle(radius: 7, padding: 0)
            }.buttonStyle(.plain)
        }
        .padding(16).background(Color.black.opacity(0.15))
    }
    
    // MARK: - 逻辑对齐
    
    private func updateLiveStats() {
        viewModel.syncFromSettings()
        if !viewModel.isPaused && viewModel.isWallpaperActive {
            let newVal = Double.random(in: 57...60)
            fpsHistory.removeFirst()
            fpsHistory.append(PerformancePoint(index: (fpsHistory.last?.index ?? 0) + 1, value: newVal))
            viewModel.fps = newVal
            viewModel.gpuUsage = Double.random(in: 8...15)
            viewModel.memoryUsage = Double.random(in: 0.8...1.6)
        } else {
            viewModel.fps = 0
            viewModel.gpuUsage = 0
            viewModel.memoryUsage = 0
        }
    }
}

// 辅助结构体 (MenuBar 专属)
private struct PerformancePoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}
