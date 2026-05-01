import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 导入壁纸 Sheet - 完整复刻 v1 功能
struct ImportWallpaperSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: LibraryViewModel
    @Binding var toast: ToastConfig?

    @State private var step: ImportStep = .selectFiles
    @State private var selectedFiles: [URL] = []
    @State private var isChecking = false
    @State private var duplicates: [String] = []

    // Step 2: 元数据
    @State private var customName: String = ""
    @State private var selectedTag: String = ""
    @State private var customTag: String = ""
    @State private var showCustomTagInput = false
    @State private var isFavorite = false

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

    // MARK: - Actions

    private func handlePrimaryAction() {
        if step == .selectFiles {
            openFilePicker(multiple: true)
        } else {
            Task {
                await performImport()
            }
        }
    }

    private func openFilePicker(multiple: Bool) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = multiple
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.movie, .image]
        panel.message = multiple ? "选择要导入的壁纸文件（支持多选）" : "选择要导入的壁纸文件"
        panel.prompt = "选择"  // 设置按钮文字为中文
        panel.canCreateDirectories = false

        panel.begin { response in
            guard response == .OK, !panel.urls.isEmpty else { return }
            Task { @MainActor in
                await checkAndProceed(urls: panel.urls)
            }
        }
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "选择包含壁纸文件的目录"
        panel.prompt = "选择"  // 设置按钮文字为中文
        panel.canCreateDirectories = false

        panel.begin { response in
            guard response == .OK, let folderURL = panel.url else { return }
            Task { @MainActor in
                await scanFolder(url: folderURL)
            }
        }
    }

    private func scanFolder(url: URL) async {
        isChecking = true

        do {
            let validExts = Set(["mp4", "mov", "m4v", "heic", "heif", "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif"])
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            let mediaFiles = contents.filter { validExts.contains($0.pathExtension.lowercased()) }

            guard !mediaFiles.isEmpty else {
                toast = ToastConfig(message: "目录中没有找到支持的壁纸文件", type: .warning)
                isChecking = false
                return
            }

            await checkAndProceed(urls: mediaFiles)
        } catch {
            toast = ToastConfig(message: "读取目录失败: \(error.localizedDescription)", type: .error)
            isChecking = false
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        Task { @MainActor in
            var urls: [URL] = []

            for provider in providers {
                // 正确的拖拽处理方式
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    do {
                        let data = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) as? Data
                        if let data = data,
                           let path = String(data: data, encoding: .utf8),
                           let url = URL(string: path) {
                            urls.append(url)
                        }
                    } catch {
                        print("拖拽加载失败: \(error)")
                    }
                }
            }

            guard !urls.isEmpty else { return }
            await checkAndProceed(urls: urls)
        }
    }

    private func checkAndProceed(urls: [URL]) async {
        isChecking = true

        // 检查重复
        var newFiles: [URL] = []
        var duplicateNames: [String] = []

        for url in urls {
            // 简化版重复检测（实际应该用 fileHash）
            if viewModel.wallpapers.contains(where: { $0.filePath == url.path }) {
                duplicateNames.append(url.lastPathComponent)
            } else {
                newFiles.append(url)
            }
        }

        isChecking = false

        if newFiles.isEmpty {
            toast = ToastConfig(message: "所有文件均已存在，无需导入", type: .info)
            return
        }

        selectedFiles = newFiles
        duplicates = duplicateNames
        step = .metadata
    }

    private func performImport() async {
        viewModel.isImporting = true

        do {
            let imported = try await FileImporter.shared.importFiles(urls: selectedFiles)

            for (index, wallpaper) in imported.enumerated() {
                // 自定义名称
                if !customName.isEmpty {
                    wallpaper.name = imported.count > 1 ? "\(customName) (\(index + 1))" : customName
                }

                // 重复检测
                if viewModel.wallpapers.contains(where: { $0.fileHash == wallpaper.fileHash }) {
                    var suffix = 2
                    let baseName = wallpaper.name
                    while viewModel.wallpapers.contains(where: { $0.name == "\(baseName) (\(suffix))" }) {
                        suffix += 1
                    }
                    wallpaper.name = "\(baseName) (\(suffix))"
                }

                // 设置收藏
                wallpaper.isFavorite = isFavorite

                // TODO: 添加标签（需要 Tag 关联逻辑）

                viewModel.wallpapers.append(wallpaper)
            }

            viewModel.save()
            viewModel.isImporting = false

            toast = ToastConfig(message: "已导入 \(imported.count) 个壁纸", type: .success)
            dismiss()
        } catch {
            viewModel.isImporting = false
            toast = ToastConfig(message: "导入失败: \(error.localizedDescription)", type: .error)
        }
    }
}
