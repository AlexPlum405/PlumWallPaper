import SwiftUI
import AppKit
import Charts // 用于性能图表

struct MenuBarView: View {
    @State private var viewModel = MenuBarViewModel()
    @State private var isHovered = false
    
    // 模拟实时数据流用于展示“最强性能”视觉
    @State private var fpsHistory: [PerformancePoint] = (0..<20).map { PerformancePoint(index: $0, value: Double.random(in: 58...60)) }
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    private let panelWidth: CGFloat = 340
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部：品牌与快速开关
            headerSection
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // 2. 核心：当前动态内容监控器 (带实时波形)
                    liveMonitorSection
                    
                    // 3. 播放控制：液态按钮组
                    playbackControlSection
                    
                    // 4. 资源调度状态：GPU & MEM
                    resourceStatsSection
                    
                    // 5. 快速导航
                    quickNavSection
                }
                .padding(20)
            }
            
            // 6. 底部：系统级操作
            footerSection
        }
        .frame(width: panelWidth)
        .background {
            ZStack {
                LiquidGlassBackgroundView(material: .hudWindow, blendingMode: .withinWindow)
                
                // 动态呼吸光晕：根据壁纸状态改变颜色
                Circle()
                    .fill(viewModel.isPaused ? Color.orange.opacity(0.12) : LiquidGlassColors.primaryPink.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 100, y: -150)
            }
            .ignoresSafeArea()
        }
        .onReceive(timer) { _ in
            updateLiveStats()
        }
    }
    
    // MARK: - Header (品牌感知)
    private var headerSection: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: LiquidGlassColors.primaryPink.opacity(0.4), radius: 8)
                
                Text("PLUM")
                    .font(.system(size: 14, weight: .black))
                    .kerning(2)
            }
            
            Spacer()
            
            // 状态指示器
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isPaused ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)
                
                Text(viewModel.isPaused ? "已暂停渲染" : "渲染中")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(viewModel.isPaused ? .orange : .green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(viewModel.isPaused ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - 实时监控区 (最核心视觉)
    private var liveMonitorSection: some View {
        VStack(spacing: 16) {
            // 壁纸预览卡片
            ZStack(alignment: .bottomLeading) {
                if viewModel.isWallpaperActive {
                    AsyncImage(url: URL(string: "https://mock.placeholder/wallpaper.jpg")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle().fill(Color.white.opacity(0.05))
                        case .empty:
                            Rectangle().fill(Color.white.opacity(0.03))
                                .overlay { ProgressView().tint(.white.opacity(0.3)) }
                        @unknown default:
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .frame(width: panelWidth - 40, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    // 实时 FPS 曲线图叠加
                    Chart(fpsHistory) { point in
                        AreaMark(
                            x: .value("Time", point.index),
                            y: .value("FPS", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [LiquidGlassColors.primaryPink.opacity(0.5), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Time", point.index),
                            y: .value("FPS", point.value)
                        )
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: 30...65)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 60)
                    .padding(.bottom, 10)
                } else {
                    emptyEnginePlaceholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
    }
    
    private var emptyEnginePlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "engine.combustion")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            
            Text("引擎未启动")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(LiquidGlassColors.textTertiary)
        }
        .frame(width: panelWidth - 40, height: 180)
        .background(Color.white.opacity(0.03))
    }
    
    // MARK: - 播放控制 (液态交互)
    private var playbackControlSection: some View {
        HStack(spacing: 15) {
            playButton(
                icon: viewModel.isWallpaperActive ? (viewModel.isPaused ? "play.fill" : "pause.fill") : "power",
                label: viewModel.isWallpaperActive ? (viewModel.isPaused ? "继续" : "暂停") : "启动",
                isPrimary: true
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    viewModel.toggleWallpaper()
                }
            }
            
            playButton(icon: "forward.fill", label: "下一张", isPrimary: false) {
                // TODO: Next
            }
            
            playButton(icon: "gearshape.fill", label: "偏好", isPrimary: false) {
                viewModel.openMainWindow()
            }
        }
    }
    
    private func playButton(icon: String, label: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    if isPrimary {
                        Circle()
                            .fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: LiquidGlassColors.primaryPink.opacity(0.4), radius: 12, y: 4)
                    } else {
                        Circle()
                            .fill(.white.opacity(0.06))
                            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.05 : 1.0)
    }
    
    // MARK: - 性能看板
    private var resourceStatsSection: some View {
        HStack(spacing: 12) {
            resourceCard(label: "帧率", value: "\(Int(viewModel.fps))", unit: "FPS", color: LiquidGlassColors.onlineGreen)
            resourceCard(label: "显存", value: "1.2", unit: "GB", color: LiquidGlassColors.accentCyan)
            resourceCard(label: "负载", value: "\(Int(viewModel.gpuUsage))", unit: "%", color: LiquidGlassColors.secondaryViolet)
        }
    }
    
    private func resourceCard(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(LiquidGlassColors.textPrimary)
                Text(unit)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.05), lineWidth: 1))
    }
    
    // MARK: - 快速导航
    private var quickNavSection: some View {
        VStack(spacing: 8) {
            LiquidGlassNavButton(title: "管理壁纸库", icon: "square.grid.2x2.fill", isSelected: false) {
                viewModel.openMainWindow()
            }
            
            LiquidGlassNavButton(title: "性能调节", icon: "bolt.fill", isSelected: false) {
                // TODO: Open Performance Settings
            }
        }
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            Button("反馈问题") { }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textTertiary)
            
            Spacer()
            
            Button {
                viewModel.quit()
            } label: {
                Text("退出 PLUM")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().stroke(.red.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.black.opacity(0.2))
    }
    
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

// 辅助结构体
struct PerformancePoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

#Preview {
    MenuBarView()
}
