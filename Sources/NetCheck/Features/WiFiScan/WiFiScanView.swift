import SwiftUI
import AppKit
import NetCheckCore
import NetCheckUI

struct WiFiScanView: View {
    @Environment(\.locale) private var locale
    @State private var vm = WiFiScanViewModel()
    @State private var groupBySSID = false

    var body: some View {
        FeatureWindowBackground(tintColor: .teal) {
            VStack(spacing: 16) {
                HStack {
                    Text("Wi-Fi Diagnostics", tableName: "Features")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        vm.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(vm.isScanning ? 360 : 0))
                            .animation(vm.isScanning ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: vm.isScanning)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isScanning)
                    .accessibilityLabel(Text("Refresh networks", tableName: "Features"))
                }
                .padding(.horizontal)
                .padding(.top, 4)

                summaryLine
                    .padding(.horizontal)

                Toggle(isOn: $groupBySSID) {
                    Text("Group networks with the same name", tableName: "Features")
                }
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                if !vm.locationAuthorized {
                    authorizationBanner
                        .padding(.horizontal)
                }

                if let error = vm.errorMessage(locale: locale) {
                    GlassPanelView {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        if groupBySSID {
                            ForEach(vm.groupedNetworks) { group in
                                NetworkGroupRow(group: group, congestion: vm.congestion)
                            }
                        } else {
                            ForEach(vm.networks) { network in
                                NetworkRow(network: network, congestion: vm.congestion(for: network))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }

    private var summaryLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi")
                .foregroundStyle(.teal)
            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var summaryText: String {
        let count = vm.networks.count
        guard count > 0 else {
            return vm.isScanning
                ? AppLocalization.string("Searching for networks…", table: "Features", locale: locale)
                : AppLocalization.string("No networks detected", table: "Features", locale: locale)
        }
        var parts = [AppLocalization.string("\(count) networks detected", table: "Features", locale: locale)]
        if vm.weakSecurityCount > 0 {
            parts.append(AppLocalization.string("\(vm.weakSecurityCount) unsecured", table: "Features", locale: locale))
        }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var authorizationBanner: some View {
        GlassPanelView {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: vm.locationDenied ? "location.slash.fill" : "location.fill")
                    .foregroundStyle(vm.locationDenied ? .red : .orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.locationDenied
                        ? AppLocalization.string("Location access denied — access points are grouped", table: "Features", locale: locale)
                        : AppLocalization.string("Location access is needed to identify each access point", table: "Features", locale: locale))
                        .font(.caption.weight(.semibold))
                    Text(vm.locationDenied
                        ? AppLocalization.string("Without this permission, macOS hides each access point’s name and address (BSSID). Access points with the same name may appear as a single network.", table: "Features", locale: locale)
                        : AppLocalization.string("macOS requires location access to reveal Wi-Fi access point addresses (BSSIDs) and distinguish access points with the same name. Allow access in the system prompt.", table: "Features", locale: locale))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if vm.locationDenied {
                        Button {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Text("Open System Settings…", tableName: "Features")
                        }
                        .buttonStyle(.link)
                        .font(.caption2)
                    }
                }
                Spacer()
            }
        }
    }
}

private struct NetworkRow: View {
    @Environment(\.locale) private var locale
    let network: WiFiNetworkInfo
    let congestion: Int

    private var tintColor: Color {
        let strength = network.strength
        if strength > 0.6 { return .teal }
        if strength > 0.3 { return .orange }
        return .red
    }

    private var snrColor: Color {
        guard let snr = network.snr else { return .secondary }
        if snr >= 25 { return .green }
        if snr >= 15 { return .orange }
        return .red
    }

    var body: some View {
        GlassPanelView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    SignalBars(strength: network.strength, color: tintColor)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(network.localizedDisplayName(locale: locale))
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            if network.isCurrent {
                                Tag(text: AppLocalization.string("Connected", table: "Features", locale: locale), color: .teal)
                            }
                            if network.isAdHoc {
                                Tag(text: AppLocalization.string("Ad hoc", table: "Features", locale: locale), color: .purple)
                            }
                        }
                        if let bssid = network.bssid {
                            Text(bssid)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(verbatim: "\(network.rssi) dBm")
                            .font(.caption.monospacedDigit().weight(.medium))
                        if let snr = network.snr {
                            Text(verbatim: "SNR \(snr) dB")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(snrColor)
                        }
                    }
                }

                HStack(spacing: 10) {
                    if let channel = network.channelNumber {
                        Label {
                            Text(AppLocalization.string("Channel \(channel)", table: "Features", locale: locale)
                                 + (network.localizedBand(locale: locale).map { " · \($0)" } ?? "")
                                 + (network.channelWidth.map { " · \($0)" } ?? ""))
                        } icon: {
                            Image(systemName: "number")
                        }
                    }
                    if let phy = network.phyMode {
                        Label(phy, systemImage: "waveform")
                    }
                    Spacer()
                    SecurityBadge(security: network.security)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if congestion > 1 {
                    Label {
                        Text(AppLocalization.string("\(congestion) networks on this channel — possible interference", table: "Features", locale: locale))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct NetworkGroupRow: View {
    @Environment(\.locale) private var locale
    let group: WiFiScanViewModel.NetworkGroup
    let congestion: (WiFiNetworkInfo) -> Int
    @State private var expanded = false

    private var strongest: WiFiNetworkInfo { group.networks[0] }   // déjà trié par rssi desc

    private var tintColor: Color {
        let strength = strongest.strength
        if strength > 0.6 { return .teal }
        if strength > 0.3 { return .orange }
        return .red
    }

    var body: some View {
        // Un seul BSSID pour ce SSID : pas besoin de repli/disclosure, la ligne simple suffit
        if group.networks.count == 1 {
            NetworkRow(network: strongest, congestion: congestion(strongest))
        } else {
            GlassPanelView {
                DisclosureGroup(isExpanded: $expanded) {
                    VStack(spacing: 8) {
                        ForEach(group.networks) { network in
                            NetworkRow(network: network, congestion: congestion(network))
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    HStack(spacing: 10) {
                        SignalBars(strength: strongest.strength, color: tintColor)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(strongest.localizedDisplayName(locale: locale))
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                if group.networks.contains(where: \.isCurrent) {
                                    Tag(text: AppLocalization.string("Connected", table: "Features", locale: locale), color: .teal)
                                }
                                Tag(text: AppLocalization.string("\(group.networks.count) access points", table: "Features", locale: locale), color: .secondary)
                            }
                            Text(AppLocalization.string("Best signal \(strongest.rssi) dBm · \(strongest.localizedLabel(locale: locale))", table: "Features", locale: locale))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
    }
}

private struct SecurityBadge: View {
    @Environment(\.locale) private var locale
    let security: WiFiSecurityLevel

    private var color: Color {
        switch security {
        case .wpa3:            return .green
        case .wpa2:            return .blue
        case .wpa, .owe:       return .orange
        case .wep, .open:      return .red
        case .unknown:         return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            if security.isWeak {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
            }
            Text(security.localizedLabel(locale: locale))
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12), in: Capsule())
    }
}
