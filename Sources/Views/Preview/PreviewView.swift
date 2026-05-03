import SwiftUI
import SwiftData

struct PreviewView: View {
    let wallpaper: Wallpaper
    let onClose: () -> Void
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @State private var isVisible = false
    @State private var isHoveringPrev = false
    @State private var isHoveringNext = false
    @State private var toast: ToastConfig?
    @State private var isApplying = false

    var body: some View {
        ZStack {
            // 1. 全屏背景
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            HStack(spacing: 20) {
                // 上一张按钮 (极简)
                artisanNavButton(icon: "chevron.left", isHovered: isHoveringPrev, isEnabled: onPrevious != nil) {
                    isHoveringPrev = $0
                } action: {
                    onPrevious?()
                }

                Spacer()

                VStack(spacing: 40) {
                    // 2. 主图预览
                    ZStack {
                        if let url = URL(string: wallpaper.filePath), url.scheme != nil {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fit)
                                case .failure, .empty:
                                    Color.black.overlay(ProgressView().tint(.white))
                                @unknown default:
                                    Color.black
                                }
                            }
                        } else {
                            Image(nsImage: NSImage(contentsOfFile: wallpaper.filePath) ?? NSImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    .frame(maxWidth: 900, maxHeight: 600)
                    .background(RoundedRectangle(cornerRadius: 32).fill(Color.black))
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.4), radius: 60, x: 0, y: 30)

                    // 3. 核心操作栏
                    HStack(spacing: 25) {
                        Button(action: onClose) {
                            Image(systemName: "xmark").font(.system(size: 18, weight: .bold))
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }.buttonStyle(.plain)

                        Button {
                            Task { await setAsWallpaper() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isApplying ? "hourglass" : "desktopcomputer").font(.system(size: 16, weight: .bold))
                                Text(isApplying ? "设置中..." : "设为壁纸").font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .frame(height: 56)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink))
                        }
                        .buttonStyle(.plain)
                        .disabled(isApplying)

                        Button(action: toggleFavorite) {
                            Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }.buttonStyle(.plain)
                    }
                }

                Spacer()

                // 下一张按钮 (极简)
                artisanNavButton(icon: "chevron.right", isHovered: isHoveringNext, isEnabled: onNext != nil) {
                    isHoveringNext = $0
                } action: {
                    onNext?()
                }
            }
            .padding(.horizontal, 30)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.3)) { isVisible = true } }
        .toast($toast)
    }

    private func artisanNavButton(icon: String, isHovered: Bool, isEnabled: Bool, onHover: @escaping (Bool) -> Void, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Rectangle().fill(Color.white.opacity(0.001)).frame(width: 80, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(isEnabled ? (isHovered ? .white : .white.opacity(0.3)) : .white.opacity(0.1))
                    .scaleEffect(isHovered && isEnabled ? 1.1 : 1.0)
            }
            .onHover { onHover(isEnabled && $0) }
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func toggleFavorite() {
        wallpaper.isFavorite.toggle()
        do {
            try modelContext.save()
            toast = ToastConfig(message: wallpaper.isFavorite ? "已加入收藏" : "已取消收藏", type: .success)
            SlideshowScheduler.shared.rebuildPlaylist()
        } catch {
            wallpaper.isFavorite.toggle()
            toast = ToastConfig(message: "收藏失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func setAsWallpaper() async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }

        let url = URL(fileURLWithPath: wallpaper.filePath)
        do {
            switch wallpaper.type {
            case .video:
                try await RenderPipeline.shared.setWallpaper(url: url, wallpaperId: wallpaper.id)
            case .image, .heic:
                RenderPipeline.shared.cleanup()
                try WallpaperSetter.shared.setWallpaper(imageURL: url)
            }

            var mapping: [String: UUID] = [:]
            for screen in DisplayManager.shared.availableScreens {
                mapping[screen.id] = wallpaper.id
            }
            RestoreManager.shared.saveSession(mapping: mapping)
            SlideshowScheduler.shared.onWallpaperChanged(wallpaper.id)
            toast = ToastConfig(message: "设置成功", type: .success)
        } catch {
            toast = ToastConfig(message: "设置失败: \(error.localizedDescription)", type: .error)
        }
    }
}
