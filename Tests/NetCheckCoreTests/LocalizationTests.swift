import Foundation
import Testing
@testable import NetCheckCore

@Suite("Core localization")
struct LocalizationTests {
    @Test(arguments: ["en", "de", "fr"])
    func signalLabelsUseRequestedLocale(language: String) {
        let locale = Locale(identifier: language)
        let expected = [
            "en": ["Excellent", "Good", "Fair", "Weak"],
            "de": ["Ausgezeichnet", "Gut", "Mittel", "Schwach"],
            "fr": ["Excellent", "Bon", "Moyen", "Faible"]
        ][language]!

        for (rssi, label) in zip([-40, -60, -70, -90], expected) {
            let signal = WiFiSignal(rssi: rssi, ssid: "My Wi-Fi")
            let network = makeNetwork(ssid: "My Wi-Fi", rssi: rssi)

            #expect(signal.localizedLabel(locale: locale) == label)
            #expect(network.localizedLabel(locale: locale) == label)
            #expect(signal.ssid == "My Wi-Fi")
        }
    }

    @Test(arguments: ["en", "de", "fr"])
    func qualityLabelsUseRequestedLocale(language: String) {
        let expected = [
            "en": ["Excellent", "Good", "Fair", "Poor"],
            "de": ["Ausgezeichnet", "Gut", "Mittel", "Schlecht"],
            "fr": ["Excellent", "Bon", "Moyen", "Mauvais"]
        ][language]!
        let qualities: [QualityLevel] = [.excellent, .good, .fair, .poor]

        for (quality, label) in zip(qualities, expected) {
            #expect(quality.localizedLabel(locale: Locale(identifier: language)) == label)
        }
    }

    @Test(arguments: ["en", "de", "fr"])
    func networkDisplayNamesPreserveSSIDAndIdentity(language: String) {
        let locale = Locale(identifier: language)
        let hiddenName = [
            "en": "Hidden network",
            "de": "Verborgenes Netzwerk",
            "fr": "Réseau masqué"
        ][language]!
        let hidden = makeNetwork(ssid: nil)
        let empty = makeNetwork(ssid: "")
        let named = makeNetwork(ssid: "Réseau privé 🏠")

        #expect(hidden.localizedDisplayName(locale: locale) == hiddenName)
        #expect(empty.localizedDisplayName(locale: locale) == hiddenName)
        #expect(named.localizedDisplayName(locale: locale) == "Réseau privé 🏠")
        #expect(named.id == "00:11:22:33:44:55")
        #expect(named.bssid == "00:11:22:33:44:55")
        #expect(named.band == "5 GHz")
        #expect(named.channelWidth == "80 MHz")
        #expect(named.phyMode == "Wi-Fi 6")
    }

    @Test(arguments: ["en", "de", "fr"])
    func securityLabelsKeepProtocolNames(language: String) {
        let locale = Locale(identifier: language)
        let expected = [
            "en": ["Open", "Unknown"],
            "de": ["Offen", "Unbekannt"],
            "fr": ["Ouvert", "Inconnu"]
        ][language]!

        #expect(WiFiSecurityLevel.open.localizedLabel(locale: locale) == expected[0])
        #expect(WiFiSecurityLevel.unknown.localizedLabel(locale: locale) == expected[1])
        for (security, name) in zip(
            [WiFiSecurityLevel.owe, .wep, .wpa, .wpa2, .wpa3],
            ["OWE", "WEP", "WPA", "WPA2", "WPA3"]
        ) {
            #expect(security.localizedLabel(locale: locale) == name)
        }
    }

    @Test(arguments: ["en", "de", "fr"])
    func usageNamesDoNotChangeRawValues(language: String) {
        let locale = Locale(identifier: language)
        let expected = [
            "en": ["Video calls", "Online gaming"],
            "de": ["Videoanrufe", "Online-Spiele"],
            "fr": ["Vidéo conf", "Jeux en ligne"]
        ][language]!

        #expect(UsageProfile.videoConf.localizedName(locale: locale) == expected[0])
        #expect(UsageProfile.gaming.localizedName(locale: locale) == expected[1])
        #expect(UsageProfile.videoConf.rawValue == "Vidéo conf")
        #expect(UsageProfile.gaming.rawValue == "Jeux en ligne")
    }

    @Test(arguments: ["en", "de", "fr"])
    func scanErrorsTranslateOnlyAppOwnedText(language: String) {
        let locale = Locale(identifier: language)
        let expected = [
            "en": "Wi-Fi interface unavailable.",
            "de": "WLAN-Schnittstelle nicht verfügbar.",
            "fr": "Interface Wi-Fi indisponible."
        ][language]!

        #expect(WiFiNetworkScanner.ScanError.interfaceUnavailable.localizedDescription(locale: locale) == expected)
        #expect(WiFiNetworkScanner.ScanError.scanFailed("OS error 42").localizedDescription(locale: locale) == "OS error 42")
    }

    @Test func regionalLocalesResolveToSupportedTranslations() {
        #expect(QualityLevel.good.localizedLabel(locale: Locale(identifier: "de-AT")) == "Gut")
        #expect(QualityLevel.good.localizedLabel(locale: Locale(identifier: "fr-CA")) == "Bon")
        #expect(QualityLevel.good.localizedLabel(locale: Locale(identifier: "en-GB")) == "Good")
        #expect(QualityLevel.good.localizedLabel(locale: Locale(identifier: "ja-JP")) == "Good")
    }

    private func makeNetwork(ssid: String?, rssi: Int = -60) -> WiFiNetworkInfo {
        WiFiNetworkInfo(
            id: "00:11:22:33:44:55", ssid: ssid, bssid: "00:11:22:33:44:55",
            rssi: rssi, noise: -90, channelNumber: 36,
            band: "5 GHz", channelWidth: "80 MHz", phyMode: "Wi-Fi 6",
            security: .wpa2, isAdHoc: false, isCurrent: true
        )
    }
}
