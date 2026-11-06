import Foundation

// Normalise -30 dBm (1.0) à -90 dBm (0.0) — partagé entre WiFiSignal et WiFiNetworkInfo
func wifiStrength(forRSSI rssi: Int) -> Double {
    max(0, min(1, Double(rssi + 90) / 60.0))
}

func wifiLabel(forRSSI rssi: Int, locale: Locale) -> String {
    switch rssi {
    case (-50)...: return CoreLocalization.string("Excellent", locale: locale)
    case (-65)...: return CoreLocalization.string("Good", locale: locale)
    case (-75)...: return CoreLocalization.string("Fair", locale: locale)
    default:       return CoreLocalization.string("Weak", locale: locale)
    }
}

public struct WiFiSignal: Sendable {
    public let rssi: Int        // dBm, typiquement -30 à -90
    public let ssid: String?

    public var strength: Double { wifiStrength(forRSSI: rssi) }
    public var label: String { localizedLabel(locale: .current) }

    public func localizedLabel(locale: Locale) -> String {
        wifiLabel(forRSSI: rssi, locale: locale)
    }

    public init(rssi: Int, ssid: String?) {
        self.rssi = rssi; self.ssid = ssid
    }
}

public enum WiFiSecurityLevel: Sendable {
    case open, owe, wep, wpa, wpa2, wpa3, unknown

    public var label: String {
        localizedLabel(locale: .current)
    }

    public func localizedLabel(locale: Locale) -> String {
        switch self {
        case .open:    return CoreLocalization.string("Open", locale: locale)
        case .owe:     return "OWE"
        case .wep:     return "WEP"
        case .wpa:     return "WPA"
        case .wpa2:    return "WPA2"
        case .wpa3:    return "WPA3"
        case .unknown: return CoreLocalization.string("Unknown", locale: locale)
        }
    }

    // Réseaux sans chiffrement robuste — à signaler dans le diagnostic
    public var isWeak: Bool {
        switch self {
        case .open, .wep: return true
        default:          return false
        }
    }
}

// Un point d'accès individuel (une entrée par BSSID) — plusieurs WiFiNetworkInfo
// peuvent partager le même SSID (mesh, extenders) sans être regroupés.
public struct WiFiNetworkInfo: Sendable, Identifiable, Hashable {
    public let id: String
    public let ssid: String?
    public let bssid: String?
    public let rssi: Int
    public let noise: Int?
    public let channelNumber: Int?
    public let band: String?
    public let channelWidth: String?
    public let phyMode: String?
    public let security: WiFiSecurityLevel
    public let isAdHoc: Bool
    public let isCurrent: Bool

    public var strength: Double { wifiStrength(forRSSI: rssi) }
    public var label: String { localizedLabel(locale: .current) }
    public var displayName: String { localizedDisplayName(locale: .current) }

    public func localizedLabel(locale: Locale) -> String {
        wifiLabel(forRSSI: rssi, locale: locale)
    }

    /// Band with the frequency in the locale's number format: "2.4 GHz" in English, "2,4 GHz" in German and French.
    public func localizedBand(locale: Locale) -> String? {
        guard let band else { return nil }
        let parts = band.split(separator: " ", maxSplits: 1)
        guard parts.count == 2,
              let value = Double(parts[0].replacingOccurrences(of: ",", with: ".")) else { return band }
        return "\(value.formatted(.number.locale(locale))) \(parts[1])"
    }

    public func localizedDisplayName(locale: Locale) -> String {
        guard let ssid, !ssid.isEmpty else {
            return CoreLocalization.string("Hidden network", locale: locale)
        }
        return ssid
    }
    // Rapport signal/bruit (dB) — plus il est élevé, plus la liaison est propre.
    // CoreWLAN renvoie un bruit de 0 quand il n'est pas mesuré : pas de SNR dans ce cas.
    public var snr: Int? {
        guard let noise, noise < 0 else { return nil }
        return rssi - noise
    }

    public init(
        id: String, ssid: String?, bssid: String?, rssi: Int, noise: Int?,
        channelNumber: Int?, band: String?, channelWidth: String?, phyMode: String?,
        security: WiFiSecurityLevel, isAdHoc: Bool, isCurrent: Bool
    ) {
        self.id = id; self.ssid = ssid; self.bssid = bssid; self.rssi = rssi; self.noise = noise
        self.channelNumber = channelNumber; self.band = band
        self.channelWidth = channelWidth; self.phyMode = phyMode
        self.security = security; self.isAdHoc = isAdHoc; self.isCurrent = isCurrent
    }
}
