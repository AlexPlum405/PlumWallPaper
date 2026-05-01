import SwiftUI

struct PreviewView: View {
    let wallpaper: Wallpaper
    let onClose: () -> Void
    @State private var isVisible = false
    @State private var isHoveringPrev = false
    @State private var isHoveringNext = false

    var body: some View {
        ZStack {
            // 1. 全屏背景
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            HStack(spacing: 20) {
                // 上一张按钮 (极简)
                artisanNavButton(icon: "chevron.left", isHovered: isHoveringPrev) {
                    isHoveringPrev = $0
                } action: {
                    // Previous logic
                }

                Spacer()

                VStack(spacing: 40) {
                    // 2. 主图预览 (移除占位图，换回 AsyncImage)
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

                        Button(action: onClose) {
                            HStack(spacing: 12) {
                                Image(systemName: "desktopcomputer").font(.system(size: 16, weight: .bold))
                                Text("设为壁纸").font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .frame(height: 56)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink))
                        }.buttonStyle(.plain)

                        Button(action: { }) {
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
                artisanNavButton(icon: "chevron.right", isHovered: isHoveringNext) {
                    isHoveringNext = $0
                } action: {
                    // Next logic
                }
            }
            .padding(.horizontal, 30)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.3)) { isVisible = true } }
    }

    private func artisanNavButton(icon: String, isHovered: Bool, onHover: @escaping (Bool) -> Void, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Rectangle().fill(Color.white.opacity(0.001)).frame(width: 80, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(isHovered ? .white : .white.opacity(0.3))
                    .scaleEffect(isHovered ? 1.1 : 1.0)
            }
            .onHover(perform: onHover)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }.buttonStyle(.plain)
    }
}
