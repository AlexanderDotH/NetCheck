import AppKit
import SwiftUI
import Testing
@testable import NetCheck

@Suite("Feature windows", .serialized)
@MainActor
struct FeatureWindowTests {
    nonisolated private static let resizableFeatures: [WindowManager.Feature] = [
        .wifiFinder, .wifiScan, .speedTest, .traceroute, .usage,
    ]

    @Test(arguments: resizableFeatures)
    func panelsOpenAtTheirDesignedSize(feature: WindowManager.Feature) throws {
        let panel = WindowManager.makePanel(for: feature)
        defer { panel.contentViewController = nil }
        panel.contentView?.layoutSubtreeIfNeeded()

        // The hosting controller must not resize the window to the SwiftUI ideal size.
        let contentSize = panel.contentRect(forFrameRect: panel.frame).size
        #expect(contentSize == feature.defaultContentSize)

        // The SwiftUI content fits the default size, and the window cannot shrink below it.
        #expect(panel.contentMinSize.width <= feature.defaultContentSize.width)
        #expect(panel.contentMinSize.height <= feature.defaultContentSize.height)
        let minimum = try #require(feature.minimumSize)
        #expect(panel.minSize == minimum)
        #expect(panel.styleMask.contains(.resizable))
    }

    @Test func titleBarStaysDraggableExceptOnTheGlobe() {
        for feature in Self.resizableFeatures {
            let panel = WindowManager.makePanel(for: feature, content: AnyView(Color.clear))
            #expect(panel.titlebarAppearsTransparent)
            #expect(panel.titleVisibility == .hidden)
            #expect(panel.isMovableByWindowBackground == (feature != .traceroute))
            panel.contentViewController = nil
        }
    }

    @Test func tracerouteDestinationComesFromPreferences() throws {
        let suiteName = "NetCheckFeatureWindowTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)

        #expect(TracerouteViewModel(settings: settings).destination == "8.8.8.8")
        settings.tracerouteDestination = "  one.one.one.one "
        #expect(TracerouteViewModel(settings: settings).destination == "one.one.one.one")
        settings.tracerouteDestination = "   "
        #expect(TracerouteViewModel(settings: settings).destination == "8.8.8.8")
    }
}
