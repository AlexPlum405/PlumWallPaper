// Sources/Engine/DesktopWindow.swift
import AppKit
import AVFoundation

final class DesktopWindow: NSWindow {
    private(set) var playerLayer: AVPlayerLayer!
    private let imageLayer = CALayer()
    private let environmentLayer = CALayer()
    private let flashLayer = CALayer()
    let player: AVPlayer

    init(screen: NSScreen) {
        self.player = AVPlayer()
        self.playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.setFrame(screen.frame, display: true)

        // 设置为真正的桌面级窗口，防止 macOS Sonoma 缩放
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.backgroundColor = .black
        self.isReleasedWhenClosed = false

        let screenBounds = NSRect(origin: .zero, size: screen.frame.size)
        let scale = screen.backingScaleFactor
        let view = NSView(frame: screenBounds)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.masksToBounds = true
        view.layer?.contentsScale = scale
        playerLayer.frame = screenBounds
        playerLayer.contentsScale = scale
        playerLayer.contentsGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        imageLayer.frame = screenBounds
        imageLayer.contentsScale = scale
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        imageLayer.isHidden = true
        environmentLayer.frame = screenBounds
        environmentLayer.contentsScale = scale
        environmentLayer.masksToBounds = true
        environmentLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        flashLayer.frame = screenBounds
        flashLayer.contentsScale = scale
        flashLayer.backgroundColor = NSColor.white.cgColor
        flashLayer.opacity = 0
        flashLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.addSublayer(playerLayer)
        view.layer?.addSublayer(imageLayer)
        view.layer?.addSublayer(environmentLayer)
        view.layer?.addSublayer(flashLayer)
        self.contentView = view

        NSLog("[DesktopWindow] init screen=\(screen.localizedName) frame=\(screen.frame) scale=\(scale) level=\(self.level.rawValue)")
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        self.player = AVPlayer()
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        commonInit()
    }

    private func commonInit() {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.backgroundColor = .black
        self.isReleasedWhenClosed = false
    }

    func displayVideo() {
        imageLayer.contents = nil
        imageLayer.isHidden = true
        playerLayer.player = player
        playerLayer.isHidden = false
    }

    func displayImage(url: URL) throws {
        guard let image = NSImage(contentsOf: url) else {
            throw DesktopWindowError.imageLoadFailed(url.path)
        }
        player.pause()
        player.replaceCurrentItem(with: nil)
        imageLayer.contents = image
        imageLayer.isHidden = false
        playerLayer.isHidden = true
    }

    func configureEnvironment(effects: WallpaperRenderEffects?) {
        environmentLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        flashLayer.removeAllAnimations()
        flashLayer.opacity = 0

        guard let effects, effects.hasDynamicEnvironment else { return }
        layoutRenderLayers()

        if effects.particleRate > 0.1 {
            addAmbientParticleEmitters(effects)
        }
        if effects.weatherRain > 0.1 {
            addRainEmitter(effects)
        }
        if effects.weatherSnow > 0.1 {
            addSnowEmitter(effects)
        }
        if effects.weatherThunder > 0.1 {
            addLightningFlash(effects)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show() {
        orderBack(nil)
        layoutRenderLayers()
    }

    func hide() {
        orderOut(nil)
    }

    private func layoutRenderLayers() {
        guard let contentView else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let bounds = contentView.bounds
        playerLayer.frame = bounds
        imageLayer.frame = bounds
        environmentLayer.frame = bounds
        flashLayer.frame = bounds
        environmentLayer.sublayers?.forEach { $0.frame = bounds }
        if let window = contentView.window {
            let scale = window.backingScaleFactor
            contentView.layer?.contentsScale = scale
            playerLayer.contentsScale = scale
            imageLayer.contentsScale = scale
            environmentLayer.contentsScale = scale
            flashLayer.contentsScale = scale
        }
        CATransaction.commit()
    }

    private func addAmbientParticleEmitters(_ effects: WallpaperRenderEffects) {
        let bounds = environmentLayer.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let material = ParticleMaterial(style: effects.particleStyle)
        let sprites = DesktopParticleSprite.images(for: material)
        let baseRate = min(max(effects.particleRate, 0), 220) * material.desktopDensityMultiplier
        let color = DesktopParticleSprite.color(for: material)
        let previewFootprint = max(
            1,
            effects.particleSize * material.previewSizeMultiplier * material.previewFootprintMultiplier
        )
        let baseScale = CGFloat(max(0.04, min(3.0, previewFootprint / material.desktopSpriteReferenceSize)))
        let previewGravityAcceleration = effects.particleGravity * 100
        let previewVelocity = 22 + effects.particleTurbulence * 20 + effects.particleThrust * 10

        for layerIndex in 0..<3 {
            let emitter = CAEmitterLayer()
            emitter.name = "lab-particles-\(layerIndex)"
            emitter.frame = bounds
            emitter.emitterShape = .rectangle
            emitter.emitterMode = .surface
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
            emitter.emitterSize = bounds.size
            emitter.renderMode = material.desktopIsGlow ? .additive : .unordered
            emitter.masksToBounds = true

            let cells = sprites.enumerated().map { variantIndex, sprite -> CAEmitterCell in
                let cell = CAEmitterCell()
                cell.name = "lab-particle-cell-\(layerIndex)-\(variantIndex)"
                cell.contents = sprite
                cell.birthRate = Float(baseRate * [0.18, 0.12, 0.045][layerIndex] / Double(max(1, sprites.count)))
                cell.lifetime = Float(max(2, effects.particleLifetime * [1.8, 1.2, 0.8][layerIndex] * material.desktopLifetimeMultiplier))
                cell.lifetimeRange = cell.lifetime * 0.35
                cell.velocity = CGFloat(previewVelocity * [0.36, 0.58, 0.82][layerIndex] * material.desktopVelocityMultiplier)
                cell.velocityRange = CGFloat(previewVelocity * [0.32, 0.45, 0.6][layerIndex] * material.desktopVelocityMultiplier)
                cell.xAcceleration = CGFloat(effects.weatherWind * 10 * [0.72, 1.0, 1.26][layerIndex] * material.desktopWindMultiplier)
                cell.yAcceleration = CGFloat(max(-900, min(1400, previewGravityAcceleration * [0.45, 0.75, 1.05][layerIndex] * material.desktopGravityMultiplier)))
                cell.emissionLongitude = .pi / 2
                cell.emissionRange = CGFloat(max(0.35, min(Double.pi, effects.particleSpread * .pi / 180)))
                cell.scale = baseScale * [0.58, 1.0, 1.48][layerIndex]
                cell.scaleRange = cell.scale * material.desktopScaleRange
                cell.alphaRange = 0.18
                cell.alphaSpeed = -Float(max(0.04, 1 / max(effects.particleLifetime * material.desktopLifetimeMultiplier, 1.4)))
                cell.spin = CGFloat(effects.particleSpin * 0.14 + Double(layerIndex) * 0.2 + Double(variantIndex) * 0.05)
                cell.spinRange = CGFloat(material.desktopSpinRange + effects.particleTurbulence * 0.08)
                cell.color = color.withAlphaComponent([0.24, 0.34, 0.45][layerIndex] * material.desktopAlphaMultiplier).cgColor
                cell.redRange = material.desktopColorRange
                cell.greenRange = material.desktopColorRange
                cell.blueRange = material.desktopColorRange
                return cell
            }

            emitter.emitterCells = cells
            emitter.opacity = Float([0.55, 0.72, 0.9][layerIndex])
            environmentLayer.addSublayer(emitter)
        }
    }

    private func addRainEmitter(_ effects: WallpaperRenderEffects) {
        let bounds = environmentLayer.bounds
        guard bounds.width > 0 else { return }

        let emitter = CAEmitterLayer()
        emitter.name = "lab-rain"
        emitter.frame = bounds
        emitter.emitterShape = .line
        emitter.emitterMode = .surface
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -24)
        emitter.emitterSize = CGSize(width: bounds.width * 1.25, height: 1)
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.contents = DesktopParticleSprite.rain.first?.cgImage ?? CGImage.emptyParticleImage
        cell.birthRate = Float(min(360, max(12, effects.weatherRain * 2.8)))
        cell.lifetime = 2.4
        cell.lifetimeRange = 0.7
        cell.velocity = 620
        cell.velocityRange = 180
        cell.xAcceleration = CGFloat(effects.weatherWind * 26)
        cell.yAcceleration = 280
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 0.18
        cell.scale = 0.72
        cell.scaleRange = 0.24
        cell.alphaSpeed = -0.22
        cell.color = NSColor(calibratedRed: 0.72, green: 0.86, blue: 1.0, alpha: 0.36).cgColor
        emitter.emitterCells = [cell]

        environmentLayer.addSublayer(emitter)
    }

    private func addSnowEmitter(_ effects: WallpaperRenderEffects) {
        let bounds = environmentLayer.bounds
        guard bounds.width > 0 else { return }

        let emitter = CAEmitterLayer()
        emitter.name = "lab-snow"
        emitter.frame = bounds
        emitter.emitterShape = .line
        emitter.emitterMode = .surface
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -18)
        emitter.emitterSize = CGSize(width: bounds.width * 1.2, height: 1)
        emitter.renderMode = .unordered

        let cell = CAEmitterCell()
        cell.contents = DesktopParticleSprite.softCircle.cgImage
        cell.birthRate = Float(min(240, max(10, effects.weatherSnow * 2.1)))
        cell.lifetime = 9.0
        cell.lifetimeRange = 4.0
        cell.velocity = 52
        cell.velocityRange = 38
        cell.xAcceleration = CGFloat(effects.weatherWind * 8)
        cell.yAcceleration = 18
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 0.55
        cell.scale = 0.28
        cell.scaleRange = 0.25
        cell.alphaSpeed = -0.055
        cell.color = NSColor.white.withAlphaComponent(0.62).cgColor
        emitter.emitterCells = [cell]

        environmentLayer.addSublayer(emitter)
    }

    private func addLightningFlash(_ effects: WallpaperRenderEffects) {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0, 0, 0.16, 0, 0.08, 0]
        animation.keyTimes = [0, 0.55, 0.58, 0.61, 0.64, 0.68]
        animation.duration = max(1.8, 8.0 - effects.weatherThunder / 12)
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        flashLayer.add(animation, forKey: "lab-lightning")
    }
}

enum DesktopWindowError: LocalizedError {
    case imageLoadFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed(let path):
            return "无法载入桌面图片: \(path)"
        }
    }
}

private enum DesktopParticleSprite {
    static let softCircle = makeSoftCircle(size: 36, coreAlpha: 0.82)
    static let dust = [12, 18, 25].map { makeSoftCircle(size: CGFloat($0), coreAlpha: 0.72) }
    static let glow = [38, 52, 64].map { makeSoftCircle(size: CGFloat($0), coreAlpha: 0.9) }
    static let bokeh = [58, 74, 92].map { makeBokeh(size: CGFloat($0)) }
    static let petal = [
        makePetal(width: 52, height: 28, pinch: 0.22),
        makePetal(width: 42, height: 24, pinch: 0.35),
        makePetal(width: 62, height: 30, pinch: 0.16),
        makePetal(width: 48, height: 22, pinch: 0.42)
    ]
    static let shard = [
        makeShard(width: 34, height: 7),
        makeShard(width: 22, height: 5),
        makeShard(width: 46, height: 8)
    ]
    static let ember = [
        makeEmber(width: 28, height: 14),
        makeEmber(width: 18, height: 10),
        makeEmber(width: 36, height: 16)
    ]
    static let snow = [
        makeSoftCircle(size: 20, coreAlpha: 0.9),
        makeSoftCircle(size: 28, coreAlpha: 0.74),
        makeSnowCluster(size: 34)
    ]
    static let rain = [
        makeRainStreak(width: 5, height: 66),
        makeRainStreak(width: 4, height: 52),
        makeRainStreak(width: 7, height: 86)
    ]
    static let mist = [
        makeMistBlob(width: 100, height: 58),
        makeMistBlob(width: 84, height: 46),
        makeMistBlob(width: 132, height: 66)
    ]
    static let firefly = [
        makeFirefly(size: 34),
        makeFirefly(size: 46),
        makeFirefly(size: 28)
    ]

    static func images(for material: ParticleMaterial) -> [CGImage] {
        let images: [NSImage]
        switch material {
        case .dust:
            images = dust
        case .glow:
            images = glow
        case .bokeh:
            images = bokeh
        case .petal:
            images = petal
        case .shard:
            images = shard
        case .ember:
            images = ember
        case .snow:
            images = snow
        case .rain:
            images = rain
        case .mist:
            images = mist
        case .firefly:
            images = firefly
        }
        return images.map(\.cgImage)
    }

    static func color(for material: ParticleMaterial) -> NSColor {
        switch material {
        case .petal:
            return NSColor(calibratedRed: 1.0, green: 0.32, blue: 0.68, alpha: 1)
        case .rain:
            return NSColor(calibratedRed: 0.58, green: 0.82, blue: 1.0, alpha: 1)
        case .snow:
            return .white
        case .shard:
            return NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.62, alpha: 1)
        case .ember:
            return NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.18, alpha: 1)
        case .glow, .firefly:
            return NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.66, alpha: 1)
        case .bokeh:
            return NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.88, alpha: 1)
        case .mist:
            return NSColor(calibratedRed: 0.9, green: 0.92, blue: 0.94, alpha: 1)
        case .dust:
            return NSColor(calibratedRed: 0.96, green: 0.92, blue: 0.82, alpha: 1)
        }
    }

    private static func makeSoftCircle(size: CGFloat, coreAlpha: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let gradient = NSGradient(colors: [
            .white.withAlphaComponent(coreAlpha),
            .white.withAlphaComponent(coreAlpha * 0.22),
            .white.withAlphaComponent(0.0)
        ])
        gradient?.draw(in: NSBezierPath(ovalIn: rect), relativeCenterPosition: .zero)

        return image
    }

    private static func makeBokeh(size: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(x: 2, y: 2, width: size - 4, height: size - 4)
        let gradient = NSGradient(colors: [
            .white.withAlphaComponent(0.14),
            .white.withAlphaComponent(0.08),
            .white.withAlphaComponent(0.0)
        ])
        gradient?.draw(in: NSBezierPath(ovalIn: rect), relativeCenterPosition: .zero)
        NSColor.white.withAlphaComponent(0.18).setStroke()
        let ring = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.18, dy: size * 0.18))
        ring.lineWidth = max(1, size * 0.025)
        ring.stroke()

        return image
    }

    private static func makePetal(width: CGFloat, height: CGFloat, pinch: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }

        let path = NSBezierPath()
        path.move(to: CGPoint(x: width * 0.08, y: height * 0.5))
        path.curve(
            to: CGPoint(x: width * 0.76, y: height * 0.86),
            controlPoint1: CGPoint(x: width * (0.12 + pinch), y: height * 0.06),
            controlPoint2: CGPoint(x: width * 0.56, y: height * 0.05)
        )
        path.curve(
            to: CGPoint(x: width * 0.96, y: height * 0.48),
            controlPoint1: CGPoint(x: width * 0.9, y: height * 0.92),
            controlPoint2: CGPoint(x: width * 1.02, y: height * 0.68)
        )
        path.curve(
            to: CGPoint(x: width * 0.08, y: height * 0.5),
            controlPoint1: CGPoint(x: width * 0.72, y: height * 0.26),
            controlPoint2: CGPoint(x: width * 0.32, y: height * 0.76)
        )
        path.close()
        NSColor.white.setFill()
        path.fill()

        return image
    }

    private static func makeShard(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(x: 1, y: height * 0.28, width: width - 2, height: height * 0.44)
        NSColor.white.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: rect, xRadius: height * 0.22, yRadius: height * 0.22).fill()

        return image
    }

    private static func makeEmber(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let gradient = NSGradient(colors: [
            .white.withAlphaComponent(0.92),
            .white.withAlphaComponent(0.28),
            .white.withAlphaComponent(0.0)
        ])
        gradient?.draw(in: NSBezierPath(ovalIn: rect), relativeCenterPosition: .zero)

        return image
    }

    private static func makeSnowCluster(size: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.white.withAlphaComponent(0.78).setFill()
        NSBezierPath(ovalIn: CGRect(x: size * 0.2, y: size * 0.24, width: size * 0.44, height: size * 0.44)).fill()
        NSColor.white.withAlphaComponent(0.42).setFill()
        NSBezierPath(ovalIn: CGRect(x: size * 0.52, y: size * 0.5, width: size * 0.22, height: size * 0.22)).fill()
        NSBezierPath(ovalIn: CGRect(x: size * 0.35, y: size * 0.62, width: size * 0.18, height: size * 0.18)).fill()

        return image
    }

    private static func makeRainStreak(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }

        let path = NSBezierPath()
        path.move(to: CGPoint(x: width * 0.72, y: 2))
        path.line(to: CGPoint(x: width * 0.28, y: height - 2))
        path.lineWidth = max(1, width * 0.32)
        NSColor.white.withAlphaComponent(0.86).setStroke()
        path.stroke()

        return image
    }

    private static func makeMistBlob(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }

        for i in 0..<4 {
            let x = CGFloat(i) * width * 0.18
            let y = height * (0.18 + CGFloat(i % 2) * 0.12)
            let rect = CGRect(x: x, y: y, width: width * 0.5, height: height * 0.52)
            let gradient = NSGradient(colors: [
                .white.withAlphaComponent(0.22),
                .white.withAlphaComponent(0.04),
                .white.withAlphaComponent(0.0)
            ])
            gradient?.draw(in: NSBezierPath(ovalIn: rect), relativeCenterPosition: .zero)
        }

        return image
    }

    private static func makeFirefly(size: CGFloat) -> NSImage {
        let image = NSImage(size: CGSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let gradient = NSGradient(colors: [
            .white.withAlphaComponent(0.96),
            .white.withAlphaComponent(0.32),
            .white.withAlphaComponent(0.0)
        ])
        gradient?.draw(in: NSBezierPath(ovalIn: rect), relativeCenterPosition: .zero)
        NSColor.white.setFill()
        let core = size * 0.16
        NSBezierPath(ovalIn: CGRect(x: size * 0.5 - core / 2, y: size * 0.5 - core / 2, width: core, height: core)).fill()

        return image
    }
}

private extension ParticleMaterial {
    var desktopIsGlow: Bool {
        switch self {
        case .glow, .bokeh, .shard, .ember, .rain, .firefly:
            return true
        case .dust, .petal, .snow, .mist:
            return false
        }
    }

    var desktopColorRange: Float {
        switch self {
        case .petal: return 0.12
        case .glow, .bokeh, .shard, .ember, .rain, .firefly: return 0.22
        case .snow, .mist, .dust: return 0.08
        }
    }

    var desktopDensityMultiplier: Double {
        switch self {
        case .bokeh, .mist: return 0.32
        case .petal, .ember, .firefly: return 0.62
        case .rain: return 1.35
        default: return 1.0
        }
    }

    var desktopScaleRange: CGFloat {
        switch self {
        case .bokeh, .mist: return 0.35
        case .petal, .shard, .ember: return 0.52
        default: return 0.45
        }
    }

    var desktopVelocityMultiplier: Double {
        switch self {
        case .rain: return 2.4
        case .mist, .bokeh: return 0.45
        case .petal: return 0.8
        case .ember, .shard: return 1.25
        default: return 1.0
        }
    }

    var desktopWindMultiplier: Double {
        switch self {
        case .mist, .bokeh: return 0.35
        case .petal, .snow, .rain: return 1.25
        default: return 1.0
        }
    }

    var desktopGravityMultiplier: Double {
        switch self {
        case .mist, .bokeh, .firefly: return 0.18
        case .rain: return 2.1
        case .petal: return 0.68
        case .ember: return -0.35
        case .shard: return 0.55
        default: return 1.0
        }
    }

    var desktopLifetimeMultiplier: Double {
        switch self {
        case .mist, .bokeh: return 1.8
        case .firefly: return 1.4
        case .rain, .ember, .shard: return 0.78
        default: return 1.0
        }
    }

    var desktopSpinRange: Double {
        switch self {
        case .petal: return 2.4
        case .shard, .ember: return 1.8
        case .rain, .mist, .bokeh: return 0.35
        default: return 1.1
        }
    }

    var desktopAlphaMultiplier: CGFloat {
        switch self {
        case .mist, .bokeh: return 0.58
        case .dust: return 0.7
        case .rain: return 0.82
        case .firefly: return 0.72
        default: return 1.0
        }
    }
}

private extension NSImage {
    var cgImage: CGImage {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil) ?? CGImage.emptyParticleImage
    }
}

private extension CGImage {
    static var emptyParticleImage: CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let data = [UInt8](repeating: 255, count: 4)
        let provider = CGDataProvider(data: Data(data) as CFData)!
        return CGImage(
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }
}
