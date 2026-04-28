import SwiftUI

struct AdjustGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(.white.opacity(0.3))
            content()
        }
    }
}

struct AdjustRow: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            Slider(value: $value, in: range)
                .tint(Color.white.opacity(0.6))
        }
    }
}
