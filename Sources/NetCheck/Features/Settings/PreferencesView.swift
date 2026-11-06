import SwiftUI
import Sparkle

struct PreferencesView: View {
    @State private var settings: AppSettings
    private let updater = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
    )

    init(settings: AppSettings = .shared) {
        self._settings = State(initialValue: settings)
    }

    var body: some View {
        Form {
            Section("General") {
                Picker("Language", selection: $settings.selectedLanguage) {
                    Text("System default").tag(AppLanguage.system)
                    ForEach(AppLanguage.allCases.filter { $0 != .system }) { language in
                        Text(verbatim: language.nativeName ?? language.rawValue).tag(language)
                    }
                }
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Wi-Fi Geiger sound", isOn: $settings.geigerSoundEnabled)
            }

            Section("Traceroute") {
                TextField("Destination", text: $settings.tracerouteDestination)
                    .textFieldStyle(.roundedBorder)
                Text("IP address or hostname (default: 8.8.8.8)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("About") {
                HStack {
                    Text(verbatim: "NetCheck")
                        .font(.headline)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
                Link(destination: URL(string: "https://github.com/vincentlauriat/NetCheck")!) {
                    Text(verbatim: "GitHub")
                }
                Button("Check for Updates…") {
                    updater.updater.checkForUpdates()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 520)
    }
}
