import SwiftUI
import NetCheckCore

struct StatusMenuView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "NetCheck")
                        .font(.headline)
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .glassEffect()

            Divider()

            Group {
                MenuRowButton(icon: "antenna.radiowaves.left.and.right", label: "Wi-Fi Finder") {
                    WindowManager.open(.wifiFinder)
                }
                MenuRowButton(icon: "wifi", label: "Wi-Fi Diagnostics") {
                    WindowManager.open(.wifiScan)
                }
                MenuRowButton(icon: "bolt.fill", label: "Speed Test") {
                    WindowManager.open(.speedTest)
                }
                MenuRowButton(icon: "map.fill", label: "Traceroute") {
                    WindowManager.open(.traceroute)
                }
                MenuRowButton(icon: "chart.bar.fill", label: "Usage") {
                    WindowManager.open(.usage)
                }
            }

            Divider()

            MenuRowButton(icon: "gearshape.fill", label: "Preferences") {
                WindowManager.open(.settings)
            }
            MenuRowButton(icon: "power", label: "Quit") {
                NSApp.terminate(nil)
            }
        }
        .frame(width: 300)
    }
}

struct MenuRowButton: View {
    let icon: String
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(label)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
