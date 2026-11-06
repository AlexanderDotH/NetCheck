import SwiftUI

struct LocalizedRoot<Content: View>: View {
    @State private var settings: AppSettings
    private let content: Content

    init(settings: AppSettings = .shared, @ViewBuilder content: () -> Content) {
        self._settings = State(initialValue: settings)
        self.content = content()
    }

    var body: some View {
        content.environment(\.locale, settings.selectedLanguage.resolvedLocale())
    }
}
