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
    }
}

struct MainView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var activeTab: String = "home"
    @State private var showSettings = false
    @State private var showImport = false

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
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.accent)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.white)
                                .frame(width: 12, height: 12)
                        )
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("Plum")
                            .font(Theme.Fonts.display(size: 28))
                        Text("WALLPAPER")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(4)
                            .opacity(0.4)
                    }
                }
                .onTapGesture { activeTab = "home" }

                Spacer()

                HStack(spacing: 4) {
                    NavPill(id: "home", label: "首页", icon: "house.fill", activeTab: $activeTab)
                    NavPill(id: "library", label: "壁纸库", icon: "square.grid.2x2.fill", activeTab: $activeTab)
                }
                .padding(4)
                .background(Theme.glass)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.border, lineWidth: 1)
                )

                Spacer()

                HStack(spacing: 16) {
                    NavActionBtn(icon: "magnifyingglass")
                    NavActionBtn(icon: "plus", isPrimary: true)
                        .onTapGesture { showImport = true }
                    NavActionBtn(icon: "gearshape.fill")
                        .onTapGesture { showSettings = true }
                }
            }
            .padding(.horizontal, 80)
            .frame(height: 80)
            .background(
                LinearGradient(
                    colors: [Theme.bg.opacity(0.8), .clear],
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
    }
}

struct TopNavBar: View {
    @Binding var activeTab: String
    @Binding var showSettings: Bool
    @Binding var showColorAdjust: Bool

    var body: some View {
        HStack(spacing: 0) {
            // 品牌区
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.accent)
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: 12, height: 12)
                    )
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("Plum")
                        .font(Theme.Fonts.display(size: 28))
                    Text("WALLPAPER")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(4)
                        .opacity(0.4)
                }
            }
            .onTapGesture { activeTab = "home" }

            Spacer()

            // Tab 切换
            HStack(spacing: 4) {
                NavPill(id: "home", label: "首页", icon: "house.fill", activeTab: $activeTab)
                NavPill(id: "library", label: "壁纸库", icon: "square.grid.2x2.fill", activeTab: $activeTab)
            }
            .padding(4)
            .background(Theme.glass)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.border, lineWidth: 1)
            )

            Spacer()

            // 操作按钮
            HStack(spacing: 16) {
                NavActionBtn(icon: "magnifyingglass")
                NavActionBtn(icon: "plus", isPrimary: true)
                    .onTapGesture { showColorAdjust = true }
                NavActionBtn(icon: "gearshape.fill")
                    .onTapGesture { showSettings = true }
            }
        }
        .padding(.horizontal, 80)
        .frame(height: 80)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Theme.bg.opacity(0.8), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct NavPill: View {
    let id: String
    let label: String
    let icon: String
    @Binding var activeTab: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(label).font(.system(size: 13, weight: .bold))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(activeTab == id ? Theme.glassHeavy : Color.clear)
        .foregroundColor(activeTab == id ? .white : .white.opacity(0.4))
        .cornerRadius(10)
        .onTapGesture {
            withAnimation(.spring()) {
                activeTab = id
            }
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
