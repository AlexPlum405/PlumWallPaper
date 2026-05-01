import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 导入壁纸 Sheet - 完整复刻 v1 功能
struct ImportWallpaperSheet: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: LibraryViewModel
    @Binding var toast: ToastConfig?

    @State var step: ImportStep = .selectFiles
    @State var selectedFiles: [URL] = []
    @State var isChecking = false
    @State var duplicates: [String] = []

    // Step 2: 元数据
    @State var customName: String = ""
    @State private var selectedTag: String = ""
    @State private var customTag: String = ""
    @State private var showCustomTagInput = false
    @State var isFavorite = false

    private let tagOptions = ["4K UHD", "风景", "抽象", "动漫", "赛博朋克", "极简"]

    enum ImportStep {
        case selectFiles
        case metadata
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    if step == .selectFiles {
                        selectFilesView
                    } else {
                        metadataView
                    }
                }
                .padding(40)
            }

            // Footer
            footerSection
        }
        .frame(width: step == .selectFiles ? 640 : 560, height: 600)
        .background(LiquidGlassBackgroundView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 50, y: 30)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(step == .selectFiles ? "导入壁纸资源" : "完善壁纸信息")
                    .font(.system(size: 22, weight: .semibold))

                Text(step == .selectFiles ? "支持 Apple ProRAW, HEIC 及 8K 视频" : "已选择 \(selectedFiles.count) 个文件")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    // MARK: - Select Files View

    private var selectFilesView: some View {
        VStack(spacing: 32) {
            if isChecking {
                checkingView
            } else {
                dropZone
                actionButtons
            }
        }
    }

    private var checkingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(LiquidGlassColors.primaryPink)

            Text("正在检查文件...")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(height: 240)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LiquidGlassColors.primaryPink.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.02)))

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.05))
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 10)

                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                }

                VStack(spacing: 8) {
                    Text("在此处添加您的资源")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text("或者拖拽文件到窗口内")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .frame(height: 240)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onTapGesture {
            openFilePicker(multiple: true)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                openFilePicker(multiple: true)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 18))
                    Text("批量文件")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                openFolderPicker()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 18))
                    Text("整包导入")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Metadata View

    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 资源名称
            VStack(alignment: .leading, spacing: 8) {
                Text("资源名称")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))

                TextField("", text: $customName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
            }

            // 所属分类标签
            VStack(alignment: .leading, spacing: 12) {
                Text("所属分类标签")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))

                FlowLayout(spacing: 8) {
                    ForEach(tagOptions, id: \.self) { tag in
                        tagChip(tag: tag, isSelected: !showCustomTagInput && selectedTag == tag) {
                            selectedTag = tag
                            showCustomTagInput = false
                        }
                    }

                    if !showCustomTagInput {
                        Button {
                            showCustomTagInput = true
                        } label: {
                            Text("+ 新增分类")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 6) {
                            TextField("输入分类名...", text: $customTag)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .frame(width: 120)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(LiquidGlassColors.primaryPink, lineWidth: 1))

                            Button {
                                if !customTag.isEmpty {
                                    selectedTag = customTag
                                    showCustomTagInput = false
                                    customTag = ""
                                }
                            } label: {
                                Text("确定")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(LiquidGlassColors.primaryPink))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // 加入我的收藏
            HStack {
                Text("加入我的收藏")
                    .font(.system(size: 14))

                Spacer()

                Toggle("", isOn: $isFavorite)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: LiquidGlassColors.primaryPink))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.02)))
        }
    }

    private func tagChip(tag: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text(step == .selectFiles ? "支持 MP4, MOV, M4V, HEIC, JPG, PNG 等格式" : "即将导入 \(selectedFiles.count) 个资源")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.3))

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if step == .selectFiles {
                        dismiss()
                    } else {
                        step = .selectFiles
                        duplicates = []
                    }
                } label: {
                    Text(step == .selectFiles ? "取消" : "返回上一步")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.05)))
                }
                .buttonStyle(.plain)

                Button {
                    handlePrimaryAction()
                } label: {
                    Text(step == .selectFiles ? "选择文件" : "确认并导入")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .leading, endPoint: .trailing)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

}
