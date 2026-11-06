import SwiftUI

@main
struct NetCheckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            LocalizedRoot { PreferencesView() }
        }
    }
}
