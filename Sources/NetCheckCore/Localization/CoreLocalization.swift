import Foundation

enum CoreLocalization {
    private static let frameworkBundle = Bundle(for: BundleMarker.self)
    private static let supportedLanguages = ["en", "de", "fr"]

    static func string(_ key: String, locale: Locale) -> String {
        let language = locale.language.languageCode?.identifier ?? "en"
        let localization = supportedLanguages.contains(language) ? language : "en"
        let bundle = localizedBundle(for: localization)
        return bundle.localizedString(forKey: key, value: key, table: "Core")
    }

    private static func localizedBundle(for language: String) -> Bundle {
        guard let path = frameworkBundle.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return frameworkBundle
        }
        return bundle
    }

    private final class BundleMarker: NSObject {}
}
