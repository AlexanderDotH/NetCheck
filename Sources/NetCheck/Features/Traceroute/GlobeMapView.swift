import SwiftUI
import MapKit

struct GlobeMapView: View {
    let stops: [RouteStop]
    let highlightedHopID: Int?
    let isComplete: Bool
    /// Height of the controls drawn over the bottom of the map.
    var bottomInset: CGFloat = 0
    @Binding var cameraPosition: MapCameraPosition

    private var route: [CLLocationCoordinate2D] { stops.map(\.coordinate) }

    var body: some View {
        Map(position: $cameraPosition) {
            // Tracé complet : contour sombre + ligne jaune, en géodésique sur le globe
            if route.count >= 2 {
                MapPolyline(coordinates: route, contourStyle: .geodesic)
                    .stroke(.black.opacity(0.45),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                MapPolyline(coordinates: route, contourStyle: .geodesic)
                    .stroke(.yellow,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }

            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                Annotation(stop.city ?? "", coordinate: stop.coordinate, anchor: .center) {
                    StopMarker(
                        label: stop.hopLabel,
                        role: role(at: index),
                        isHighlighted: highlightedHopID.map(stop.hopIDs.contains) ?? false
                    )
                }
            }
        }
        // Hybrid = satellite imagery plus country borders, country and city names.
        .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapZoomStepper()
        }
        // Keeps the Apple Maps attribution, map controls and camera framing above the overlay
        .safeAreaPadding(.bottom, bottomInset)
        .ignoresSafeArea()
    }

    private func role(at index: Int) -> StopMarker.Role {
        if index == 0 { return .origin }
        if isComplete && index == stops.count - 1 { return .destination }
        return .transit
    }
}

private struct StopMarker: View {
    enum Role { case origin, transit, destination }

    let label: String
    let role: Role
    let isHighlighted: Bool

    private var fill: Color {
        switch role {
        case .origin:      return .green
        case .transit:     return Color(white: 0.12)
        case .destination: return .red
        }
    }

    var body: some View {
        Text(verbatim: label)
            .font(.caption2.monospacedDigit().weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 22)
            .background(fill, in: Capsule())
            .overlay(Capsule().strokeBorder(isHighlighted ? Color.yellow : .white.opacity(0.85),
                                            lineWidth: isHighlighted ? 2.5 : 1.5))
            .shadow(color: isHighlighted ? .yellow.opacity(0.8) : .black.opacity(0.5),
                    radius: isHighlighted ? 8 : 3)
            .scaleEffect(isHighlighted ? 1.25 : 1)
            .animation(.spring(duration: 0.3), value: isHighlighted)
    }
}
