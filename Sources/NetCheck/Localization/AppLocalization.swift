import Foundation

enum AppLocalization {
    static func string(
        _ value: String.LocalizationValue,
        table: String? = nil,
        locale: Locale
    ) -> String {
        let languageCode = locale.language.languageCode?.identifier
        let supportedLanguage = languageCode.flatMap(AppLanguage.init(rawValue:)) ?? .english
        let formattingLocale = languageCode == supportedLanguage.rawValue
            ? locale : supportedLanguage.resolvedLocale()
        let bundle = localizedBundle(for: supportedLanguage)
        return String(localized: value, table: table, bundle: bundle, locale: formattingLocale)
    }

    private static func localizedBundle(for language: AppLanguage) -> Bundle {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
            ?? Bundle.main.path(forResource: AppLanguage.english.rawValue, ofType: "lproj")
        return path.flatMap(Bundle.init(path:)) ?? .main
    }
}
