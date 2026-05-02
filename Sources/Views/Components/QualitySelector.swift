// Sources/Views/Components/QualitySelector.swift
import SwiftUI

/// 下载质量选择器
struct QualitySelector: View {
    let downloadOptions: [MediaDownloadOption]
    @Binding var selectedQuality: MediaDownloadOption?
    let onDownload: () -> Void
    let onCancel: () -> Void

    @State private var hoveredOption: String?

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("选择下载质量")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .background(Color.white.opacity(0.1))

            // 质量选项列表
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(sortedOptions, id: \.id) { option in
                        qualityOptionRow(option)
                    }
                }
                .padding(24)
            }
            .frame(maxHeight: 400)

            Divider()
                .background(Color.white.opacity(0.1))

            // 底部按钮
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                Button(action: onDownload) {
                    Text("下载并应用")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedQuality != nil
                                        ? LiquidGlassColors.primaryPink
                                        : Color.white.opacity(0.2)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedQuality == nil)
            }
            .padding(24)
        }
        .frame(width: 480)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LiquidGlassColors.deepBackground)
                .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
        )
    }

    private var sortedOptions: [MediaDownloadOption] {
        downloadOptions.sorted { $0.qualityRank > $1.qualityRank }
    }

    private func qualityOptionRow(_ option: MediaDownloadOption) -> some View {
        Button(action: {
            selectedQuality = option
        }) {
            HStack(spacing: 16) {
                // 选择指示器
                ZStack {
                    Circle()
                        .stroke(
                            selectedQuality?.id == option.id
                                ? LiquidGlassColors.primaryPink
                                : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)

                    if selectedQuality?.id == option.id {
                        Circle()
                            .fill(LiquidGlassColors.primaryPink)
                            .frame(width: 10, height: 10)
                    }
                }

                // 质量信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(option.label)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)

                        if option.qualityRank == sortedOptions.first?.qualityRank {
                            Text("推荐")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(LiquidGlassColors.primaryPink.opacity(0.2))
                                )
                        }
                    }

                    HStack(spacing: 12) {
                        Text(option.resolutionText)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("•")
                            .foregroundStyle(.white.opacity(0.3))

                        Text(option.fileSizeText)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // 质量标签
                qualityBadge(for: option)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        selectedQuality?.id == option.id
                            ? LiquidGlassColors.primaryPink.opacity(0.15)
                            : (hoveredOption == option.id
                                ? Color.white.opacity(0.05)
                                : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedQuality?.id == option.id
                                    ? LiquidGlassColors.primaryPink.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            hoveredOption = isHovered ? option.id : nil
        }
    }

    private func qualityBadge(for option: MediaDownloadOption) -> some View {
        let color: Color
        if option.label.uppercased().contains("8K") {
            color = .purple
        } else if option.label.uppercased().contains("4K") {
            color = .blue
        } else if option.label.uppercased().contains("HD") {
            color = .green
        } else {
            color = .orange
        }

        return Text(option.label.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
    }
}
