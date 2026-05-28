import SwiftUI

@main
struct NewStickyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All window management is handled imperatively via AppDelegate and WindowManager.
        // We still need at least one Scene for the @main App lifecycle.
        Settings {
            EmptyView()
        }
    }
}
