import SwiftUI
import CoreLocation
import NetCheckCore

@MainActor
@Observable
final class WiFiScanViewModel: NSObject, CLLocationManagerDelegate {
    private(set) var networks: [WiFiNetworkInfo] = []
    private(set) var isScanning = false
    private(set) var scanError: WiFiNetworkScanner.ScanError?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let scanner = WiFiNetworkScanner()
    private let locationManager = CLLocationManager()
    private var refreshTask: Task<Void, Never>?

    // Un scan Wi-Fi manque parfois une borne au passage (fenêtre de scan courte) — on fusionne
    // les résultats successifs par id plutôt que de tout remplacer, et on ne retire une entrée
    // qu'après plusieurs scans consécutifs sans elle, pour une liste stable et complète.
    private struct Tracked { var info: WiFiNetworkInfo; var missedScans: Int }
    private var tracked: [String: Tracked] = [:]
    private let maxMissedScans = 2

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    func start() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        refresh()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { return }
                refresh()
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() {
        guard !isScanning else { return }
        isScanning = true
        scanError = nil
        Task {
            defer { isScanning = false }
            do {
                let results = try await scanner.scan()
                var seenIDs = Set<String>()
                for network in results {
                    seenIDs.insert(network.id)
                    tracked[network.id] = Tracked(info: network, missedScans: 0)
                }
                for key in tracked.keys where !seenIDs.contains(key) {
                    tracked[key]?.missedScans += 1
                }
                tracked = tracked.filter { $0.value.missedScans <= maxMissedScans }
                networks = tracked.values.map(\.info).sorted { $0.rssi > $1.rssi }
            } catch {
                scanError = error as? WiFiNetworkScanner.ScanError ?? .scanFailed(error.localizedDescription)
            }
        }
    }

    func errorMessage(locale: Locale) -> String? {
        scanError?.localizedDescription(locale: locale)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            refresh()
        }
    }

    var locationAuthorized: Bool {
        authorizationStatus == .authorizedAlways
    }

    var locationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // Diagnostic : nombre de réseaux détectés sur chaque canal, pour repérer la congestion
    private var channelCongestion: [Int: Int] {
        Dictionary(grouping: networks.compactMap(\.channelNumber), by: { $0 })
            .mapValues(\.count)
    }

    func congestion(for network: WiFiNetworkInfo) -> Int {
        guard let channel = network.channelNumber else { return 1 }
        return channelCongestion[channel] ?? 1
    }

    var weakSecurityCount: Int {
        networks.filter(\.security.isWeak).count
    }

    // Regroupement optionnel par SSID — les réseaux masqués (sans SSID) ne sont jamais
    // regroupés entre eux, chacun reste une entrée à part.
    struct NetworkGroup: Identifiable {
        let id: String
        let networks: [WiFiNetworkInfo]
    }

    var groupedNetworks: [NetworkGroup] {
        Dictionary(grouping: networks) { $0.ssid ?? "hidden:\($0.id)" }
            .map { key, group in
                let sorted = group.sorted { $0.rssi > $1.rssi }
                return NetworkGroup(id: key, networks: sorted)
            }
            .sorted { $0.networks[0].rssi > $1.networks[0].rssi }
    }
}
