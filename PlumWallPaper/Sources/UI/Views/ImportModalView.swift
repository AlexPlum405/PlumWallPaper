import SwiftUI

struct ImportModalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isDragging = false
    @State private var showDuplicateConfirm = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("导入新壁纸")
                    .font(Theme.Fonts.display(size: 28))
                    .italic()
                Text("支持 MP4, MOV, HEIC 格式作品")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            if !viewModel.isImporting {
                // 拖拽导入区
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isDragging ? Theme.accent : Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .background(isDragging ? Theme.accent.opacity(0.05) : Color.white.opacity(0.02))
                    
                    VStack(spacing: 20) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 48))
                            .foregroundColor(isDragging ? Theme.accent : .white.opacity(0.2))
                        
                        VStack(spacing: 4) {
                            Text("将文件拖拽至此")
                                .font(.system(size: 16, weight: .bold))
                            Text("或者点击下方按钮手动选择")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .frame(height: 300)
                .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                    handleDrop(providers)
                    return true
                }
                
                // 按钮区
                HStack(spacing: 16) {
                    Button(action: selectFiles) {
                        Label("选择文件", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.glassHeavy)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: selectFolder) {
                        Label("导入文件夹", systemImage: "folder.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.glassHeavy)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button("取消") { dismiss() }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 13))
            } else {
                // 导入进度区
                VStack(spacing: 40) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.05), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.importProgress)
                            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(viewModel.importProgress * 100))%")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                    }
                    
                    VStack(spacing: 12) {
                        Text("正在处理资源...")
                            .font(.system(size: 16, weight: .bold))
                        Text(viewModel.currentImportFileName)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    
                    Text("请勿关闭应用，正在生成高性能预览分片")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent.opacity(0.6))
                }
                .frame(height: 300)
            }
        }
        .padding(48)
        .frame(width: 500)
        .background(Theme.bg)
        .confirmationDialog(
            "检测到 \(viewModel.pendingDuplicates.count) 个重复文件",
            isPresented: $showDuplicateConfirm
        ) {
            Button("仍要导入（自动加 (2) 后缀）") {
                Task {
                    await viewModel.confirmDuplicates(context: modelContext)
                    dismiss()
                }
            }
            Button("跳过重复", role: .cancel) {
                viewModel.cancelDuplicates()
                dismiss()
            }
        } message: {
            Text("库中已有相同文件。要不要仍然导入它们？")
        }
    }
    
    // --- 逻辑 ---

    func handleDrop(_ providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await loadURL(from: provider) {
                    urls.append(url)
                }
            }
            await runImport(urls: urls)
        }
    }

    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie, .image]
        if panel.runModal() == .OK {
            Task { await runImport(urls: panel.urls) }
        }
    }

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            guard let folderURL = panel.urls.first else { return }
            let urls = collectMediaFiles(in: folderURL)
            Task { await runImport(urls: urls) }
        }
    }

    private func runImport(urls: [URL]) async {
        await viewModel.importFiles(urls: urls, context: modelContext)
        if !viewModel.pendingDuplicates.isEmpty {
            showDuplicateConfirm = true
        } else if !viewModel.isImporting {
            dismiss()
        }
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func collectMediaFiles(in folder: URL) -> [URL] {
        let exts = ["mp4", "mov", "m4v", "heic", "heif"]
        guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else {
            return []
        }
        var urls: [URL] = []
        for case let fileURL as URL in enumerator {
            if exts.contains(fileURL.pathExtension.lowercased()) {
                urls.append(fileURL)
            }
        }
        return urls
    }
}
