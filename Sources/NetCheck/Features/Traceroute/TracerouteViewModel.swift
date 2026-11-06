import SwiftUI
import MapKit
import NetCheckCore

@MainActor
@Observable
final class TracerouteViewModel {
    var destination: String
    private(set) var hops: [TracerouteHop] = []
    private(set) var stops: [RouteStop] = []
    private(set) var isRunning = false
    /// Hop chosen in the hop list; its stop is highlighted on the map.
    private(set) var selectedHopID: Int?
    var cameraPosition: MapCameraPosition = TracerouteViewModel.overview

    private let tracerouteService = TracerouteService()
    private let geoService = GeoIPService()
    private var traceTask: Task<Void, Never>?

    static let overview = MapCameraPosition.camera(
        MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                  distance: 24_000_000, heading: 0, pitch: 0)
    )

    // La destination par défaut vient des Préférences
    init(settings: AppSettings = .shared) {
        let saved = settings.tracerouteDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        destination = saved.isEmpty ? "8.8.8.8" : saved
    }

    /// Hop described in the info banner: the selected one, otherwise the newest while tracing.
    var focusedHop: TracerouteHop? {
        if let selectedHopID { return hops.first { $0.id == selectedHopID } }
        return isRunning ? hops.last : nil
    }

    var highlightedHopID: Int? { focusedHop?.id }

    // Toute la route est affichée d'un coup : chaque nouveau hop est ajouté à la carte
    // et la caméra recadre l'ensemble du trajet, sans survoler les hops un par un.
    func start() {
        guard !isRunning else { return }
        traceTask?.cancel()
        isRunning = true
        hops = []; stops = []; selectedHopID = nil
        withAnimation(.easeInOut(duration: 1.0)) { cameraPosition = Self.overview }

        let target = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        traceTask = Task {
            await tracerouteService.setDestination(target)
            for await hop in await tracerouteService.run() {
                guard !Task.isCancelled else { break }
                let enriched = await geoService.locate(hop: hop)
                hops.append(enriched)
                let updated = TracerouteRoute.stops(for: hops)
                let addedStop = updated.count != stops.count
                stops = updated
                if addedStop { showFullRoute() }
            }
            isRunning = false
            showFullRoute()
        }
    }

    func stop() {
        traceTask?.cancel()
        traceTask = nil
        isRunning = false
    }

    func select(hopID: Int) {
        selectedHopID = selectedHopID == hopID ? nil : hopID
    }

    func clearSelection() { selectedHopID = nil }

    /// Frames every geolocated hop of the route.
    func showFullRoute() {
        let target = TracerouteRoute.mapRect(fitting: stops.map(\.coordinate))
            .map(MapCameraPosition.rect) ?? Self.overview
        withAnimation(.easeInOut(duration: 1.2)) { cameraPosition = target }
    }
}

extension TracerouteService {
    func setDestination(_ dest: String) async { destination = dest }
}
