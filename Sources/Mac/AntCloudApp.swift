import SwiftUI

@main
struct AntCloudApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var auth = AuthStore()

    var body: some Scene {
        WindowGroup("AntCloud") {
            RootView()
                .environmentObject(auth)
                .tint(.antBlue)
                .frame(minWidth: 760, minHeight: 600)
                .task {
                    if !startPreview() { await auth.restore() }
                }
        }
        .windowToolbarStyle(.unified)
        .commands {
            // The About pane (version, credits) replaces the standard About panel.
            CommandGroup(replacing: .appInfo) {
                Button("About AntCloud") { NotificationCenter.default.post(name: .showAbout, object: nil) }
            }
        }
    }

    /// Debug builds only: `ANTCLOUD_PREVIEW=login` or `home:<phase>` renders a state for screenshots
    /// with a fake profile, without reading the Keychain or calling the API.
    private func startPreview() -> Bool {
        #if DEBUG
        guard let value = ProcessInfo.processInfo.environment["ANTCLOUD_PREVIEW"] else { return false }
        if let icon = NSImage(contentsOfFile: "AntCloud.icns") { NSApp.applicationIconImage = icon }
        if ProcessInfo.processInfo.environment["ANTCLOUD_APPEARANCE"] == "light" { NSApp.appearance = NSAppearance(named: .aqua) }
        let renew = ISO8601DateFormatter().string(from: .now.addingTimeInterval(12 * 86_400))
        auth.previewSignIn(value == "login" ? nil : UserProfile(json: [
            "firstName": "Samyak", "email": "player@example.com", "currentPlan": "premiumNyt",
            "renewDate": renew, "totalTimeMonth": 3600, "timeUsedMonth": 1290,
        ]))
        return true
        #else
        return false
        #endif
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Running as a bare SwiftPM executable needs this to get a Dock icon and key window.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        #if DEBUG
        // `ANTCLOUD_SNAPSHOT=<file.png>` saves the window once it has settled, then quits.
        if let path = ProcessInfo.processInfo.environment["ANTCLOUD_SNAPSHOT"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Snapshot the window as the active one, so controls show their accent colours.
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first(where: \.isVisible)?.makeKeyAndOrderFront(nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if let view = NSApp.windows.first(where: \.isVisible)?.contentView?.superview,
                   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

extension Notification.Name {
    /// Opens the About pane (from the app menu).
    static let showAbout = Notification.Name("AntCloudShowAbout")
}
