import SwiftUI
import AppKit

struct DetailPreviewCanvas: View {
    let wallpaper: Wallpaper
    let contentURL: URL?
    let posterURL: URL?
    let isStudioActive: Bool
    let exposure: Double
    let contrast: Double
    let saturation: Double
    let hue: Double
    let blur: Double
    let grain: Double
    let vignette: Double
    let grayscale: Double
    let invert: Double
    let highlights: Double
    let shadows: Double
    let weatherWind: Double
    let weatherRain: Double
    let weatherThunder: Double
    let weatherSnow: Double
    @Binding var lightningFlash: Double
    let particleStyle: String
    let particleRate: Double
    let particleLifetime: Double
    let particleSize: Double
    let particleGravity: Double
    let particleTurbulence: Double
    let particleSpin: Double
    let particleThrust: Double
    let particleAngle: Double
    let particleSpread: Double
    let particleFadeIn: Double
    let particleFadeOut: Double
    let particleColorStart: Color
    let particleColorEnd: Color

    var body: some View {
        ZStack {
            DetailBackgroundLayer(
                wallpaper: wallpaper,
                contentURL: contentURL,
                posterURL: posterURL,
                blur: blur,
                grayscale: grayscale,
                contrast: contrast,
                saturation: saturation,
                exposure: exposure,
                hue: hue,
                highlights: highlights,
                shadows: shadows,
                invert: invert,
                grain: grain,
                vignette: vignette
            )

            weatherLayers

            if isStudioActive && particleRate > 0 {
                ParticleOverlay(
                    style: particleStyle,
                    rate: particleRate,
                    lifetime: particleLifetime,
                    size: particleSize,
                    gravity: particleGravity,
                    turbulence: particleTurbulence,
                    spin: particleSpin,
                    thrust: particleThrust,
                    angle: particleAngle,
                    spread: particleSpread,
                    fadeIn: particleFadeIn,
                    fadeOut: particleFadeOut,
                    wind: weatherWind,
                    isRainMode: false,
                    colorStart: particleColorStart,
                    colorEnd: particleColorEnd
                )
                .drawingGroup()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .id("canvas-\(wallpaper.id)")
    }

    @ViewBuilder
    private var weatherLayers: some View {
        if weatherThunder > 0 {
            DetailLightningLayer(frequency: weatherThunder, flash: $lightningFlash)
        }
        if weatherSnow > 0 {
            DetailSnowLayer(intensity: weatherSnow, wind: weatherWind)
        }
        if weatherRain > 0 {
            DetailRainLayer(intensity: weatherRain, wind: weatherWind)
        }
    }
}

private struct DetailBackgroundLayer: View {
    let wallpaper: Wallpaper
    let contentURL: URL?
    let posterURL: URL?
    let blur: Double
    let grayscale: Double
    let contrast: Double
    let saturation: Double
    let exposure: Double
    let hue: Double
    let highlights: Double
    let shadows: Double
    let invert: Double
    let grain: Double
    let vignette: Double

    var body: some View {
        ZStack {
            if wallpaper.type == .video, let url = contentURL {
                DetailVideoLayerContainer(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let url = contentURL {
                DetailSimpleImage(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                DetailSimplePoster(url: posterURL)
            }

            if invert > 50 {
                Color.white.blendMode(.difference)
            }
            if grain > 0 {
                GrainTextureOverlay(opacity: grain / 100.0)
                    .blendMode(.overlay)
            }
            if vignette > 0 {
                RadialGradient(
                    colors: [.clear, .black.opacity(vignette / 100.0)],
                    center: .center,
                    startRadius: 300,
                    endRadius: 1000
                )
            }
        }
        .blur(radius: CGFloat(blur))
        .grayscale(grayscale / 100.0)
        .contrast(contrast / 100.0)
        .saturation(saturation / 100.0)
        .brightness((exposure - 100) / 100.0)
        .hueRotation(.degrees(hue))
        .colorMultiply(Color(white: highlights / 100.0))
    }
}

private struct DetailSimpleImage: View {
    let url: URL

    var body: some View {
        if url.isFileURL {
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black
            }
        } else {
            RemoteThumbnailImage(urls: [url], contentMode: .fill)
        }
    }
}

private struct DetailSimplePoster: View {
    let url: URL?

    var body: some View {
        ZStack {
            Color.black
            if let url {
                DetailSimpleImage(url: url)
                    .blur(radius: 16)
                    .opacity(0.45)
            }
        }
    }
}

private struct DetailRainLayer: View {
    let intensity: Double
    let wind: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let backgroundCount = Int(intensity * 3)
                for index in 0..<backgroundCount {
                    drawRainLine(
                        into: context,
                        seed: Double(index) * 0.7,
                        now: now,
                        size: size,
                        opacity: 0.15,
                        width: 0.5,
                        speedMultiplier: 0.8
                    )
                }

                let foregroundCount = Int(intensity * 4)
                for index in 0..<foregroundCount {
                    drawRainLine(
                        into: context,
                        seed: Double(index) * 1.3,
                        now: now,
                        size: size,
                        opacity: 0.4,
                        width: 1.2,
                        speedMultiplier: 1.2
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawRainLine(
        into context: GraphicsContext,
        seed: Double,
        now: Double,
        size: CGSize,
        opacity: Double,
        width: CGFloat,
        speedMultiplier: Double
    ) {
        let speed = (900.0 + (sin(seed * 123.4) * 300.0)) * speedMultiplier
        let lifetime: Double = 1.2
        let age = (now - seed * 0.08).truncatingRemainder(dividingBy: lifetime)
        let currentY = -150.0 + (speed * age)
        let currentX = (sin(seed * 456.7) * 0.5 + 0.5) * size.width
            + (wind * 350 * (age / lifetime))
            + (wind * 15 * age)

        guard currentY < size.height + 150 else { return }

        var path = Path()
        path.move(to: CGPoint(x: currentX, y: currentY))
        path.addLine(to: CGPoint(x: currentX + (wind * 3), y: currentY + speed * 0.045))
        context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: width)
    }
}

private struct DetailSnowLayer: View {
    let intensity: Double
    let wind: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let count = Int(intensity * 3.5)
                for index in 0..<count {
                    let seed = Double(index)
                    let depth = sin(seed * 99) * 0.5 + 0.5
                    let speed = 80.0 + depth * 120.0
                    let lifetime: Double = 15.0
                    let age = (now - seed * 0.7).truncatingRemainder(dividingBy: lifetime)
                    let startX = (sin(seed * 321.0) * 0.5 + 0.5) * size.width
                        + (wind * 80 * (age / lifetime))
                        + sin(age * (1.0 + depth) + seed) * (15.0 + depth * 30.0)
                    let currentY = -40.0 + (speed * age)

                    if currentY < size.height + 40 {
                        let rect = CGRect(
                            x: startX,
                            y: currentY,
                            width: 1.5 + depth * 3.5,
                            height: 1.5 + depth * 3.5
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.2 + depth * 0.5)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct DetailLightningLayer: View {
    let frequency: Double
    @Binding var flash: Double
    @State private var bolts: [LightningBolt] = []
    @State private var lastTriggerTime = Date()
    @State private var nextTriggerDelay: TimeInterval = 1.0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, _ in
                for bolt in bolts {
                    context.stroke(bolt.path, with: .color(.white.opacity(bolt.opacity)), lineWidth: bolt.width)
                    var glow = context
                    glow.addFilter(.blur(radius: 4))
                    glow.stroke(bolt.path, with: .color(.blue.opacity(bolt.opacity * 0.4)), lineWidth: bolt.width * 3)
                }
            }
            .onChange(of: timeline.date) { _, date in
                let size = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
                updateBolts(at: date, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    private func updateBolts(at now: Date, size: CGSize) {
        if now.timeIntervalSince(lastTriggerTime) > nextTriggerDelay,
           Double.random(in: 0...1) < frequency / 100.0 {
            let path = generateLightningPath(
                start: CGPoint(x: Double.random(in: 0...size.width), y: 0),
                size: size
            )
            bolts.append(LightningBolt(path: path, opacity: 1.0, width: CGFloat.random(in: 1...3)))
            lastTriggerTime = now
            nextTriggerDelay = Double.random(in: 0.2...max(0.5, 10.0 - frequency / 10.0))
            withAnimation(.linear(duration: 0.05)) {
                flash = Double.random(in: 0.5...0.8)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.5)) {
                    flash = 0
                }
            }
        }

        for index in bolts.indices.reversed() {
            let opacity = bolts[index].opacity - 0.15
            if opacity <= 0 {
                bolts.remove(at: index)
            } else {
                bolts[index] = LightningBolt(path: bolts[index].path, opacity: opacity, width: bolts[index].width)
            }
        }
    }

    private func generateLightningPath(start: CGPoint, size: CGSize) -> Path {
        var path = Path()
        path.move(to: start)
        var current = start
        let segments = 20
        let segmentHeight = size.height / CGFloat(segments)

        for _ in 0..<segments {
            current = CGPoint(
                x: current.x + CGFloat.random(in: -50...50),
                y: current.y + segmentHeight
            )
            path.addLine(to: current)

            if Double.random(in: 0...1) < 0.2 {
                var branch = current
                for _ in 0..<5 {
                    branch = CGPoint(
                        x: branch.x + CGFloat.random(in: -30...30),
                        y: branch.y + CGFloat.random(in: 5...20)
                    )
                    path.move(to: current)
                    path.addLine(to: branch)
                }
                path.move(to: current)
            }
        }

        return path
    }

    private struct LightningBolt: Identifiable {
        let id = UUID()
        let path: Path
        let opacity: Double
        let width: CGFloat
    }
}
