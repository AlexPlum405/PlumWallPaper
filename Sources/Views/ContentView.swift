// Sources/Views/ContentView.swift
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case library = "壁纸库"
    case shaderEditor = "着色器编辑器"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library: return "photo.on.rectangle"
        case .shaderEditor: return "slider.horizontal.3"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .library

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            switch selectedItem {
            case .library:
                Text("壁纸库 - 待实现")
            case .shaderEditor:
                Text("着色器编辑器 - 待实现")
            case .settings:
                Text("设置 - 待实现")
            case nil:
                Text("选择一个页面")
            }
        }
    }
}
