import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SwiftData

extension ImportWallpaperSheet {

    // MARK: - Actions

    func handlePrimaryAction() {
        if step == .selectFiles {
            openFilePicker(multiple: true)
        } else {
            Task {
                await performImport()
            }
        }
    }

    func openFilePicker(multiple: Bool) {
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

    func openFolderPicker() {
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

    func scanFolder(url: URL) async {
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

    func handleDrop(providers: [NSItemProvider]) {
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

    func checkAndProceed(urls: [URL]) async {
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

    func performImport() async {
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

                // 添加标签（需要 Tag 关联逻辑）
                if !selectedTag.isEmpty, let context = viewModel.store?.modelContext {
                    let tagName = selectedTag
                    let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
                    let tag: Tag
                    if let existing = try? context.fetch(descriptor).first {
                        tag = existing
                    } else {
                        tag = Tag(name: tagName)
                        context.insert(tag)
                    }
                    wallpaper.tags.append(tag)
                    tag.wallpapers.append(wallpaper)
                }

                if let store = viewModel.store {
                    try? store.add(wallpaper)
                } else {
                    viewModel.wallpapers.append(wallpaper)
                }
            }

            viewModel.loadWallpapers()
            viewModel.isImporting = false

            toast = ToastConfig(message: "已导入 \(imported.count) 个壁纸", type: .success)
            dismiss()
        } catch {
            viewModel.isImporting = false
            toast = ToastConfig(message: "导入失败: \(error.localizedDescription)", type: .error)
        }
    }
}