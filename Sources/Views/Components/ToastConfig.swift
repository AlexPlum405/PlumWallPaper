import Foundation
import SwiftUI

// MARK: - Toast 配置
struct ToastConfig: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastView.ToastType
    let duration: Double

    init(message: String, type: ToastView.ToastType = .info, duration: Double = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

// MARK: - View Extension
extension View {
    func toast(_ toast: Binding<ToastConfig?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
