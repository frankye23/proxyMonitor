import SwiftUI

@main
struct ProxyGlassApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar app — no main window scene needed
        // Settings scene for future settings panel
        Settings {
            SettingsView()
        }
    }
}
