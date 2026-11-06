import SwiftUI
import NetCheckCore

struct HopListView: View {
    let hops: [TracerouteHop]
    let activeIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(hops.enumerated()), id: \.element.id) { idx, hop in
                    HopChip(hop: hop, isActive: idx == activeIndex)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HopChip: View {
    @Environment(\.locale) private var locale
    let hop: TracerouteHop
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hop.isTimeout ? "* * *" : (hop.ip ?? "?"))
                .font(.caption.monospacedDigit().weight(isActive ? .semibold : .regular))
            if let city = hop.city {
                Text(city)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let ms = hop.latencyMs {
                Text(String(format: "%.0f ms", locale: locale, ms))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isActive ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.yellow.opacity(0.2) : Color.primary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(isActive ? Color.yellow : Color.clear, lineWidth: 1))
    }
}
