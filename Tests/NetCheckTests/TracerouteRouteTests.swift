import MapKit
import Testing
import NetCheckCore
@testable import NetCheck

@Suite("Traceroute route")
struct TracerouteRouteTests {
    private func hop(_ id: Int, _ city: String?, _ lat: Double?, _ lon: Double?, country: String? = "DE") -> TracerouteHop {
        TracerouteHop(id: id, ip: lat == nil ? nil : "192.0.2.\(id)", latencyMs: Double(id),
                      city: city, country: lat == nil ? nil : country,
                      latitude: lat, longitude: lon, asn: nil)
    }

    @Test func consecutiveHopsInOneCityShareAStop() {
        let hops = [
            hop(0, nil, nil, nil),                     // private router, no location
            hop(1, "Frankfurt", 50.11, 8.68),
            hop(2, nil, nil, nil),                     // timeout between two Frankfurt hops
            hop(3, "Frankfurt", 50.12, 8.70),
            hop(4, "Munich", 48.14, 11.58),
            hop(5, "Munich", 48.14, 11.58),
            hop(6, "Mountain View", 37.39, -122.08, country: "US"),
        ]
        let stops = TracerouteRoute.stops(for: hops)

        #expect(stops.map(\.city) == ["Frankfurt", "Munich", "Mountain View"])
        #expect(stops.map(\.hopIDs) == [[1, 3], [4, 5], [6]])
        #expect(stops.map(\.hopLabel) == ["2–4", "5–6", "7"])
    }

    @Test func revisitedPlacesStayInRouteOrder() {
        let hops = [hop(0, "Munich", 48.14, 11.58), hop(1, "Vienna", 48.21, 16.37), hop(2, "Munich", 48.14, 11.58)]
        #expect(TracerouteRoute.stops(for: hops).map(\.hopIDs) == [[0], [1], [2]])
    }

    @Test func noLocatedHopsMeansNoRouteToFrame() {
        #expect(TracerouteRoute.stops(for: [hop(0, nil, nil, nil)]).isEmpty)
        #expect(TracerouteRoute.mapRect(fitting: []) == nil)
    }

    @Test func frameContainsTheWholeRouteWithAMargin() throws {
        let munich = CLLocationCoordinate2D(latitude: 48.14, longitude: 11.58)
        let mountainView = CLLocationCoordinate2D(latitude: 37.39, longitude: -122.08)
        let rect = try #require(TracerouteRoute.mapRect(fitting: [munich, mountainView]))

        #expect(rect.contains(MKMapPoint(munich)))
        #expect(rect.contains(MKMapPoint(mountainView)))
        // The route is centred with room on every side.
        let points = [MKMapPoint(munich), MKMapPoint(mountainView)]
        let routeWidth = abs(points[0].x - points[1].x)
        #expect(rect.size.width > routeWidth)
        #expect(abs(rect.midX - (points[0].x + points[1].x) / 2) < 1)
        #expect(abs(rect.midY - (points[0].y + points[1].y) / 2) < 1)
    }

    @Test func singleCityRouteStillShowsTheSurroundingCountry() throws {
        let munich = CLLocationCoordinate2D(latitude: 48.14, longitude: 11.58)
        let rect = try #require(TracerouteRoute.mapRect(fitting: [munich]))
        let widthMeters = rect.size.width / MKMapPointsPerMeterAtLatitude(munich.latitude)
        #expect(widthMeters >= TracerouteRoute.minimumSpanMeters)
        #expect(rect.contains(MKMapPoint(munich)))
    }

    @MainActor @Test func selectingAHopTogglesTheHighlight() throws {
        let suiteName = "TracerouteRouteTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let vm = TracerouteViewModel(settings: AppSettings(defaults: defaults))

        vm.select(hopID: 3)
        #expect(vm.selectedHopID == 3)
        vm.select(hopID: 3)
        #expect(vm.selectedHopID == nil)
        vm.select(hopID: 2)
        vm.clearSelection()
        #expect(vm.selectedHopID == nil)
        #expect(vm.focusedHop == nil)
    }
}
