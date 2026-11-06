import Foundation
import Observation
import Testing
@testable import NetCheck

@Suite("Language settings")
struct LanguageSettingsTests {
    @Test func explicitSelectionsIgnoreSystemPreference() {
        #expect(AppLanguage.english.resolvedLocale(preferredLanguages: ["de-DE"]).language.languageCode?.identifier == "en")
        #expect(AppLanguage.german.resolvedLocale(preferredLanguages: ["fr-FR"]).language.languageCode?.identifier == "de")
        #expect(AppLanguage.french.resolvedLocale(preferredLanguages: ["en-US"]).language.languageCode?.identifier == "fr")
    }

    @Test func systemSelectionUsesFirstSupportedPreferredLanguage() {
        let locale = AppLanguage.system.resolvedLocale(preferredLanguages: ["ja-JP", "de-AT", "fr-FR"])

        #expect(locale.language.languageCode?.identifier == "de")
        #expect(locale.region?.identifier == "AT")
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: ["fr-CA", "de-DE"]).language.languageCode?.identifier == "fr")
    }

    @Test func unsupportedOrEmptySystemPreferencesFallBackToEnglish() {
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: ["ja-JP", "es-ES"]).language.languageCode?.identifier == "en")
        #expect(AppLanguage.system.resolvedLocale(preferredLanguages: []).language.languageCode?.identifier == "en")
    }

    @Test func newSettingsFollowSystemDefault() {
        withDefaults { defaults in
            #expect(AppSettings(defaults: defaults).selectedLanguage == .system)
        }
    }

    @Test func unrecognizedStoredLanguageFallsBackToSystemDefault() {
        withDefaults { defaults in
            defaults.set("unsupported-language", forKey: "selectedLanguage")
            #expect(AppSettings(defaults: defaults).selectedLanguage == .system)
        }
    }

    @Test(arguments: [AppLanguage.system, .english, .german, .french])
    func selectedLanguagePersistsAcrossSettingsInstances(language: AppLanguage) {
        withDefaults { defaults in
            let settings = AppSettings(defaults: defaults)
            settings.selectedLanguage = language

            #expect(AppSettings(defaults: defaults).selectedLanguage == language)
        }
    }

    @Test func languageSelectionEmitsObservationChanges() {
        withDefaults { defaults in
            let settings = AppSettings(defaults: defaults)
            let change = ObservationChange()
            withObservationTracking {
                _ = settings.selectedLanguage
            } onChange: {
                change.markChanged()
            }

            settings.selectedLanguage = .german

            #expect(change.hasChanged)
        }
    }

    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "NetCheckTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}

private final class ObservationChange: @unchecked Sendable {
    private let lock = NSLock()
    private var changed = false

    var hasChanged: Bool { lock.withLock { changed } }

    func markChanged() {
        lock.withLock { changed = true }
    }
}
