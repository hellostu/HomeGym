import SwiftUI

/// A compact labeled stat, shared by the This Week and Trends tabs.
struct StatTile: View {
    let title: String
    let value: String
    let symbol: String
    var caption: String? = nil
    var captionColor: Color = .secondary

    var body: some View {
        VStack(spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(value).font(.title2.weight(.semibold)).monospacedDigit()
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(captionColor)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.4)))
    }

    /// "2.4t" above a tonne, "840 kg" below.
    static func volumeText(_ kg: Double) -> String {
        kg >= 1000 ? String(format: "%.1ft", kg / 1000) : "\(Int(kg.rounded())) kg"
    }

    /// Green for growth, red for a drop, muted when flat.
    static func deltaColor(_ change: Double) -> Color {
        change > 0 ? .green : change < 0 ? .red : .secondary
    }
}
