import SwiftUI
import SwiftData

// MARK: - Artisan Tag Manager (Scheme C: Artisan Gallery)
struct TagManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var searchText = ""
    @State private var selectedTagID: UUID?
    @State private var editName = ""
    @State private var editColor = "#81A1C1"
    @State private var toast: ToastConfig?

    private let palette: [(hex: String, color: Color)] = [
        ("#81A1C1", LiquidGlassColors.tertiaryBlue),
        ("#B4A0E5", LiquidGlassColors.primaryViolet),
        ("#A8D5BA", LiquidGlassColors.onlineGreen),
        ("#EBCB8B", LiquidGlassColors.warningOrange),
        ("#BF616A", LiquidGlassColors.errorRed),
        ("#F4C2C2", LiquidGlassColors.primaryPink)
    ]

    var body: some View {
        HStack(spacing: 0) {
            artisanSidebar

            VStack {
                if let tag = selectedTag {
                    artisanTagEditor(tag: tag)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                } else {
                    artisanEmptySelectionView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LiquidGlassColors.deepBackground)
        }
        .frame(width: 800, height: 580)
        .background(LiquidGlassBackgroundView(material: .hudWindow))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
        .artisanShadow()
        .toast($toast)
        .onAppear {
            if selectedTagID == nil, let first = tags.first {
                selectTag(first)
            }
        }
    }

    private var artisanSidebar: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("策展索引")
                        .artisanTitleStyle(size: 20)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.textQuaternary)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(LiquidGlassColors.textQuaternary)
                    TextField("检索标签...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .galleryCardStyle(radius: 10, padding: 0)
            }
            .padding(28)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(filteredTags) { tag in
                        ArtisanTagRow(tag: tag, color: Color(hex: tag.color), isSelected: selectedTagID == tag.id) {
                            withAnimation(.gallerySpring) { selectTag(tag) }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            Button { createTag() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                    Text("新增索引项")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Capsule().fill(LiquidGlassColors.primaryPink))
                .padding(24)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 280)
        .background(LiquidGlassBackgroundView(material: .sidebar))
        .overlay(Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 0.5), alignment: .trailing)
    }

    private func artisanTagEditor(tag: Tag) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: 14) {
                Text("INDEX NAME")
                    .font(.system(size: 10, weight: .black))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.textQuaternary)

                TextField("输入名称", text: $editName)
                    .artisanTitleStyle(size: 44)
                    .textFieldStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("VISUAL IDENTIFIER")
                    .font(.system(size: 10, weight: .black))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.textQuaternary)

                HStack(spacing: 16) {
                    ForEach(palette, id: \.hex) { item in
                        Circle()
                            .fill(item.color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: editColor == item.hex ? 3 : 0))
                            .artisanShadow(color: item.color.opacity(0.2), radius: 10)
                            .onTapGesture { editColor = item.hex }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("COLLECTION STATS")
                    .font(.system(size: 10, weight: .black))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.textQuaternary)

                HStack(spacing: 20) {
                    artisanStatBox(label: "已绑定画作", value: "\(tag.wallpapers.count)", unit: "PIECES")
                    artisanStatBox(label: "索引颜色", value: editColor.replacingOccurrences(of: "#", with: ""), unit: "HEX")
                }
            }

            Spacer()

            HStack(spacing: 16) {
                Button { deleteSelectedTag() } label: {
                    Text("移除此索引")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.errorRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .galleryCardStyle(radius: 12, padding: 0)
                }
                .buttonStyle(.plain)

                Button { saveSelectedTag() } label: {
                    Text("保存典藏")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(LiquidGlassColors.primaryPink))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(60)
    }

    private func artisanStatBox(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value).font(.custom("Georgia", size: 28).bold()).foregroundStyle(LiquidGlassColors.textPrimary)
                Text(unit).font(.system(size: 9, weight: .black)).foregroundStyle(LiquidGlassColors.primaryPink)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .galleryCardStyle(radius: 20, padding: 0)
    }

    private var artisanEmptySelectionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tag.circle")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            Text(tags.isEmpty ? "暂无索引，点击左下角新增" : "请在左侧选择索引进行管理")
                .font(.custom("Georgia", size: 16).italic())
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
    }

    private var filteredTags: [Tag] {
        if searchText.isEmpty { return tags }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var selectedTag: Tag? {
        guard let selectedTagID else { return nil }
        return tags.first { $0.id == selectedTagID }
    }

    private func selectTag(_ tag: Tag) {
        selectedTagID = tag.id
        editName = tag.name
        editColor = tag.color
    }

    private func createTag() {
        let baseName = "新索引"
        var name = baseName
        var suffix = 2
        while tags.contains(where: { $0.name == name }) {
            name = "\(baseName) \(suffix)"
            suffix += 1
        }

        let tag = Tag(name: name, color: palette[tags.count % palette.count].hex)
        modelContext.insert(tag)
        saveContext(message: "已创建索引")
        selectTag(tag)
    }

    private func saveSelectedTag() {
        guard let tag = selectedTag else { return }
        let normalized = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            toast = ToastConfig(message: "索引名称不能为空", type: .warning)
            return
        }

        if tags.contains(where: { $0.id != tag.id && $0.name == normalized }) {
            toast = ToastConfig(message: "已存在同名索引", type: .warning)
            return
        }

        tag.name = normalized
        tag.color = editColor
        saveContext(message: "索引已保存")
    }

    private func deleteSelectedTag() {
        guard let tag = selectedTag else { return }
        modelContext.delete(tag)
        selectedTagID = tags.first(where: { $0.id != tag.id })?.id
        if let next = selectedTag {
            selectTag(next)
        } else {
            editName = ""
            editColor = palette[0].hex
        }
        saveContext(message: "索引已移除")
    }

    private func saveContext(message: String) {
        do {
            try modelContext.save()
            toast = ToastConfig(message: message, type: .success)
        } catch {
            toast = ToastConfig(message: "保存失败: \(error.localizedDescription)", type: .error)
        }
    }
}

private struct ArtisanTagRow: View {
    let tag: Tag
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(tag.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .kerning(0.5)
                Spacer()
                Text("\(tag.wallpapers.count)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : LiquidGlassColors.textQuaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if isSelected || isHovered {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? LiquidGlassColors.primaryPink.opacity(0.12) : Color.white.opacity(0.04))
                }
            }
            .foregroundStyle(isSelected ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
