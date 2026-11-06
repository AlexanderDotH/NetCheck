import Foundation
import Testing
@testable import NetCheck

@Suite("App localization")
struct FeatureLocalizationTests {
    @Test func appLabelsUseTheRequestedLanguage() {
        #expect(AppLocalization.string("Language", locale: Locale(identifier: "en")) == "Language")
        #expect(AppLocalization.string("Language", locale: Locale(identifier: "de")) == "Sprache")
        #expect(AppLocalization.string("Language", locale: Locale(identifier: "fr")) == "Langue")
        #expect(AppLocalization.string("Preferences", locale: Locale(identifier: "de")) == "Einstellungen")
    }

    @Test(arguments: ["en", "de", "fr"])
    func networkCountsUseCatalogPluralForms(language: String) {
        let expected = [
            "en": ["0 networks detected", "1 network detected", "2 networks detected"],
            "de": ["0 Netzwerke gefunden", "1 Netzwerk gefunden", "2 Netzwerke gefunden"],
            "fr": ["0 réseau détecté", "1 réseau détecté", "2 réseaux détectés"]
        ][language]!

        for count in 0...2 {
            let value = AppLocalization.string("\(count) networks detected", table: "Features", locale: Locale(identifier: language))
            #expect(value == expected[count])
        }
    }

    @Test(arguments: ["en", "de", "fr"])
    func accessPointCountsUseCatalogPluralForms(language: String) {
        let expected = [
            "en": ["0 access points", "1 access point", "2 access points"],
            "de": ["0 Zugangspunkte", "1 Zugangspunkt", "2 Zugangspunkte"],
            "fr": ["0 borne", "1 borne", "2 bornes"]
        ][language]!

        for count in 0...2 {
            let value = AppLocalization.string("\(count) access points", table: "Features", locale: Locale(identifier: language))
            #expect(value == expected[count])
        }
    }

    @Test(arguments: ["en", "de", "fr"])
    func unsecuredCountsUseCatalogPluralForms(language: String) {
        let expected = [
            "en": ["0 unsecured", "1 unsecured", "2 unsecured"],
            "de": ["0 ungesichert", "1 ungesichert", "2 ungesichert"],
            "fr": ["0 non sécurisé", "1 non sécurisé", "2 non sécurisés"]
        ][language]!

        for count in 0...2 {
            let value = AppLocalization.string("\(count) unsecured", table: "Features", locale: Locale(identifier: language))
            #expect(value == expected[count])
        }
    }

    @Test(arguments: ["en", "de", "fr"])
    func congestionCountsUseCatalogPluralForms(language: String) {
        let expected = [
            "en": [
                "0 networks on this channel — possible interference",
                "1 network on this channel — possible interference",
                "2 networks on this channel — possible interference"
            ],
            "de": [
                "0 Netzwerke auf diesem Kanal — mögliche Störungen",
                "1 Netzwerk auf diesem Kanal — mögliche Störungen",
                "2 Netzwerke auf diesem Kanal — mögliche Störungen"
            ],
            "fr": [
                "0 réseau sur ce canal — risque d’interférence",
                "1 réseau sur ce canal — risque d’interférence",
                "2 réseaux sur ce canal — risque d’interférence"
            ]
        ][language]!

        for count in 0...2 {
            let value = AppLocalization.string("\(count) networks on this channel — possible interference", table: "Features", locale: Locale(identifier: language))
            #expect(value == expected[count])
        }
    }

    @Test func regionalAndUnsupportedLocalesUseExpectedResources() {
        let count = 2
        #expect(AppLocalization.string("\(count) networks detected", table: "Features", locale: Locale(identifier: "de-AT")) == "2 Netzwerke gefunden")
        #expect(AppLocalization.string("\(count) networks detected", table: "Features", locale: Locale(identifier: "fr-CA")) == "2 réseaux détectés")
        #expect(AppLocalization.string("\(count) networks detected", table: "Features", locale: Locale(identifier: "ja-JP")) == "2 networks detected")
        let singularCount = 1
        #expect(AppLocalization.string("\(singularCount) networks detected", table: "Features", locale: Locale(identifier: "ja-JP")) == "1 network detected")
    }
}
