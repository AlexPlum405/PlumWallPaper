import SwiftUI
import UniformTypeIdentifiers

struct ImportModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var importProgress: Double = 0.0
    @State private var isImporting = false
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 32) {
            Text("导入新壁纸")
                .font(Theme.Fonts.display(size: 28))
                .italic()

            if !isImporting {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isTargeted ? Theme.accent : Color.white.opacity(0.1),
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                        .background(Color.white.opacity(0.02))

                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.4))
                        Text("将文件拖拽至此")
                            .font(.system(size: 16, weight: .bold))
                        Text("支持 MP4、MOV、HEIC")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .frame(height: 300)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { _ in
                    isImporting = true
                    simulate()
                    return true
                }

                Button("选择文件") {
                    isImporting = true
                    simulate()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.glassHeavy)
                .cornerRadius(12)
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 40) {
                    ProgressView(value: importProgress)
                        .tint(Theme.accent)
                        .padding()
                    Text("正在生成预览... \(Int(importProgress * 100))%")
                        .font(.system(size: 13, design: .monospaced))
                }
                .frame(height: 300)
            }
        }
        .padding(48)
        .frame(width: 500)
        .background(Theme.bg)
    }

    private func simulate() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            importProgress += 0.01
            if importProgress >= 1.0 {
                timer.invalidate()
                dismiss()
            }
        }
    }
}
