import SwiftUI

/// The Mac's Network pane: the shared network check, tied to the stream settings.
struct NetworkPane: View {
    @ObservedObject var check: NetworkCheck
    @Binding var settings: StreamSettings
    let busy: Bool

    var body: some View {
        NetworkCheckView(
            check: check,
            resolution: settings.resolution,
            fps: settings.fps,
            bitrate: Int(settings.bitrate) ?? 0,
            applyBitrate: { settings.bitrate = String($0) },
            busy: busy
        )
        .navigationTitle("Network")
    }
}
