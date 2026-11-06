import SwiftUI
import NetCheckCore

public struct StatusBadge: View {
    @Environment(\.locale) private var locale
    public let quality: QualityLevel

    public init(quality: QualityLevel) { self.quality = quality }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(quality.localizedLabel(locale: locale))
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch quality {
        case .excellent: return .green
        case .good:      return .blue
        case .fair:      return .orange
        case .poor:      return .red
        }
    }
}
