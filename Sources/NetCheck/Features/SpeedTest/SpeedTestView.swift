import SwiftUI
import NetCheckUI

struct SpeedTestView: View {
    @Environment(\.locale) private var locale
    @State private var vm = SpeedTestViewModel()

    var body: some View {
        FeatureWindowBackground(tintColor: .blue) {
            VStack(spacing: 24) {
                Text("Speed Test", tableName: "Features")
                    .font(.title2.bold())
                    .padding(.top, 4)

                HStack(spacing: 32) {
                    SpeedGauge(value: vm.download, maxValue: 1000,
                               label: AppLocalization.string("Download", table: "Features", locale: locale), icon: "arrow.down", color: .blue,
                               isActive: vm.isRunning)
                    SpeedGauge(value: vm.upload, maxValue: 500,
                               label: AppLocalization.string("Upload", table: "Features", locale: locale), icon: "arrow.up", color: .purple,
                               isActive: vm.isRunning)
                }

                GlassPanelView {
                    HStack(spacing: 0) {
                        // RPM
                        VStack(spacing: 4) {
                            Text(verbatim: vm.rpm > 0 ? "\(vm.rpm)" : "—")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                            Text(vm.rpm > 0
                                ? AppLocalization.string("RPM — \(vm.rpmLabel(locale: locale))", table: "Features", locale: locale)
                                : "RPM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Responsiveness per minute", tableName: "Features")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 52)

                        // Latence
                        VStack(spacing: 4) {
                            Text(vm.latencyMs > 0 ? String(format: "%.0f ms", locale: locale, vm.latencyMs) : "—")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                            Text(vm.latencyMs > 0
                                ? AppLocalization.string("Latency — \(vm.latencyLabel(locale: locale))", table: "Features", locale: locale)
                                : AppLocalization.string("Latency", table: "Features", locale: locale))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Round-trip time (RTT)", tableName: "Features")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)

                Button {
                    vm.start()
                } label: {
                    Text(vm.isRunning
                        ? AppLocalization.string("Testing…", table: "Features", locale: locale)
                        : AppLocalization.string("Start", table: "Features", locale: locale))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(vm.isRunning)

                Spacer()
            }
        }
    }
}
