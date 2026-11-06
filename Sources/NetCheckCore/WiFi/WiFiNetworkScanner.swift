import Foundation
import CoreWLAN

// Scan complet des réseaux Wi-Fi visibles — contrairement à WiFiScanner (signal du
// réseau connecté uniquement), chaque point d'accès (BSSID) apparaît comme une entrée
// distincte même si plusieurs partagent le même SSID.
public actor WiFiNetworkScanner {
    public enum ScanError: Error, Sendable, LocalizedError {
        case interfaceUnavailable
        case scanFailed(String)

        public var errorDescription: String? {
            localizedDescription(locale: .current)
        }

        public func localizedDescription(locale: Locale) -> String {
            switch self {
            case .interfaceUnavailable:
                return CoreLocalization.string("Wi-Fi interface unavailable.", locale: locale)
            case .scanFailed(let message): return message
            }
        }
    }

    public init() {}

    public func scan() throws -> [WiFiNetworkInfo] {
        guard let iface = CWWiFiClient.shared().interface() else {
            throw ScanError.interfaceUnavailable
        }
        let currentBSSID = iface.bssid()
        do {
            let networks = try iface.scanForNetworks(withSSID: nil, includeHidden: true)
            return networks
                .map { network in
                    // Sans BSSID (autorisation Localisation absente), on retombe sur SSID+canal :
                    // stable d'un scan à l'autre, mais ne peut pas dissocier deux bornes identiques
                    // sur le même canal — limitation de l'API CoreWLAN, pas du code.
                    let id = network.bssid ?? "ssid:\(network.ssid ?? "masqué")|ch:\(network.wlanChannel?.channelNumber ?? 0)"
                    return WiFiNetworkInfo(
                        id: id,
                        ssid: network.ssid,
                        bssid: network.bssid,
                        rssi: network.rssiValue,
                        noise: network.noiseMeasurement,
                        channelNumber: network.wlanChannel?.channelNumber,
                        band: Self.bandLabel(network.wlanChannel?.channelBand),
                        channelWidth: Self.widthLabel(network.wlanChannel?.channelWidth),
                        phyMode: Self.phyModeLabel(of: network),
                        security: Self.securityLevel(of: network),
                        isAdHoc: network.ibss,
                        isCurrent: currentBSSID != nil && network.bssid == currentBSSID
                    )
                }
                .sorted { $0.rssi > $1.rssi }
        } catch {
            throw ScanError.scanFailed(error.localizedDescription)
        }
    }

    private static func bandLabel(_ band: CWChannelBand?) -> String? {
        switch band {
        case .band2GHz: return "2.4 GHz"
        case .band5GHz: return "5 GHz"
        case .band6GHz: return "6 GHz"
        default:        return nil
        }
    }

    private static func widthLabel(_ width: CWChannelWidth?) -> String? {
        switch width {
        case .width20MHz:  return "20 MHz"
        case .width40MHz:  return "40 MHz"
        case .width80MHz:  return "80 MHz"
        case .width160MHz: return "160 MHz"
        default:           return nil
        }
    }

    // Rapporte la génération Wi-Fi la plus élevée annoncée par le point d'accès
    private static func phyModeLabel(of network: CWNetwork) -> String? {
        let modes: [(CWPHYMode, String)] = [
            (.mode11be, "Wi-Fi 7"),
            (.mode11ax, "Wi-Fi 6"),
            (.mode11ac, "Wi-Fi 5"),
            (.mode11n,  "Wi-Fi 4"),
            (.mode11g,  "802.11g"),
            (.mode11a,  "802.11a"),
            (.mode11b,  "802.11b"),
        ]
        for (mode, label) in modes where network.supportsPHYMode(mode) {
            return label
        }
        return nil
    }

    private static func securityLevel(of network: CWNetwork) -> WiFiSecurityLevel {
        if network.supportsSecurity(.wpa3Personal) || network.supportsSecurity(.wpa3Enterprise)
            || network.supportsSecurity(.wpa3Transition) {
            return .wpa3
        }
        if network.supportsSecurity(.wpa2Personal) || network.supportsSecurity(.wpa2Enterprise)
            || network.supportsSecurity(.personal) || network.supportsSecurity(.enterprise) {
            return .wpa2
        }
        if network.supportsSecurity(.wpaPersonal) || network.supportsSecurity(.wpaEnterprise)
            || network.supportsSecurity(.wpaPersonalMixed) || network.supportsSecurity(.wpaEnterpriseMixed) {
            return .wpa
        }
        if network.supportsSecurity(.OWE) || network.supportsSecurity(.oweTransition) {
            return .owe
        }
        if network.supportsSecurity(.dynamicWEP) || network.supportsSecurity(.WEP) {
            return .wep
        }
        if network.supportsSecurity(.none) {
            return .open
        }
        return .unknown
    }
}
