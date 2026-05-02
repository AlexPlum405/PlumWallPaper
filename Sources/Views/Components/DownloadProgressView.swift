// Sources/Views/Components/DownloadProgressView.swift
import SwiftUI

/// 下载进度显示
struct DownloadProgressView: View {
    let task: DownloadTask

    var body: some View {
        HStack(spacing: 16) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: task.progress)
                    .stroke(
                        LiquidGlassColors.primaryPink,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: task.progress)

                if task.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                } else if task.status == .failed {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.red)
                } else {
                    Text("\(Int(task.progress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(task.quality.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.primaryPink)

                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))

                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LiquidGlassColors.deepBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
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
        VStack(alignment: .trailing, spacing: 12) {
            ForEach(Array(downloadManager.activeDownloads.values), id: \.id) { task in
                DownloadProgressView(task: task)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: downloadManager.activeDownloads.count)
    }
}
