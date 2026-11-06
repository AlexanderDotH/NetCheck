import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case german = "de"
    case french = "fr"

    var id: String { rawValue }

    var nativeName: String? {
        switch self {
        case .system: return nil
        case .english: return "English"
        case .german: return "Deutsch"
        case .french: return "Français"
        }
    }

    func resolvedLocale(preferredLanguages: [String] = Locale.preferredLanguages) -> Locale {
        guard self == .system else { return Locale(identifier: rawValue) }

        for identifier in preferredLanguages {
            let locale = Locale(identifier: identifier)
            if let languageCode = locale.language.languageCode?.identifier,
               let language = Self(rawValue: languageCode), language != .system {
                return locale
            }
        }
        return Locale(identifier: AppLanguage.english.rawValue)
    }
}
