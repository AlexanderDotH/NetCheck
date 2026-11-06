import SwiftUI
import NetCheckCore

struct HopListView: View {
    let hops: [TracerouteHop]
    let highlightedHopID: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(hops) { hop in
                        Button { onSelect(hop.id) } label: {
                            HopChip(hop: hop, isHighlighted: hop.id == highlightedHopID)
                        }
                        .buttonStyle(.plain)
                        .id(hop.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
            // Garde le hop mis en avant (ou le dernier reçu) visible
            .onChange(of: highlightedHopID) {
                guard let highlightedHopID else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(highlightedHopID, anchor: .center)
                }
            }
        }
    }
}

struct HopChip: View {
    @Environment(\.locale) private var locale
    let hop: TracerouteHop
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(verbatim: "\(hop.id + 1)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(isHighlighted ? Color.yellow : Color.secondary)
                Text(hop.isTimeout ? "* * *" : (hop.ip ?? "?"))
                    .font(.caption.monospacedDigit().weight(isHighlighted ? .semibold : .regular))
                    .lineLimit(1)
            }
            Text(place ?? " ")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(hop.latencyMs.map { String(format: "%.0f ms", locale: locale, $0) } ?? "—")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isHighlighted ? .primary : .secondary)
        }
        .frame(minWidth: 96, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .glassEffect(isHighlighted ? .regular.tint(.yellow.opacity(0.35)) : .regular,
                     in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(isHighlighted ? Color.yellow : Color.clear, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }

    private var place: String? {
        let country = hop.country.map { locale.localizedString(forRegionCode: $0) ?? $0 }
        let parts = [hop.city, country].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
