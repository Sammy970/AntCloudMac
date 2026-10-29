import SwiftUI

@main
struct AntCloudApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var auth = AuthStore()

    var body: some Scene {
        WindowGroup("AntCloud") {
            RootView()
                .environmentObject(auth)
                .frame(minWidth: 520, minHeight: 600)
                .task { await auth.restore() }
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Running as a bare SwiftPM executable needs this to get a Dock icon and key window.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
