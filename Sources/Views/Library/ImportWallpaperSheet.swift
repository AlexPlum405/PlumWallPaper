import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SwiftData

/// 导入壁纸 Sheet (Scheme C: Artisan Gallery)
struct ImportWallpaperSheet: View {
    @Environment(\.dismiss) var dismiss
    @Query private var existingTags: [Tag]
    var viewModel: LibraryViewModel
    @Binding var toast: ToastConfig?

    @State var step: ImportStep = .selectFiles
    @State var selectedFiles: [URL] = []
    @State var isChecking = false
    @State var duplicates: [String] = []

    // Step 2: 元数据
    @State var customName: String = ""
    @State var selectedTag: String = ""
    @State var customTag: String = ""
    @State var showCustomTagInput = false
    @State var isFavorite = false

    private var combinedTagOptions: [String] {
        let defaultTags = ["4K UHD", "风景", "抽象", "动漫", "赛博朋克", "极简"]
        let dbTags = existingTags.map { $0.name }
        var result = defaultTags
        for tag in dbTags {
            if !result.contains(tag) {
                result.append(tag)
            }
        }
        return result
    }

    enum ImportStep {
        case selectFiles
        case metadata
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: 画廊表头
            headerSection

            // Content: 典藏中心
            ScrollView {
                VStack(spacing: 0) {
                    if step == .selectFiles {
                        artisanSelectFilesView
                    } else {
                        artisanMetadataView
                    }
                }
                .padding(48)
            }

            // Footer: 动作栏
            footerSection
        }
        .frame(width: step == .selectFiles ? 680 : 580, height: 640)
        .background(LiquidGlassBackgroundView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
        .artisanShadow()
    }

    // MARK: - Header (Artisan Table)

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(step == .selectFiles ? "导入本地资源" : "完善资源信息")
                    .artisanTitleStyle(size: 24)

                Text(step == .selectFiles ? "支持 Apple ProRAW, HEIC 及 8K CINEMATIC" : "即将入库 \(selectedFiles.count) 件艺术品")
                    .font(.system(size: 11, weight: .black))
                    .kerning(1)
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 48)
        .padding(.top, 40)
        .padding(.bottom, 24)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .bottom) {
            Rectangle().fill(LiquidGlassColors.glassBorder).frame(height: 0.5)
        }
    }

    // MARK: - Step 1: Select Files

    private var artisanSelectFilesView: some View {
        VStack(spacing: 40) {
            if isChecking {
                artisanCheckingView
            } else {
                artisanDropZone
                artisanActionButtons
            }
        }
    }

    private var artisanCheckingView: some View {
        VStack(spacing: 24) {
            CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.5)
            Text("验证艺术品一致性...")
                .font(.custom("Georgia", size: 14).italic())
                .foregroundStyle(LiquidGlassColors.textSecondary)
        }
        .frame(height: 280)
    }

    private var artisanDropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LiquidGlassColors.primaryPink.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.02)))

            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.03)).frame(width: 80, height: 80)
                    Image(systemName: "plus.app").font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                }

                VStack(spacing: 10) {
                    Text("ADD ARTWORK")
                        .font(.custom("Georgia", size: 18).bold())
                        .kerning(4)
                        .foregroundStyle(.white)

                    Text("将资源拖拽至展柜，或点击此处浏览")
                        .font(.system(size: 13))
                        .foregroundStyle(LiquidGlassColors.textQuaternary)
                }
            }
        }
        .frame(height: 280)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onTapGesture { openFilePicker(multiple: true) }
    }

    private var artisanActionButtons: some View {
        HStack(spacing: 20) {
            artisanImportOption(title: "批量文件", icon: "photo.stack", subtitle: "FILES") { openFilePicker(multiple: true) }
            artisanImportOption(title: "整包导入", icon: "folder.badge.plus", subtitle: "FOLDER") { openFolderPicker() }
        }
    }
    
    private func artisanImportOption(title: String, icon: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(LiquidGlassColors.primaryPink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .bold))
                    Text(subtitle).font(.system(size: 9, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .galleryCardStyle(radius: 16, padding: 0)
        }.buttonStyle(.plain)
    }

    // MARK: - Step 2: Metadata

    private var artisanMetadataView: some View {
        VStack(alignment: .leading, spacing: 32) {
            // 资源名称
            VStack(alignment: .leading, spacing: 12) {
                Text("作品命名").font(.system(size: 11, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
                TextField("如果不填写，将保留原始文件名", text: $customName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .galleryCardStyle(radius: 14, padding: 0)
            }

            // 分类索引
            VStack(alignment: .leading, spacing: 16) {
                Text("策展索引").font(.system(size: 11, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)

                FlowLayout(spacing: 10) {
                    ForEach(combinedTagOptions, id: \.self) { tag in
                        FilterChip(title: tag, isSelected: !showCustomTagInput && selectedTag == tag) {
                            withAnimation(.gallerySpring) { selectedTag = tag; showCustomTagInput = false; customTag = "" }
                        }
                    }
                    
                    if !customTag.isEmpty && !showCustomTagInput && !combinedTagOptions.contains(customTag) {
                        FilterChip(title: customTag, isSelected: selectedTag == customTag) {
                            withAnimation(.gallerySpring) { selectedTag = customTag }
                        }
                    }

                    if !showCustomTagInput {
                        Button { withAnimation(.gallerySpring) { showCustomTagInput = true } } label: {
                            Text("+ 新增索引")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .galleryCardStyle(radius: 10, padding: 0)
                        }.buttonStyle(.plain)
                    } else {
                        HStack(spacing: 8) {
                            TextField("输入索引...", text: $customTag)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 140)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .galleryCardStyle(radius: 10, padding: 0)

                            Button {
                                if !customTag.isEmpty {
                                    withAnimation(.gallerySpring) { selectedTag = customTag; showCustomTagInput = false }
                                } else {
                                    withAnimation(.gallerySpring) { showCustomTagInput = false }
                                }
                            } label: {
                                Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white).padding(10)
                                    .background(Circle().fill(LiquidGlassColors.primaryPink))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            // 收藏状态
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("列为精选藏品").font(.system(size: 14, weight: .bold))
                    Text("FEATURED ACQUISITION").font(.system(size: 9, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
                }
                Spacer()
                artisanToggle(isOn: $isFavorite)
            }
            .padding(24)
            .galleryCardStyle(radius: 20, padding: 0)
        }
    }
    
    private struct artisanToggle: View {
        @Binding var isOn: Bool
        var body: some View {
            Button { withAnimation(.gallerySpring) { isOn.toggle() } } label: {
                ZStack {
                    Capsule().fill(isOn ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1)).frame(width: 40, height: 22)
                    Circle().fill(Color.white).frame(width: 18, height: 18).shadow(color: .black.opacity(0.2), radius: 2).offset(x: isOn ? 9 : -9)
                }
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Footer (Artisan Bar)

    private var footerSection: some View {
        HStack {
            Text(step == .selectFiles ? "READY FOR ARCHIVING" : "FINALIZING GALLERY")
                .font(.system(size: 10, weight: .black))
                .kerning(2)
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    if step == .selectFiles { dismiss() } 
                    else { withAnimation(.gallerySpring) { step = .selectFiles; duplicates = [] } }
                } label: {
                    Text(step == .selectFiles ? "取消" : "上一步")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .galleryCardStyle(radius: 12, padding: 0)
                }.buttonStyle(.plain)

                Button { handlePrimaryAction() } label: {
                    HStack(spacing: 10) {
                        if viewModel.isImporting { CustomProgressView(tint: .white, scale: 0.8) }
                        Text(step == .selectFiles ? "选择文件" : "确认入库")
                            .font(.system(size: 13, weight: .bold)).kerning(1)
                    }
                    .padding(.horizontal, 36).padding(.vertical, 12)
                    .background(Capsule().fill(LiquidGlassColors.primaryPink))
                    .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 32)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .top) { Rectangle().fill(LiquidGlassColors.glassBorder).frame(height: 0.5) }
    }
}
