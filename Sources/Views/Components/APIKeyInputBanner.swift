import SwiftUI

struct APIKeyInputBanner: View {
    let service: APIKeyManager.Service
    var onKeySaved: (() -> Void)?

    @State private var keyInput = ""
    @State private var isSaved = false
    @ObservedObject private var keyManager = APIKeyManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(LiquidGlassColors.primaryPink)

                Text("需要 \(service.displayName) \(service.keyLabel)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LiquidGlassColors.textSecondary)

                Spacer()

                Button {
                    NSWorkspace.shared.open(service.registerURL)
                } label: {
                    Text("免费申请")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                TextField(service.keyPlaceholder, text: $keyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(LiquidGlassColors.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(LiquidGlassColors.surfaceBackground.opacity(0.6))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
                    }
                    .onSubmit { saveKey() }

                Button {
                    saveKey()
                } label: {
                    Text(isSaved ? "已保存" : "保存")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSaved ? .green : .white)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSaved ? Color.green.opacity(0.2) : LiquidGlassColors.primaryPink)
                        }
                }
                .buttonStyle(.plain)
                .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LiquidGlassColors.primaryPink.opacity(0.06))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(LiquidGlassColors.primaryPink.opacity(0.15), lineWidth: 0.5)
        }
        .onAppear {
            if let existing = keyManager.apiKey(for: service) {
                keyInput = existing
            }
        }
    }

    private func saveKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        keyManager.setAPIKey(trimmed, for: service)
        isSaved = true
        onKeySaved?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaved = false
        }
    }
}
