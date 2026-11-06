import Foundation
import ServiceManagement

@Observable
final class AppSettings: @unchecked Sendable {
    static let shared = AppSettings()
    private static let selectedLanguageKey = "selectedLanguage"

    @ObservationIgnored private let defaults: UserDefaults

    var selectedLanguage: AppLanguage {
        didSet { defaults.set(selectedLanguage.rawValue, forKey: Self.selectedLanguageKey) }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch { print("SMAppService error: \(error)") }
        }
    }

    var geigerSoundEnabled: Bool {
        get { defaults.object(forKey: "geigerSoundEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "geigerSoundEnabled") }
    }

    var tracerouteDestination: String {
        get { defaults.string(forKey: "tracerouteDestination") ?? "8.8.8.8" }
        set { defaults.set(newValue, forKey: "tracerouteDestination") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedLanguage = defaults.string(forKey: Self.selectedLanguageKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
    }
}
