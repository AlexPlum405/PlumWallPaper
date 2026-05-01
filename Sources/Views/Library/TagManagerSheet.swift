import SwiftUI

struct TagManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTagID: UUID?
    
    // 模拟标签数据
    @State private var tags: [TagMock] = [
        TagMock(name: "4K UHD", color: .blue, count: 128),
        TagMock(name: "Cyberpunk", color: .purple, count: 45),
        TagMock(name: "Minimalist", color: .gray, count: 89),
        TagMock(name: "Landscape", color: .green, count: 210),
        TagMock(name: "Abstract", color: .orange, count: 67)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("标签管理中心")
                    .font(.system(size: 16, weight: .black))
                    .kerning(1)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            HStack(spacing: 0) {
                // 左侧：标签列表与搜索
                VStack(spacing: 16) {
                    searchField
                    
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(filteredTags) { tag in
                                TagListRow(tag: tag, isSelected: selectedTagID == tag.id) {
                                    selectedTagID = tag.id
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 新建按钮
                    Button {
                        // TODO: Create new tag
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("新建标签")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(LiquidGlassColors.primaryPink.opacity(0.15))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(width: 260)
                .background(Color.black.opacity(0.15))
                
                // 分割线
                Rectangle().fill(.white.opacity(0.06)).frame(width: 1)
                
                // 右侧：详情编辑区
                VStack {
                    if let selectedTagID = selectedTagID, let tag = tags.first(where: { $0.id == selectedTagID }) {
                        tagEditor(tag: tag)
                    } else {
                        emptySelectionView
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.02))
            }
        }
        .frame(width: 700, height: 500)
        .background(LiquidGlassBackgroundView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.1), lineWidth: 1))
    }
    
    // MARK: - 子组件
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
            
            TextField("搜索标签...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func tagEditor(tag: TagMock) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("标签名称")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                
                TextField("输入名称", text: .constant(tag.name))
                    .font(.system(size: 24, weight: .bold))
                    .textFieldStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("视觉标记")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                
                HStack(spacing: 12) {
                    ForEach([Color.blue, .red, .green, .orange, .purple, .pink], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: tag.color == color ? 2 : 0))
                            .onTapGesture {
                                // TODO: Update color
                            }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("统计信息")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                
                HStack(spacing: 20) {
                    statBox(label: "已绑定壁纸", value: "\(tag.count)")
                    statBox(label: "最后使用", value: "2 小时前")
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    // TODO: Delete
                } label: {
                    Text("删除标签")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button {
                    // TODO: Save
                } label: {
                    Text("保存更改")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(LiquidGlassColors.primaryPink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
    }
    
    private func statBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 10)).foregroundStyle(.white.opacity(0.4))
            Text(value).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var emptySelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.1))
            Text("请从左侧选择一个标签进行管理")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    private var filteredTags: [TagMock] {
        if searchText.isEmpty { return tags }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

private struct TagListRow: View {
    let tag: TagMock
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(tag.color)
                    .frame(width: 8, height: 8)
                
                Text(tag.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                
                Spacer()
                
                Text("\(tag.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? LiquidGlassColors.primaryPink.opacity(0.15) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// 模拟数据结构
private struct TagMock: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var count: Int
}
