import SwiftUI
import SwiftData

struct ColorAdjustView: View {
    let wallpaper: Wallpaper?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var exposure: Double = 100
    @State private var contrast: Double = 100
    @State private var saturation: Double = 100
    @State private var hue: Double = 0
    @State private var blur: Double = 0
    @State private var grain: Double = 0
    @State private var vignette: Double = 0

    init(wallpaper: Wallpaper? = nil) {
        self.wallpaper = wallpaper
        if let preset = wallpaper?.filterPreset {
            _exposure = State(initialValue: preset.exposure)
            _contrast = State(initialValue: preset.contrast)
            _saturation = State(initialValue: preset.saturation)
            _hue = State(initialValue: preset.hue)
            _blur = State(initialValue: preset.blur)
            _grain = State(initialValue: preset.grain)
            _vignette = State(initialValue: preset.vignette)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.black.ignoresSafeArea()
                if let wallpaper,
                   let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                   let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: blur / 2)
                        .brightness((exposure - 100) / 200)
                        .contrast(contrast / 100)
                        .saturation(saturation / 100)
                        .hueRotation(.degrees(hue))
                } else {
                    Color.white.opacity(0.02)
                }

                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(32)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 40) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("色彩调节")
                        .font(Theme.Fonts.display(size: 24))
                        .italic()
                    Text(wallpaper?.name ?? "未选择壁纸")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        AdjustGroup(label: "基础校正") {
                            AdjustRow(label: "曝光度", value: $exposure, range: 0...200)
                            AdjustRow(label: "对比度", value: $contrast, range: 0...200)
                            AdjustRow(label: "饱和度", value: $saturation, range: 0...200)
                            AdjustRow(label: "色调", value: $hue, range: -180...180)
                        }

                        AdjustGroup(label: "特效") {
                            AdjustRow(label: "模糊", value: $blur, range: 0...20)
                            AdjustRow(label: "颗粒感", value: $grain, range: 0...100)
                            AdjustRow(label: "暗角", value: $vignette, range: 0...100)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button(action: resetToDefault) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.glassHeavy)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: applyFilter) {
                        Label("应用修改", systemImage: "check")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 360)
            .padding(32)
            .background(Color(red: 17/255, green: 18/255, blue: 22/255))
            .border(width: 1, edges: [.leading], color: Theme.border)
        }
    }

    func applyFilter() {
        guard let wallpaper else {
            dismiss()
            return
        }
        let preset = wallpaper.filterPreset ?? FilterPreset(name: "Custom")
        preset.exposure = exposure
        preset.contrast = contrast
        preset.saturation = saturation
        preset.hue = hue
        preset.blur = blur
        preset.grain = grain
        preset.vignette = vignette
        wallpaper.filterPreset = preset
        try? modelContext.save()
        // TODO: 调用后端 FilterEngine.shared.applyFilter(preset, to: wallpaper)
        dismiss()
    }

    func resetToDefault() {
        withAnimation {
            exposure = 100
            contrast = 100
            saturation = 100
            hue = 0
            blur = 0
            grain = 0
            vignette = 0
        }
    }
}

struct AdjustGroup<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(label)
                .font(.system(size: 11, weight: .black))
                .tracking(2)
                .foregroundColor(.white.opacity(0.2))
            VStack(spacing: 24) { content }
        }
    }
}

struct AdjustRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accent)
            }
            Slider(value: $value, in: range)
                .accentColor(Theme.accent)
        }
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            switch edge {
            case .top:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom:
                path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing:
                path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }
        return path
    }
}
