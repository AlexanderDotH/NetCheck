import SwiftUI
import NetCheckCore
import NetCheckUI

struct WiFiFinderView: View {
    @Environment(\.locale) private var locale
    @State private var vm = WiFiFinderViewModel()

    var body: some View {
        FeatureWindowBackground(tintColor: vm.tintColor) {
            VStack(spacing: 18) {
                Text("Wi-Fi Finder", tableName: "Features")
                    .font(.title2.bold())
                    .padding(.top, 4)

                ZStack {
                    ConcentricWaves(color: vm.tintColor, duration: vm.waveDuration, strength: vm.signal.strength)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(vm.tintColor)
                        .symbolEffect(.pulse)
                }

                GlassPanelView {
                    HStack(spacing: 12) {
                        SignalBars(strength: vm.signal.strength, color: vm.tintColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "\(vm.signal.rssi) dBm")
                                .font(.title3.monospacedDigit().bold())
                            Text(vm.signal.localizedLabel(locale: locale))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let ssid = vm.signal.ssid {
                            Text(ssid)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Conseil contextuel selon la force du signal
                HStack(spacing: 6) {
                    Image(systemName: vm.moveTipIcon)
                        .font(.caption)
                        .foregroundStyle(vm.tintColor)
                    Text(vm.moveTip(locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.4), value: vm.signal.strength)

                GlassPanelView {
                    HStack {
                        Image(systemName: vm.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundStyle(vm.tintColor)
                        Text(vm.soundEnabled
                            ? AppLocalization.string("Listen to the clicks and move around to find the strongest signal", table: "Features", locale: locale)
                            : AppLocalization.string("Enable sound for Geiger mode", table: "Features", locale: locale))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Toggle(isOn: $vm.soundEnabled) {
                            Text("Geiger sound", tableName: "Features")
                        }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

struct SignalBars: View {
    let strength: Double
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Double(i) / 3 <= strength ? color : color.opacity(0.2))
                    .frame(width: 5, height: CGFloat(8 + i * 5))
            }
        }
    }
}
