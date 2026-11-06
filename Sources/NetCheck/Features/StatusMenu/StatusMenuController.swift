import AppKit
import SwiftUI
import NetCheckCore

@MainActor
final class StatusMenuController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var popover: NSPopover?
    private let monitor = ConnectivityMonitor()
    private var monitorTask: Task<Void, Never>?

    func setup() {
        let button = statusItem.button!
        button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "NetCheck")
        button.image?.isTemplate = false
        button.action = #selector(togglePopover)
        button.target = self

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: LocalizedRoot { StatusMenuView() })
        self.popover = popover

        Task { await monitor.start() }
        monitorTask = Task {
            for await status in await monitor.statusStream {
                updateIcon(for: status)
            }
        }
    }

    private func updateIcon(for status: ConnectivityStatus) {
        guard let button = statusItem.button else { return }
        let color: NSColor
        switch status {
        case .connected:  color = .systemGreen
        case .degraded:   color = .systemOrange
        case .offline:    color = .systemRed
        }
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            .applying(.init(paletteColors: [color]))
        button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "NetCheck")?
            .withSymbolConfiguration(config)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
