import AppKit
import Foundation
import SwiftUI
import Testing
@testable import NetCheck

@Suite("Live language switching", .serialized)
@MainActor
struct LiveLanguageTests {
    @Test func multipleRootsUpdateWithoutResettingResultsOrTasks() async throws {
        let suiteName = "NetCheckLiveLanguageTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)
        settings.selectedLanguage = .english

        let first = LocaleProbe()
        let second = LocaleProbe()
        let firstWindow = makeWindow(settings: settings, probe: first)
        let secondWindow = makeWindow(settings: settings, probe: second)
        defer {
            firstWindow.orderOut(nil)
            secondWindow.orderOut(nil)
            firstWindow.contentView = nil
            secondWindow.contentView = nil
        }

        try await waitUntil { first.language == "en" && second.language == "en" && first.taskStarts == 1 && second.taskStarts == 1 }
        let firstIdentity = try #require(first.identity)
        let secondIdentity = try #require(second.identity)

        for (selection, language) in [(AppLanguage.german, "de"), (.french, "fr"), (.english, "en")] {
            settings.selectedLanguage = selection
            try await waitUntil { first.language == language && second.language == language }

            #expect(first.identity == firstIdentity)
            #expect(second.identity == secondIdentity)
            #expect(first.results == [12, 34, 56])
            #expect(second.results == [12, 34, 56])
            #expect(first.taskStarts == 1)
            #expect(second.taskStarts == 1)
            #expect(first.taskStops == 0)
            #expect(second.taskStops == 0)
        }
    }

    private func makeWindow(settings: AppSettings, probe: LocaleProbe) -> NSWindow {
        let content = LocalizedRoot(settings: settings) {
            DiagnosticProbeView(probe: probe)
        }
        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 300, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content)
        window.orderFrontRegardless()
        window.contentView?.layoutSubtreeIfNeeded()
        return window
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("Timed out waiting for SwiftUI locale propagation")
        throw LocalePropagationTimeout()
    }
}

private struct LocalePropagationTimeout: Error {}

@MainActor
private final class LocaleProbe {
    var language: String?
    var identity: UUID?
    var results: [Int] = []
    var taskStarts = 0
    var taskStops = 0
}

@MainActor
private struct DiagnosticProbeView: View {
    @Environment(\.locale) private var locale
    @State private var identity = UUID()
    @State private var results = [12, 34, 56]
    let probe: LocaleProbe

    var body: some View {
        Text(locale.identifier)
            .onAppear { record() }
            .onChange(of: locale.identifier) { record() }
            .task {
                probe.taskStarts += 1
                defer { probe.taskStops += 1 }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(20))
                }
            }
    }

    private func record() {
        probe.language = locale.language.languageCode?.identifier
        probe.identity = identity
        probe.results = results
    }
}
