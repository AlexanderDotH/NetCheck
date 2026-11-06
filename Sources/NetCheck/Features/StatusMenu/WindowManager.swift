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
        panels[feature] = panel
        panel.makeKeyAndOrderFront(nil)
    }

    // Supprime le panel à la fermeture pour que SwiftUI déclenche onDisappear
    private static func didClose(feature: Feature) {
        panels[feature] = nil
        delegates[feature] = nil
    }

    private static func makePanel(for feature: Feature) -> NSPanel {
        let (view, size): (AnyView, NSSize) = switch feature {
        case .wifiFinder: (AnyView(WiFiFinderView()), NSSize(width: 680, height: 460))
        case .wifiScan:   (AnyView(WiFiScanView()),   NSSize(width: 520, height: 480))
        case .speedTest:  (AnyView(SpeedTestView()),  NSSize(width: 468, height: 480))
        case .traceroute: (AnyView(TracerouteView()), NSSize(width: 640, height: 520))
        case .usage:      (AnyView(UsageView()),       NSSize(width: 1020, height: 480))
        case .settings:   (AnyView(PreferencesView()), NSSize(width: 420, height: 520))
        }
        let isResizable = feature == .wifiFinder || feature == .wifiScan || feature == .speedTest || feature == .traceroute || feature == .usage
        var mask: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView, .nonactivatingPanel]
        if isResizable { mask.insert(.resizable) }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: mask,
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        switch feature {
        case .wifiFinder: panel.minSize = NSSize(width: 480, height: 380)
        case .wifiScan:   panel.minSize = NSSize(width: 420, height: 380)
        case .speedTest:  panel.minSize = NSSize(width: 380, height: 420)
        case .traceroute: panel.minSize = NSSize(width: 500, height: 420)
        case .usage:      panel.minSize = NSSize(width: 680, height: 400)
        default: break
        }
        panel.contentViewController = NSHostingController(rootView: LocalizedRoot { view })
        panel.center()

        let delegate = PanelDelegate(feature: feature)
        panel.delegate = delegate
        delegates[feature] = delegate

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

extension WindowManager.Feature: Hashable {}
