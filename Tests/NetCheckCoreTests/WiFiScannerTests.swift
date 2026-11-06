import Foundation
import Testing
@testable import NetCheckCore

@Suite("WiFiScanner")
struct WiFiScannerTests {

    @Test func wifiSignalStrengthBounds() {
        let max = WiFiSignal(rssi: -30, ssid: nil)
        let min = WiFiSignal(rssi: -90, ssid: nil)
        let mid = WiFiSignal(rssi: -60, ssid: nil)
        #expect(max.strength == 1.0)
        #expect(min.strength == 0.0)
        #expect(mid.strength > 0.4 && mid.strength < 0.6)
    }

    @Test func scannerStartStop() async throws {
        let scanner = WiFiScanner()
        await scanner.start()
        try await Task.sleep(for: .milliseconds(300))
        await scanner.stop()
    }

    @Test func geigerIntervalFormula() {
        let strong = WiFiSignal(rssi: -30, ssid: nil)
        let weak_ = WiFiSignal(rssi: -90, ssid: nil)
        // Fort → 80ms, faible → 2000ms
        let strongInterval = 80 + Int((1 - strong.strength) * 1920)
        let weakInterval = 80 + Int((1 - weak_.strength) * 1920)
        #expect(strongInterval == 80)
        #expect(weakInterval == 2000)
    }

    @Test func snrRequiresAMeasuredNoiseFloor() {
        func network(noise: Int?) -> WiFiNetworkInfo {
            WiFiNetworkInfo(id: "a", ssid: "Lab", bssid: nil, rssi: -40, noise: noise,
                            channelNumber: 36, band: nil, channelWidth: nil, phyMode: nil,
                            security: .wpa3, isAdHoc: false, isCurrent: false)
        }
        #expect(network(noise: -92).snr == 52)
        // CoreWLAN reports 0 when the noise floor was not measured
        #expect(network(noise: 0).snr == nil)
        #expect(network(noise: nil).snr == nil)
    }

    @Test(arguments: [("en", "2.4 GHz"), ("de", "2,4 GHz"), ("fr", "2,4 GHz")])
    func bandUsesTheLocaleDecimalSeparator(language: String, expected: String) {
        func network(band: String?) -> WiFiNetworkInfo {
            WiFiNetworkInfo(id: "a", ssid: "Lab", bssid: nil, rssi: -40, noise: -90,
                            channelNumber: 6, band: band, channelWidth: nil, phyMode: nil,
                            security: .wpa3, isAdHoc: false, isCurrent: false)
        }
        let locale = Locale(identifier: language)
        #expect(network(band: "2.4 GHz").localizedBand(locale: locale) == expected)
        #expect(network(band: "5 GHz").localizedBand(locale: locale) == "5 GHz")
        #expect(network(band: nil).localizedBand(locale: locale) == nil)
    }
}
