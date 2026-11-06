import SwiftUI
import NetCheckUI

struct TracerouteView: View {
    @Environment(\.locale) private var locale
    @State private var vm = TracerouteViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            GlobeMapView(hops: vm.hops, activeIndex: vm.activeHopIndex,
                         cameraPosition: $vm.cameraPosition,
                         planeCoordinate: vm.planeCoordinate,
                         planeHeading: vm.planeHeading,
                         planePath: vm.planePath)

            VStack(spacing: 8) {
                // Infos hop actif — visible uniquement pendant l'animation
                if vm.isRunning, vm.activeHopIndex >= 0, vm.activeHopIndex < vm.hops.count {
                    let hop = vm.hops[vm.activeHopIndex]
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(AppLocalization.string("Hop \(hop.id + 1) · \(hop.city ?? hop.ip ?? "?")", table: "Features", locale: locale))
                                .font(.caption.weight(.semibold))
                            if let country = hop.country {
                                Text(country).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let ms = hop.latencyMs {
                            Text(String(format: "%.0f ms", locale: locale, ms))
                                .font(.caption.monospacedDigit().bold())
                        }
                        if let asn = hop.asn {
                            Text(asn.components(separatedBy: " ").first ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow, lineWidth: 1))
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                HopListView(hops: vm.hops, activeIndex: vm.activeHopIndex)
                    .padding(.vertical, 4)

                HStack(spacing: 12) {
                    Button { vm.start() } label: {
                        Text("Trace", tableName: "Features")
                    }
                        .disabled(vm.isRunning)
                    Button { vm.replay() } label: {
                        Text("Replay", tableName: "Features")
                    }
                        .disabled(vm.isRunning || vm.hops.isEmpty)
                }
                .buttonStyle(.borderedProminent)

                // Saisie destination — tout en bas
                GlassPanelView {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                        TextField(text: $vm.destination) {
                            Text("IP address or hostname", tableName: "Features")
                        }
                            .textFieldStyle(.plain)
                            .onSubmit { if !vm.isRunning { vm.start() } }
                        if vm.isRunning {
                            ProgressView()
                                .scaleEffect(0.7)
                                .accessibilityLabel(Text("Tracing route…", tableName: "Features"))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .animation(.easeInOut(duration: 0.25), value: vm.isRunning)
        }
        .frame(minWidth: 500, minHeight: 420)
    }
}
