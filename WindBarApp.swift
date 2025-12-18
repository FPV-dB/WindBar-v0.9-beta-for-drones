import SwiftUI

@main
struct WindBarApp: App {

    // Hook up the NSApplication delegate we wrote
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // No visible settings window for now
            EmptyView()
        }
    }
}
