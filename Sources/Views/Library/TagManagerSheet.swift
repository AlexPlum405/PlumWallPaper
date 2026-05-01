import SwiftUI

// MARK: - Artisan Tag Manager (Scheme C: Artisan Gallery)
// 这里是 Plum 的策展索引库，通过艺术标签组织您的数字藏品。

struct TagManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTagID: UUID?
    
    // 模拟标签数据 (同步至莫兰迪色系)
    @State private var tags: [TagMock] = [
        TagMock(name: "4K UHD", color: LiquidGlassColors.tertiaryBlue, count: 128),
        TagMock(name: "Cyberpunk", color: LiquidGlassColors.primaryViolet, count: 45),
        TagMock(name: "Minimalist", color: LiquidGlassColors.textQuaternary, count: 89),
        TagMock(name: "Landscape", color: LiquidGlassColors.onlineGreen, count: 210),
        TagMock(name: "Abstract", color: LiquidGlassColors.warningOrange, count: 67)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. 左侧：索引侧栏
            artisanSidebar
            
            // 2. 右侧：编辑工作室
            VStack {
                if let selectedTagID = selectedTagID, let tag = tags.first(where: { $0.id == selectedTagID }) {
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
    }
    
    // MARK: - A. 侧栏组件
    
    private var artisanSidebar: some View {
        VStack(spacing: 0) {
            // 表头
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("策展索引")
                        .artisanTitleStyle(size: 20)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
                    }.buttonStyle(.plain)
                }
                
                // 搜索框 (画廊化)
                HStack {
                    Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(LiquidGlassColors.textQuaternary)
                    TextField("检索标签...", text: $searchText).textFieldStyle(.plain).font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 12).frame(height: 36).galleryCardStyle(radius: 10, padding: 0)
            }
            .padding(28)
            
            // 标签列表
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(filteredTags) { tag in
                        ArtisanTagRow(tag: tag, isSelected: selectedTagID == tag.id) {
                            withAnimation(.gallerySpring) { selectedTagID = tag.id }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // 新建索引按钮
            Button { /* 逻辑 */ } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                    Text("新增索引项")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(Capsule().fill(LiquidGlassColors.primaryPink))
                .padding(24)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 280)
        .background(LiquidGlassBackgroundView(material: .sidebar))
        .overlay(Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 0.5), alignment: .trailing)
    }
    
    // MARK: - B. 编辑区组件
    
    private func artisanTagEditor(tag: TagMock) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            // 索引名称
            VStack(alignment: .leading, spacing: 14) {
                Text("INDEX NAME")
                    .font(.system(size: 10, weight: .black)).kerning(3).foregroundStyle(LiquidGlassColors.textQuaternary)
                
                TextField("输入名称", text: .constant(tag.name))
                    .artisanTitleStyle(size: 44)
                    .textFieldStyle(.plain)
            }
            
            // 视觉标记器
            VStack(alignment: .leading, spacing: 20) {
                Text("VISUAL IDENTIFIER")
                    .font(.system(size: 10, weight: .black)).kerning(3).foregroundStyle(LiquidGlassColors.textQuaternary)
                
                HStack(spacing: 16) {
                    ForEach([LiquidGlassColors.tertiaryBlue, .red, .green, .orange, .purple, LiquidGlassColors.primaryPink], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: tag.color == color ? 3 : 0))
                            .artisanShadow(color: color.opacity(0.2), radius: 10)
                            .onTapGesture { /* 逻辑更新 */ }
                    }
                }
            }
            
            // 统计看板
            VStack(alignment: .leading, spacing: 20) {
                Text("COLLECTION STATS")
                    .font(.system(size: 10, weight: .black)).kerning(3).foregroundStyle(LiquidGlassColors.textQuaternary)
                
                HStack(spacing: 20) {
                    artisanStatBox(label: "已绑定画作", value: "\(tag.count)", unit: "PIECES")
                    artisanStatBox(label: "索引热度", value: "HIGH", unit: "DEMAND")
                }
            }
            
            Spacer()
            
            // 操作栏
            HStack(spacing: 16) {
                Button { /* 逻辑 */ } label: {
                    Text("移除此索引")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.errorRed)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .galleryCardStyle(radius: 12, padding: 0)
                }.buttonStyle(.plain)
                
                Button { /* 逻辑 */ } label: {
                    Text("保存典藏")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Capsule().fill(LiquidGlassColors.primaryPink))
                }.buttonStyle(.plain)
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
        .padding(.horizontal, 24).padding(.vertical, 20)
        .galleryCardStyle(radius: 20, padding: 0)
    }
    
    private var artisanEmptySelectionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tag.circle").font(.system(size: 64, weight: .ultraLight)).foregroundStyle(LiquidGlassColors.textQuaternary)
            Text("请在左侧选择索引进行管理").font(.custom("Georgia", size: 16).italic()).foregroundStyle(LiquidGlassColors.textQuaternary)
        }
    }
    
    private var filteredTags: [TagMock] {
        if searchText.isEmpty { return tags }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - 辅助子组件

private struct ArtisanTagRow: View {
    let tag: TagMock
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(tag.color).frame(width: 6, height: 6)
                Text(tag.name).font(.system(size: 13, weight: isSelected ? .bold : .medium)).kerning(0.5)
                Spacer()
                Text("\(tag.count)").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : LiquidGlassColors.textQuaternary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background {
                if isSelected || isHovered {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isSelected ? LiquidGlassColors.primaryPink.opacity(0.12) : Color.white.opacity(0.04))
                }
            }
            .foregroundStyle(isSelected ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct TagMock: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var count: Int
}
