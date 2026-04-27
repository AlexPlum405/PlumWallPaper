import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var allWallpapers: [Wallpaper]
    @Query private var tags: [Tag]

    @State private var searchText = ""
    @State private var selectedTagName: String? = "全部"
    @State private var showingColorAdjust: Wallpaper? = nil
    @State private var showingMonitorSelector: Wallpaper? = nil
    @State private var selectedSort: LibrarySortOrder = .importDate

    enum LibrarySortOrder: String, CaseIterable, Identifiable {
        case importDate = "按导入时间"
        case name = "按名称"
        case recent = "按最近使用"
        var id: String { rawValue }
    }

    var filteredWallpapers: [Wallpaper] {
        let filtered = allWallpapers.filter { wallpaper in
            let matchesSearch = searchText.isEmpty || wallpaper.name.localizedCaseInsensitiveContains(searchText)
            let matchesTag: Bool
            if selectedTagName == nil || selectedTagName == "全部" {
                matchesTag = true
            } else if selectedTagName == "收藏" {
                matchesTag = wallpaper.isFavorite
            } else {
                matchesTag = wallpaper.tags.contains(where: { $0.name == selectedTagName })
            }
            return matchesSearch && matchesTag
        }

        switch selectedSort {
        case .importDate:
            return filtered.sorted { $0.importDate > $1.importDate }
        case .name:
            return filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .recent:
            return filtered.sorted { ($0.lastUsedDate ?? .distantPast) > ($1.lastUsedDate ?? .distantPast) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.3))
                    TextField("搜索壁纸名称...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.glass)
                .cornerRadius(12)
                .frame(width: 320)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TagFilterBtn(name: "全部", isActive: selectedTagName == "全部") { selectedTagName = "全部" }
                        TagFilterBtn(name: "收藏", isActive: selectedTagName == "收藏") { selectedTagName = "收藏" }
                        ForEach(tags) { tag in
                            TagFilterBtn(name: tag.name, isActive: selectedTagName == tag.name) {
                                selectedTagName = tag.name
                            }
                        }
                    }
                }

                Spacer()

                Picker("", selection: $selectedSort) {
                    ForEach(LibrarySortOrder.allCases) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }
            .padding(.horizontal, 80)
            .padding(.top, 120)
            .padding(.bottom, 40)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 32)], spacing: 40) {
                    ForEach(filteredWallpapers) { wallpaper in
                        LibraryCard(wallpaper: wallpaper)
                            .contextMenu {
                                Button {
                                    showingMonitorSelector = wallpaper
                                } label: {
                                    Label("设为壁纸", systemImage: "desktopcomputer")
                                }

                                Button {
                                    showingColorAdjust = wallpaper
                                } label: {
                                    Label("色彩调节", systemImage: "slider.horizontal.3")
                                }

                                Button {
                                    wallpaper.isFavorite.toggle()
                                    try? modelContext.save()
                                } label: {
                                    Label(wallpaper.isFavorite ? "取消收藏" : "收藏", systemImage: wallpaper.isFavorite ? "heart.slash" : "heart")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    modelContext.delete(wallpaper)
                                    try? modelContext.save()
                                } label: {
                                    Label("移除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 80)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .fullScreenCover(item: $showingColorAdjust) { wallpaper in
            ColorAdjustView(wallpaper: wallpaper)
        }
        .sheet(item: $showingMonitorSelector) { wallpaper in
            MonitorSelectorView(wallpaper: wallpaper)
        }
    }
}

struct LibraryCard: View {
    let wallpaper: Wallpaper
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topTrailing) {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                   let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fill)
                        .cornerRadius(16)
                } else {
                    Color.white.opacity(0.03)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(16)
                }

                if wallpaper.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Theme.accent)
                        .padding(12)
                }

                if isHovered {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { isHovered = $0 }

            VStack(alignment: .leading, spacing: 6) {
                Text(wallpaper.name)
                    .font(.system(size: 15, weight: .bold))
                Text("\(wallpaper.resolution) · \(wallpaper.type.displayName) · \(wallpaper.formattedFileSize)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}

struct TagFilterBtn: View {
    let name: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Theme.glassHeavy : Theme.glass)
                .foregroundColor(isActive ? .white : .white.opacity(0.4))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
