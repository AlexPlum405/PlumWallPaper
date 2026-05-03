// Sources/Views/Components/DownloadProgressView.swift
import SwiftUI

/// 下载进度显示
struct DownloadProgressView: View {
    let task: DownloadTask

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                statusIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(task.quality.uppercased())
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(LiquidGlassColors.primaryPink)

                        Text(statusText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }

                Spacer()

                Text("\(Int((task.progress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 42, alignment: .trailing)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))

                    Capsule()
                        .fill(progressGradient)
                        .frame(width: max(8, proxy.size.width * task.progress))
                        .shadow(color: LiquidGlassColors.primaryPink.opacity(task.status == .failed ? 0 : 0.35), radius: 8)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LiquidGlassColors.deepBackground.opacity(0.88))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.32), radius: 22, y: 10)
        )
    }

    private var statusIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 38, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )

            switch task.status {
            case .completed:
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(LiquidGlassColors.onlineGreen)
            case .failed:
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.red)
            case .waiting:
                Image(systemName: "clock")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            case .downloading:
                Image(systemName: "arrow.down")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
            }
        }
    }

    private var progressGradient: LinearGradient {
        let colors: [Color] = task.status == .failed
            ? [.red.opacity(0.85), .red.opacity(0.55)]
            : [LiquidGlassColors.primaryPink, LiquidGlassColors.accentGold]
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private var statusText: String {
        switch task.status {
        case .waiting:
            return "等待中..."
        case .downloading:
            return "下载中..."
        case .completed:
            return "已完成"
        case .failed:
            return task.error ?? "下载失败"
        }
    }
}

/// 下载进度浮窗
struct DownloadProgressOverlay: View {
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(downloadManager.activeDownloads.values.sorted(by: { $0.createdAt < $1.createdAt }), id: \.id) { task in
                DownloadProgressView(task: task)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: downloadManager.activeDownloads.count)
        .allowsHitTesting(false)
    }
}
