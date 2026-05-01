import SwiftUI
import AppKit
请阅读 /Users/Alex/AI/project/PlumWallPaper/_design_demos_trae/TRAE_START_HERE.md 开始工作。你需要生成 3 个差异化的 UI 设计方案，每个方案包含壁纸库和设置页的 SwiftUI Demo。另一位设计师（Gemini）也在独立完成同样的任务，最终用户会从 6 个方案中选出最喜欢的。
// Scheme A: "The Sovereign" - Hyper-Heritage Cinematic Style
// Aesthetic: Monolithic, Breathing Red, Elegant Serif, Floating HUD.

struct SovereignApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        DispatchQueue.main.async { NSApp.activate(ignoringOtherApps: true) }
    }
    var body: some Scene {
        WindowGroup {
            MainView().preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 850)
    }
}

struct MainView: View {
    @State private var selectedIndex = 0
    @State private var breathing = 0.0
    
    var body: some View {
        ZStack {
            // LAYER 0: Deep Void
            Color(hex: "0D0E12").ignoresSafeArea()
            
            // LAYER 1: Ambient Red Breathing
            RadialGradient(colors: [Color(hex: "E03E3E").opacity(0.12 * breathing), .clear], 
                           center: .topLeading, startRadius: 0, endRadius: 1000)
                .ignoresSafeArea()
            
            // LAYER 2: The Monolith Image
            GeometryReader { geo in
                AsyncImage(url: URL(string: MockData.wallpapers[selectedIndex].imageURL)) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Color.black }
                .frame(width: geo.size.width * 0.85, height: geo.size.height * 0.7)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .offset(x: geo.size.width * 0.15, y: geo.size.height * 0.1)
                .shadow(color: .black.opacity(0.8), radius: 50, x: -20)
                .overlay(
                    // Cinematic Title Overlap
                    VStack(alignment: .leading) {
                        Text(MockData.wallpapers[selectedIndex].name)
                            .font(.system(size: 84, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(
                                LinearGradient(colors: [.white, .white.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                            )
                            .offset(x: -geo.size.width * 0.1)
                        
                        Text("PLUM ENGINE V2 / ENGINE_ACTIVE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundStyle(Color(hex: "E03E3E"))
                            .offset(x: -geo.size.width * 0.08)
                    }
                    , alignment: .bottomLeading
                )
            }
            
            // LAYER 3: Vertical HUD Nav
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 40) {
                    Text("PLUM").font(.system(size: 18, weight: .black)).tracking(4).foregroundStyle(Color(hex: "E03E3E"))
                    
                    VStack(alignment: .leading, spacing: 20) {
                        NavLabel(text: "LIBRARY", isActive: true)
                        NavLabel(text: "SHADERS", isActive: false)
                        NavLabel(text: "STORAGE", isActive: false)
                    }
                    
                    Spacer()
                    
                    // Simple Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FPS: 60.0").font(.system(size: 10, design: .monospaced))
                        Text("GPU: 12%").font(.system(size: 10, design: .monospaced))
                    }.foregroundStyle(.secondary)
                }
                .padding(40)
                .frame(width: 200, alignment: .leading)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { breathing = 1.0 }
        }
    }
}

struct NavLabel: View {
    let text: String
    let isActive: Bool
    var body: some View {
        HStack {
            if isActive { Rectangle().fill(Color(hex: "E03E3E")).frame(width: 2, height: 12) }
            Text(text)
                .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .monospaced))
                .foregroundStyle(isActive ? .white : .secondary)
        }
    }
}

// Helpers & Mock
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

struct MockWallpaper: Identifiable {
    let id = UUID(); let name: String; let imageURL: String
}
struct MockData {
    static let wallpapers = [
        MockWallpaper(name: "Orbital Mechanics", imageURL: "https://images.unsplash.com/photo-1541562232579-512a21360020?q=80&w=2560&auto=format&fit=crop"),
        MockWallpaper(name: "Void Static", imageURL: "https://images.unsplash.com/photo-1518837695005-2083093ee35b?q=80&w=2560&auto=format&fit=crop")
    ]
}

SovereignApp.main()
