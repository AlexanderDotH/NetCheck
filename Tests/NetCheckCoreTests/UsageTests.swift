import Foundation
import Testing
@testable import NetCheckCore

@Suite("UsageQuality")
struct UsageTests {

    @Test func qualityLevelLabels() {
        #expect(QualityLevel.excellent.localizedLabel(locale: Locale(identifier: "fr")) == "Excellent")
        #expect(QualityLevel.poor.localizedLabel(locale: Locale(identifier: "fr")) == "Mauvais")
    }

    @Test func usageResultInit() {
        let r = UsageResult(profile: .mail, quality: .good, latencyMs: 80)
        #expect(r.profile == .mail)
        #expect(r.latencyMs == 80)
    }
}
