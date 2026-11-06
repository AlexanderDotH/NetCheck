import MapKit
import NetCheckCore

/// One place on the route. Consecutive hops that geolocate to the same area
/// (typically several routers in one data centre) share a single stop.
struct RouteStop: Identifiable {
    let hopIDs: [Int]
    let coordinate: CLLocationCoordinate2D
    let city: String?
    let country: String?

    var id: Int { hopIDs[0] }

    /// 1-based hop numbers as shown in the hop list, e.g. "4" or "7–13".
    var hopLabel: String {
        let first = hopIDs[0] + 1
        let last = hopIDs[hopIDs.count - 1] + 1
        return first == last ? "\(first)" : "\(first)–\(last)"
    }
}

enum TracerouteRoute {
    /// Hops closer than this are drawn as one stop.
    static let mergeDistanceMeters: CLLocationDistance = 25_000
    /// Smallest area the camera shows, so a route inside one city still shows the country.
    static let minimumSpanMeters: Double = 800_000

    static func stops(for hops: [TracerouteHop]) -> [RouteStop] {
        var stops: [RouteStop] = []
        for hop in hops {
            guard let lat = hop.latitude, let lon = hop.longitude else { continue }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            if let last = stops.last, distance(last.coordinate, coordinate) < mergeDistanceMeters {
                stops[stops.count - 1] = RouteStop(
                    hopIDs: last.hopIDs + [hop.id], coordinate: last.coordinate,
                    city: last.city ?? hop.city, country: last.country ?? hop.country
                )
            } else {
                stops.append(RouteStop(hopIDs: [hop.id], coordinate: coordinate,
                                       city: hop.city, country: hop.country))
            }
        }
        return stops
    }

    /// Map area that shows every coordinate with a margin around the route. The map view
    /// fits it into its safe area, which already excludes the controls drawn over the map.
    static func mapRect(fitting coordinates: [CLLocationCoordinate2D]) -> MKMapRect? {
        guard !coordinates.isEmpty else { return nil }
        let points = coordinates.map(MKMapPoint.init)
        let minX = points.map(\.x).min()!, maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!, maxY = points.map(\.y).max()!

        let center = MKMapPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let minimumSide = minimumSpanMeters * MKMapPointsPerMeterAtLatitude(center.coordinate.latitude)
        let width = max(maxX - minX, minimumSide) * 1.4
        let height = max(maxY - minY, minimumSide) * 1.4

        let rect = MKMapRect(x: center.x - width / 2, y: center.y - height / 2,
                             width: width, height: height)
        return rect.intersection(.world).isNull ? .world : rect
    }

    private static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}
