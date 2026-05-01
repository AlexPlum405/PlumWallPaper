import SwiftUI
import AppKit
import Charts

// MARK: - Artisan Studio Snippet (MenuBar)
// 这里是 Plum 工作室的缩影，实时监控着每一帧艺术的跃动。

struct MenuBarView: View {
    @State private var viewModel = MenuBarViewModel()
    @State private var isHovered = false
    
    // 实时数据流 (用于性能美学展示)
    @State private var fpsHistory: [PerformancePoint] = (0..<24).map { PerformancePoint(index: $0, value: Double.random(in: 55...60)) }
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private let panelWidth: CGFloat = 360
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部：画廊品牌与状态
            artisanHeaderSection
                .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    // 2. 映画监控：实时波形
                    artisanLiveMonitor
                    
                    // 3. 工作室控制组
                    artisanPlaybackControl
                    
                    // 4. 调度参数板
                    artisanResourceStats
                    
                    // 5. 快速索引
                    artisanQuickNav
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
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
                    .fill(viewModel.isPaused ? LiquidGlassColors.warningOrange.opacity(0.1) : LiquidGlassColors.primaryPink.opacity(0.12))
                    .frame(width: 200, height: 200).blur(radius: 60).offset(x: 100, y: -150)
            }
        }
        .onReceive(timer) { _ in updateLiveStats() }
    }
    
    // MARK: - A. 视觉子组件
    
    private var artisanHeaderSection: some View {
        HStack {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage()).resizable().frame(width: 28, height: 28)
                Text("Studio")
                    .font(.custom("Georgia", size: 18).bold().italic())
                    .foregroundStyle(LiquidGlassColors.primaryPink)
            }
            
            Spacer()
            
            // 状态呼吸灯
            HStack(spacing: 8) {
                Circle().fill(viewModel.isPaused ? LiquidGlassColors.warningOrange : LiquidGlassColors.onlineGreen)
                    .frame(width: 6, height: 6)
                Text(viewModel.isPaused ? "IDLE" : "ACTIVE")
                    .font(.system(size: 10, weight: .black)).kerning(1)
                    .foregroundStyle(viewModel.isPaused ? LiquidGlassColors.warningOrange : LiquidGlassColors.onlineGreen)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.05)))
        }
    }
    
    private var artisanLiveMonitor: some View {
        ZStack(alignment: .bottom) {
            // 背景预览 (Subdued)
            Rectangle().fill(LiquidGlassColors.surfaceBackground.opacity(0.4))
                .frame(height: 180)
                .overlay {
                    if !viewModel.isWallpaperActive {
                        VStack(spacing: 12) {
                            Image(systemName: "engine.combustion").font(.system(size: 32, weight: .ultraLight))
                            Text("ENGINE READY").font(.system(size: 10, weight: .black)).kerning(2)
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
                .frame(height: 80).padding(.bottom, 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
        .artisanShadow()
    }
    
    private var artisanPlaybackControl: some View {
        HStack(spacing: 20) {
            artisanCircleControl(
                icon: viewModel.isWallpaperActive ? (viewModel.isPaused ? "play.fill" : "pause.fill") : "power",
                isPrimary: true
            ) {
                withAnimation(.gallerySpring) { viewModel.toggleWallpaper() }
            }
            
            artisanCircleControl(icon: "forward.fill", isPrimary: false) { }
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
                Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)
        }.buttonStyle(.plain)
    }
    
    private var artisanResourceStats: some View {
        HStack(spacing: 12) {
            artisanStatMini(label: "RENDER", value: "\(Int(viewModel.fps))", unit: "FPS", color: LiquidGlassColors.onlineGreen)
            artisanStatMini(label: "MEMORY", value: "1.2", unit: "GB", color: LiquidGlassColors.accentGold)
            artisanStatMini(label: "LOAD", value: "\(Int(viewModel.gpuUsage))", unit: "%", color: LiquidGlassColors.primaryViolet)
        }
    }
    
    private func artisanStatMini(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 9, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(LiquidGlassColors.textPrimary)
                Text(unit).font(.system(size: 8, weight: .black)).foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).galleryCardStyle(radius: 16, padding: 0)
    }
    
    private var artisanQuickNav: some View {
        VStack(spacing: 10) {
            artisanNavRow(title: "管理壁纸库", icon: "archivebox.fill") { viewModel.openMainWindow() }
            artisanNavRow(title: "实验室后期", icon: "sparkles") { }
        }
    }
    
    private func artisanNavRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(LiquidGlassColors.primaryPink)
                Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            .padding(.horizontal, 16).frame(height: 48)
            .galleryCardStyle(radius: 12, padding: 0)
        }.buttonStyle(.plain)
    }
    
    private var artisanFooterSection: some View {
        HStack {
            Button("反馈建议") { }
                .font(.system(size: 11, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            Spacer()
            Button { viewModel.quit() } label: {
                Text("退出工作室")
                    .font(.system(size: 10, weight: .black)).kerning(1)
                    .foregroundStyle(LiquidGlassColors.errorRed)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .galleryCardStyle(radius: 8, padding: 0)
            }.buttonStyle(.plain)
        }
        .padding(20).background(Color.black.opacity(0.15))
    }
    
    // MARK: - 逻辑对齐
    
    private func updateLiveStats() {
        if !viewModel.isPaused && viewModel.isWallpaperActive {
            let newVal = Double.random(in: 57...60)
            fpsHistory.removeFirst()
            fpsHistory.append(PerformancePoint(index: (fpsHistory.last?.index ?? 0) + 1, value: newVal))
            viewModel.fps = newVal
            viewModel.gpuUsage = Double.random(in: 8...15)
        } else {
            viewModel.fps = 0
            viewModel.gpuUsage = 0
        }
    }
}

// 辅助结构体 (MenuBar 专属)
private struct PerformancePoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}
