import Testing
@testable import NetCheckCore

@Suite("SpeedTestService")
struct SpeedTestServiceTests {

    @Test func progressModelInit() {
        let p = SpeedTestProgress(downloadMbps: 100.5, uploadMbps: 50.2, rpm: 1500, latencyMs: 20, isComplete: false)
        #expect(p.downloadMbps == 100.5)
        #expect(p.uploadMbps == 50.2)
        #expect(p.rpm == 1500)
        #expect(!p.isComplete)
    }
}
