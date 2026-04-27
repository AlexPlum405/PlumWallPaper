import SwiftUI

struct ImportModalView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var isDragging = false
    @State private var importProgress: Double = 0.0
    @State private var isImporting = false
    @State private var currentFileName = ""
    
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
            
            if !isImporting {
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
                            .trim(from: 0, to: importProgress)
                            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(importProgress * 100))%")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                    }
                    
                    VStack(spacing: 12) {
                        Text("正在处理资源...")
                            .font(.system(size: 16, weight: .bold))
                        Text(currentFileName)
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
    }
    
    // --- 逻辑 ---
    
    func handleDrop(_ providers: [NSItemProvider]) {
        // TODO: 解析 URL 并调用后端导入
        simulateImport()
    }
    
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.video, .movie, .image]
        if panel.runModal() == .OK {
            simulateImport()
        }
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            simulateImport()
        }
    }
    
    func simulateImport() {
        isImporting = true
        currentFileName = "nebula_8k_vfx.mp4"
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                importProgress += 0.01
                if importProgress >= 1.0 {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
    }
}
