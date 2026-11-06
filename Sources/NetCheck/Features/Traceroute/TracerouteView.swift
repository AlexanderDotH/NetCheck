import SwiftUI
import NetCheckCore
import NetCheckUI

struct TracerouteView: View {
    @Environment(\.locale) private var locale
    @State private var vm: TracerouteViewModel
    @State private var overlayHeight: CGFloat = 0

    init(viewModel: TracerouteViewModel? = nil) {
        _vm = State(initialValue: viewModel ?? TracerouteViewModel())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GlobeMapView(stops: vm.stops,
                         highlightedHopID: vm.highlightedHopID,
                         isComplete: !vm.isRunning && !vm.stops.isEmpty,
                         bottomInset: overlayHeight,
                         cameraPosition: $vm.cameraPosition)

            VStack(spacing: 10) {
                if let hop = vm.focusedHop {
                    HopInfoBanner(hop: hop, isSelected: vm.selectedHopID != nil) {
                        vm.clearSelection()
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !vm.hops.isEmpty {
                    HopListView(hops: vm.hops, highlightedHopID: vm.highlightedHopID) { id in
                        vm.select(hopID: id)
                    }
                    .transition(.opacity)
                }

                controlBar
                    .padding(.horizontal)
                    .padding(.bottom, 14)
            }
            .animation(.easeInOut(duration: 0.25), value: vm.focusedHop?.id)
            .animation(.easeInOut(duration: 0.25), value: vm.hops.isEmpty)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { overlayHeight = $0 }
        }
        .frame(minWidth: 560, minHeight: 440)
        .onDisappear { vm.stop() }
    }

    // Saisie destination + actions regroupées dans une seule barre
    private var controlBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.secondary)
            TextField(text: $vm.destination) {
                Text("IP address or hostname", tableName: "Features")
            }
            .textFieldStyle(.plain)
            .font(.body.monospaced())
            .disabled(vm.isRunning)
            .onSubmit { if !vm.isRunning { vm.start() } }

            if vm.isRunning {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(Text("Tracing route…", tableName: "Features"))
            }

            Button { vm.showFullRoute() } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .buttonStyle(.borderless)
            .disabled(vm.stops.isEmpty)
            .help(Text("Show entire route", tableName: "Features"))
            .accessibilityLabel(Text("Show entire route", tableName: "Features"))

            Button { vm.start() } label: {
                Text("Trace", tableName: "Features")
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isRunning || vm.destination.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .glassEffect(in: Capsule())
    }
}

private struct HopInfoBanner: View {
    @Environment(\.locale) private var locale
    let hop: TracerouteHop
    let isSelected: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(AppLocalization.string("Hop \(hop.id + 1) · \(hop.city ?? hop.ip ?? "?")", table: "Features", locale: locale))
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let ms = hop.latencyMs {
                Text(String(format: "%.0f ms", locale: locale, ms))
                    .font(.callout.monospacedDigit().bold())
            }
            if isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(Text("Clear selection", tableName: "Features"))
                .accessibilityLabel(Text("Clear selection", tableName: "Features"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .glassEffect(in: RoundedRectangle(cornerRadius: 14))
    }

    // IP, pays en toutes lettres et opérateur (AS)
    private var subtitle: String? {
        let country = hop.country.map { locale.localizedString(forRegionCode: $0) ?? $0 }
        let ip = hop.city != nil ? hop.ip : nil
        let parts = [ip, country, hop.asn].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
