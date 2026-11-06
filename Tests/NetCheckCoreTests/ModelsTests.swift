import Foundation
import Testing
@testable import NetCheckCore

@Suite("Models")
struct ModelsTests {

    @Test func wifiStrengthExcellent() {
        let s = WiFiSignal(rssi: -30, ssid: nil)
        #expect(s.strength == 1.0)
        #expect(s.localizedLabel(locale: Locale(identifier: "fr")) == "Excellent")
    }

    @Test func wifiStrengthFaible() {
        let s = WiFiSignal(rssi: -90, ssid: nil)
        #expect(s.strength == 0.0)
        #expect(s.localizedLabel(locale: Locale(identifier: "fr")) == "Faible")
    }

    @Test func connectivityColor() {
        #expect(ConnectivityStatus.connected(ping: 10, ssid: nil).color == .green)
        #expect(ConnectivityStatus.degraded(reason: .highLatency).color == .orange)
        #expect(ConnectivityStatus.offline.color == .red)
    }

    @Test func usageProfileCases() {
        #expect(UsageProfile.allCases.count == 4)
    }
}
