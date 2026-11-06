import AppKit
import SwiftUI

@MainActor
enum WindowManager {
    enum Feature { case wifiFinder, wifiScan, speedTest, traceroute, usage, settings }

    private static var panels: [Feature: NSPanel] = [:]
    private static var delegates: [Feature: PanelDelegate] = [:]

    static func open(_ feature: Feature) {
        if let existing = panels[feature] {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let panel = makePanel(for: feature)
        let delegate = PanelDelegate(feature: feature)
        panel.delegate = delegate
        delegates[feature] = delegate
        panels[feature] = panel
        panel.makeKeyAndOrderFront(nil)
    }

    // Supprime le panel à la fermeture pour que SwiftUI déclenche onDisappear
    private static func didClose(feature: Feature) {
        panels[feature] = nil
        delegates[feature] = nil
    }

    static func makePanel(for feature: Feature, content: AnyView? = nil) -> NSPanel {
        let view = content ?? feature.makeView()
        let size = feature.defaultContentSize
        var mask: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView, .nonactivatingPanel]
        if feature.isResizable { mask.insert(.resizable) }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: mask,
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        // Sur la carte, un glisser doit déplacer le globe, pas la fenêtre
        panel.isMovableByWindowBackground = feature != .traceroute
        if let minimum = feature.minimumSize { panel.minSize = minimum }

        let host = NSHostingController(rootView: LocalizedRoot { view })
        // Only derive the minimum size from SwiftUI. Letting the hosting controller
        // drive the preferred size made windows open at odd sizes (e.g. 1500 pt tall).
        host.sizingOptions = [.minSize]
        panel.contentViewController = host
        panel.setContentSize(size)
        panel.center()
        return panel
    }

    private final class PanelDelegate: NSObject, NSWindowDelegate {
        let feature: Feature
        init(feature: Feature) { self.feature = feature }

        func windowWillClose(_ notification: Notification) {
            WindowManager.didClose(feature: feature)
        }
    }
}

extension WindowManager.Feature: Hashable, CaseIterable {
    var defaultContentSize: NSSize {
        switch self {
        case .wifiFinder: NSSize(width: 460, height: 560)
        case .wifiScan:   NSSize(width: 540, height: 600)
        case .speedTest:  NSSize(width: 480, height: 500)
        case .traceroute: NSSize(width: 760, height: 580)
        case .usage:      NSSize(width: 640, height: 440)
        case .settings:   NSSize(width: 420, height: 520)
        }
    }

    var minimumSize: NSSize? {
        switch self {
        case .wifiFinder: NSSize(width: 400, height: 500)
        case .wifiScan:   NSSize(width: 440, height: 420)
        case .speedTest:  NSSize(width: 420, height: 480)
        case .traceroute: NSSize(width: 560, height: 440)
        case .usage:      NSSize(width: 520, height: 380)
        case .settings:   nil
        }
    }

    var isResizable: Bool { self != .settings }

    @MainActor func makeView() -> AnyView {
        switch self {
        case .wifiFinder: AnyView(WiFiFinderView())
        case .wifiScan:   AnyView(WiFiScanView())
        case .speedTest:  AnyView(SpeedTestView())
        case .traceroute: AnyView(TracerouteView())
        case .usage:      AnyView(UsageView())
        case .settings:   AnyView(PreferencesView())
        }
    }
}
