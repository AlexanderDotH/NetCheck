import Testing
@testable import NetCheckCore

@Suite("Traceroute")
struct TracerouteTests {

    @Test func parseNormalHop() {
        let hop = TracerouteService.parse(line: "2  10.0.0.1  8.456 ms", id: 1)
        #expect(hop?.ip == "10.0.0.1")
        #expect(hop?.latencyMs == 8.456)
        #expect(hop?.id == 1)
    }

    @Test func parseTimeout() {
        let hop = TracerouteService.parse(line: "3  * * *", id: 2)
        #expect(hop != nil)
        #expect(hop?.ip == nil)
        #expect(hop?.isTimeout == true)
    }

    @Test func parseSingleProbeTimeout() {
        // NetCheck runs traceroute with -q 1, so a silent hop prints a single star
        let hop = TracerouteService.parse(line: " 4  *", id: 3)
        #expect(hop?.isTimeout == true)
        #expect(hop?.id == 3)
    }

    @Test func parseIPv6Hop() {
        let hop = TracerouteService.parse(line: " 1  2001:db8::1  1.204 ms", id: 0)
        #expect(hop?.ip == "2001:db8::1")
        #expect(hop?.latencyMs == 1.204)
    }

    @Test(arguments: [
        "1  traceroute: sendto: No route to host",
        "12",
        "2 ms",
        "5  !H  3.1 ms",
    ])
    func rejectsLinesWithoutAHopAddress(line: String) {
        #expect(TracerouteService.parse(line: line, id: 0) == nil)
    }

    @Test func parseHeader() {
        let hop = TracerouteService.parse(line: "traceroute to 8.8.8.8 (8.8.8.8), 64 hops max", id: 0)
        #expect(hop == nil)
    }

    @Test func hopIsTimeout() {
        let hop = TracerouteHop(id: 0, ip: nil, latencyMs: nil,
                                city: nil, country: nil, latitude: nil, longitude: nil, asn: nil)
        #expect(hop.isTimeout)
    }
}
