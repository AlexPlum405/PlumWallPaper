import SwiftUI
import AppKit

struct MyLibraryView: View {
    @State var viewModel = LibraryViewModel()

    // 任务 5: 编辑模式状态
    @State var isEditMode = false
    @State var selectedIDs = Set<UUID>()

    // Toast 状态
    @State var toast: ToastConfig?

    // 删除确认对话框
    @State var showDeleteConfirm = false

    // 导入 Sheet
    @State var showImportSheet = false
    
    // 布局配置
    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 320), spacing: 24)
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 1. 顶部操作区 (子导航 + 编辑/导入)
                headerSection
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // 2. 主内容区
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        if filteredWallpapers.isEmpty {
                            emptyStateView
                        } else {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(filteredWallpapers) { wallpaper in
                                    ZStack(alignment: .topLeading) {
                                        WallpaperCard(wallpaper: wallpaper) {
                                            if isEditMode {
                                                toggleSelection(wallpaper.id)
                                            } else {
                                                // TODO: 打开详情页
                                            }
                                        }
                                        .scaleEffect(isEditMode ? 0.94 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEditMode)

                                        // 选中状态指示器 (极致视觉)
                                        if isEditMode {
                                            selectionIndicator(for: wallpaper.id)
                                                .padding(12)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                            }
                        }

                        // 底部间距：为悬浮胶囊留白
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 32)
                }
                .scrollIndicators(.hidden)
            }

            // 3. 悬浮批量操作胶囊 (极致 Plum 风格)
            if isEditMode {
                VStack {
                    Spacer()
                    batchActionCapsule
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .toast($toast)
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) { }
            Button("删除 \(selectedIDs.count) 项", role: .destructive) {
                confirmDelete()
            }
        } message: {
            Text("删除后无法恢复，确定要删除选中的 \(selectedIDs.count) 个壁纸吗？")
        }
        .sheet(isPresented: $showImportSheet) {
            ImportWallpaperSheet(viewModel: viewModel, toast: $toast)
        }
    }
    
    // MARK: - 子视图组件
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            // 子标签切换
            HStack(spacing: 12) {
                ForEach(LibraryViewModel.LibraryTab.allCases, id: \.self) { tab in
                    FilterChip(
                        title: tab.rawValue,
                        isSelected: viewModel.selectedTab == tab,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedTab = tab
                                // 切换 Tab 时退出编辑模式并清空选择
                                isEditMode = false
                                selectedIDs.removeAll()
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            // 操作组
            HStack(spacing: 12) {
                // 编辑模式切换按钮
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        isEditMode.toggle()
                        if !isEditMode { selectedIDs.removeAll() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isEditMode ? "checkmark.circle.fill" : "checklist")
                        Text(isEditMode ? "完成" : "批量操作")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isEditMode ? LiquidGlassColors.primaryPink : .white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(isEditMode ? .white.opacity(0.1) : .white.opacity(0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if !isEditMode {
                    // 导入按钮
                    Button(action: { showImportSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("导入壁纸")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background {
                            Capsule().fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .leading, endPoint: .trailing))
                                .shadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 10, y: 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // 选中指示器
    private func selectionIndicator(for id: UUID) -> some View {
        let isSelected = selectedIDs.contains(id)
        return ZStack {
            Circle()
                .fill(isSelected ? LiquidGlassColors.primaryPink : .black.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 1.5))
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .shadow(color: isSelected ? LiquidGlassColors.primaryPink.opacity(0.4) : .clear, radius: 8)
    }
    
    // 批量操作胶囊
    private var batchActionCapsule: some View {
        HStack(spacing: 24) {
            Text("已选择 \(selectedIDs.count) 项")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.trailing, 12)

            Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 24)

            // 操作按钮组
            HStack(spacing: 20) {
                // 智能收藏按钮
                smartFavoriteButton

                batchActionButton(icon: "trash.fill", label: "删除", color: .red) {
                    performBatchDelete()
                }
                batchActionButton(icon: "folder.fill", label: "移动", color: LiquidGlassColors.tertiaryBlue) { }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.4), radius: 25, y: 15)
        }
    }

    // 智能收藏按钮（根据选中项状态动态变化）
    private var smartFavoriteButton: some View {
        let state = selectedFavoriteState
        let icon = state == .all ? "heart.slash.fill" : "heart.fill"
        let label = state == .all ? "取消" : "收藏"

        return batchActionButton(icon: icon, label: label, color: LiquidGlassColors.primaryPink) {
            performBatchFavorite()
        }
    }
    
    private func batchActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(color.opacity(0.9))
            .frame(width: 44)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 100)
            ZStack {
                Circle().fill(.white.opacity(0.05)).frame(width: 120, height: 120)
                Image(systemName: "folder.badge.questionmark").font(.system(size: 40)).foregroundStyle(.white.opacity(0.2))
            }
            VStack(spacing: 8) {
                Text("暂无内容").font(.system(size: 18, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                Text("你还没有\(viewModel.selectedTab.rawValue)任何壁纸").font(.system(size: 14)).foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
