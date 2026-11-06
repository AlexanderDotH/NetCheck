import SwiftUI
import NetCheckCore

@MainActor
@Observable
final class SpeedTestViewModel {
    private(set) var download: Double = 0
    private(set) var upload: Double = 0
    private(set) var rpm: Int = 0
    private(set) var latencyMs: Double = 0
    private(set) var isRunning = false
    private(set) var isDone = false

    private let service = SpeedTestService()
    private var testTask: Task<Void, Never>?
    private var animTask: Task<Void, Never>?

    // EMA interne — lisse le jitter, la valeur affichée converge vers la moyenne
    private var emaDl: Double = 0
    private var emaUl: Double = 0
    private var emaRpm: Double = 0
    private var emaLatency: Double = 0
    private static let emaAlpha = 0.2

    func start() {
        guard !isRunning else { return }
        isRunning = true; isDone = false
        download = 0; upload = 0; rpm = 0; latencyMs = 0
        emaDl = 0; emaUl = 0; emaRpm = 0; emaLatency = 0
        startAnimation()
        testTask = Task {
            for await progress in await service.run() {
                animTask?.cancel()
                download  = progress.downloadMbps
                upload    = progress.uploadMbps
                rpm       = progress.rpm
                latencyMs = progress.latencyMs
                if progress.isComplete { isDone = true; isRunning = false }
            }
            animTask?.cancel()
            isRunning = false
        }
    }

    // Valeurs simulées : montée exp + jitter ±8% lissé par EMA.
    // La valeur affichée est la moyenne glissante, pas le dernier échantillon brut.
    private func startAnimation() {
        animTask?.cancel()
        animTask = Task { @MainActor in
            var t: Double = 0
            let α = SpeedTestViewModel.emaAlpha
            while !Task.isCancelled {
                let base   = 1.0 - exp(-t / 10.0)
                let jitter = { Double.random(in: -0.08...0.08) }
                emaDl      = emaDl      + α * (120 * base * (1 + jitter()) - emaDl)
                emaUl      = emaUl      + α * (60  * base * (1 + jitter()) - emaUl)
                emaRpm     = emaRpm     + α * (600 * base + Double.random(in: -40...40) - emaRpm)
                emaLatency = emaLatency + α * (200 * exp(-t / 5) + 10 + Double.random(in: -3...3) - emaLatency)
                download  = max(0, emaDl)
                upload    = max(0, emaUl)
                rpm       = max(0, Int(emaRpm))
                latencyMs = max(5, emaLatency)
                try? await Task.sleep(for: .milliseconds(120))
                t += 0.12
            }
        }
    }

    func rpmLabel(locale: Locale) -> String {
        switch rpm {
        case 0:       return "—"
        case ..<400:  return AppLocalization.string("Fair", table: "Features", locale: locale)
        case ..<1000: return AppLocalization.string("Good", table: "Features", locale: locale)
        default:      return AppLocalization.string("Excellent", table: "Features", locale: locale)
        }
    }

    func latencyLabel(locale: Locale) -> String {
        guard latencyMs > 0 else { return "—" }
        switch latencyMs {
        case ..<20:  return AppLocalization.string("Excellent", table: "Features", locale: locale)
        case ..<60:  return AppLocalization.string("Good", table: "Features", locale: locale)
        case ..<120: return AppLocalization.string("Fair", table: "Features", locale: locale)
        default:     return AppLocalization.string("High", table: "Features", locale: locale)
        }
    }
}
