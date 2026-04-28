//
//  PlumWallPaperApp.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import SwiftUI
import SwiftData

@main
struct PlumWallPaperApp: App {
    let modelContainer: ModelContainer
    @State private var viewModel = AppViewModel()

    init() {
        do {
            let schema = Schema([
                Wallpaper.self,
                Tag.self,
                FilterPreset.self,
                Settings.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
                .modelContainer(modelContainer)
                .environment(viewModel)
                .task {
                    await viewModel.restoreLastSession(context: modelContainer.mainContext)
                }
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.titleVisibility = .hidden
                        window.titlebarAppearsTransparent = true
                        window.styleMask.insert(.fullSizeContentView)
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("退出 PlumWallPaper") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}

struct MainView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var activeTab: String = "home"
    @State private var showSettings = false
    @State private var showImport = false
    @Namespace private var animation

    var body: some View {
        @Bindable var vm = viewModel

        ZStack(alignment: .top) {
            Group {
                if activeTab == "home" {
                    HomeView()
                } else {
                    LibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Logo 容器 (100% 原型还原: 深色玻璃 + 红色果实)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "16181C"))
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        // 红色果实核心 (Plum)
                        ZStack {
                            // 红色果体
                            Circle()
                                .fill(LinearGradient(colors: [Theme.accent, Color(hex: "A02020")], startPoint: .top, endPoint: .bottom))
                                .frame(width: 22, height: 22)
                                .offset(y: 2)
                            
                            // 绿色小叶/柄 (原型中那个绿色横线)
                            Capsule()
                                .fill(Color(hex: "2ECC71"))
                                .frame(width: 8, height: 3)
                                .offset(y: -8)
                        }
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("Plum")
                            .font(Theme.Fonts.display(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("WALLPAPER")
                            .font(.system(size: 9, weight: .black))
                            .tracking(4) // 严格对齐 letter-spacing
                            .opacity(0.35)
                    }
                }
                .onTapGesture { withAnimation { activeTab = "home" } }

                Spacer()

                // Pill Tab (灵动分段控制器 - 原型样式)
                HStack(spacing: 0) {
                    ForEach(["home", "library"], id: \.self) { id in
                        Text(id == "home" ? "首页" : "壁纸库")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .foregroundColor(activeTab == id ? .white : .white.opacity(0.4))
                            .background(
                                ZStack {
                                    if activeTab == id {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                            .background(VisualEffectView(material: .hudWindow).cornerRadius(12))
                                            .shadow(color: .black.opacity(0.2), radius: 10)
                                            .matchedGeometryEffect(id: "pill", in: animation)
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) {
                                    activeTab = id
                                }
                            }
                    }
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))

                Spacer()

                HStack(spacing: 16) {
                    NavActionBtn(icon: "magnifyingglass")
                    NavActionBtn(icon: "plus", isPrimary: true)
                        .onTapGesture { showImport = true }
                    NavActionBtn(icon: "gearshape.fill")
                        .onTapGesture { showSettings = true }
                }
            }
            .padding(.horizontal, 56) // 原型 56px
            .frame(height: 110) // 原型 110px
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.4), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .sheet(isPresented: $showImport) {
            ImportModalView()
        }
        .sheet(item: $vm.monitorSelectorRequest) { wallpaper in
            MonitorSelectorView(wallpaper: wallpaper)
        }
        .sheet(item: $vm.colorAdjustRequest) { wallpaper in
            ColorAdjustView(wallpaper: wallpaper)
        }
    }
}

struct NavActionBtn: View {
    let icon: String
    var isPrimary: Bool = false

    var body: some View {
        ZStack {
            if isPrimary {
                Circle().fill(Color.white)
            } else {
                Circle()
                    .fill(Theme.glass)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
            }
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isPrimary ? .black : .white)
        }
        .frame(width: 44, height: 44)
    }
}
