import SwiftUI

/// Signed-in window: a sidebar with the Cloud PC, Stream and Network panes and the account footer.
struct HomeView: View {
    enum Pane: Hashable { case cloudPC, stream, network, controllers, about }

    @EnvironmentObject private var auth: AuthStore
    @Environment(\.openURL) private var openURL
    @StateObject private var session: SessionService
    @State private var settings = StreamSettings.load()
    @State private var pane: Pane? = .cloudPC
    /// Kept here so results survive switching panes.
    @StateObject private var networkCheck = NetworkCheck()
    @StateObject private var controllerMonitor = ControllerMonitor()

    init(api: APIClient) {
        _session = StateObject(wrappedValue: SessionService(api: api, driver: MoonlightDriver()))
    }

    var body: some View {
        split
            .onChange(of: settings) { $0.save() }
        .onChange(of: session.phase) { phase in
            // The in-stream overlay (time left, health warnings, ⌃⌥A) lives exactly as long as the stream.
            if phase == .streaming, let host = session.streamHost {
                StreamOverlayPanel.shared.begin(host: host, profile: auth.profile)
            } else if phase != .streaming {
                StreamOverlayPanel.shared.end()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAbout)) { _ in pane = .about }
        .onAppear {
            session.onSessionExpired = { auth.logout() }
            previewIfRequested()
        }
        .alert(item: $session.notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message))
        }
    }

    @ViewBuilder
    private var split: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["ANTCLOUD_SNAPSHOT"] != nil {
            // Window snapshots can't draw the glass sidebar, so lay the same views out flat.
            HStack(spacing: 0) {
                sidebar.frame(width: 220)
                Divider()
                detail
            }
        } else {
            splitView
        }
        #else
        splitView
        #endif
    }

    private var splitView: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            detail
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch pane ?? .cloudPC {
        case .cloudPC:
            CloudPCPane(session: session, settings: settings) { pane = .stream }
        case .stream:
            StreamPane(settings: $settings, locked: session.phase == .pairing || session.phase == .streaming)
        case .about:
            ScrollView { AboutView() }
                .navigationTitle("About")
        case .network:
            NetworkPane(check: networkCheck, settings: $settings, busy: session.phase == .pairing || session.phase == .streaming)
        case .controllers:
            ControllersPane(monitor: controllerMonitor)
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        List(selection: $pane) {
            NavigationLink(value: Pane.cloudPC) {
                HStack {
                    Label("Cloud PC", systemImage: "desktopcomputer")
                    Spacer()
                    if let color = session.phase.indicatorColor {
                        Circle().fill(color).frame(width: 7, height: 7)
                            .help(session.phase.statusText)
                    }
                }
            }
            NavigationLink(value: Pane.stream) {
                Label("Stream", systemImage: "slider.horizontal.3")
            }
            NavigationLink(value: Pane.network) {
                Label("Network", systemImage: "gauge.with.dots.needle.67percent")
            }
            NavigationLink(value: Pane.controllers) {
                Label("Controllers", systemImage: "gamecontroller")
            }
            NavigationLink(value: Pane.about) {
                Label("About", systemImage: "info.circle")
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let profile = auth.profile {
                AccountFooter(profile: profile) {
                    Task { await auth.reloadProfile() }
                } plans: {
                    openURL(Config.pricingURL)
                } logOut: {
                    session.shutDown()
                    auth.logout()
                }
            }
        }
    }

    /// Debug builds only: `ANTCLOUD_PREVIEW=home:<phase>` shows a phase for screenshots.
    private func previewIfRequested() {
        #if DEBUG
        guard let value = ProcessInfo.processInfo.environment["ANTCLOUD_PREVIEW"],
              value.hasPrefix("home:") else { return }
        let phases: [String: SessionService.Phase] = [
            "idle": .idle, "connecting": .connecting, "queued": .queued(position: 3), "booting": .booting,
            "ready": .ready, "pairing": .pairing, "streaming": .streaming,
        ]
        let parts = value.dropFirst(5).split(separator: ":")
        if let phase = parts.first.flatMap({ phases[String($0)] }) { session.previewPhase(phase) }
        if parts.contains("stream") { pane = .stream }
        if parts.contains("network") { pane = .network }
        if parts.contains("about") { pane = .about }
        // `:controllers` opens the pane; add `:sample` for a sample controller mid-press, without hardware.
        if parts.contains("controllers") { pane = .controllers }
        if parts.contains("sample") { controllerMonitor.showPreview() }
        // `home:streaming:overlay` also opens the in-stream overlay against AntCloud's server.
        if parts.contains("overlay") {
            StreamOverlayPanel.shared.begin(host: "socket.antcloud.co", profile: auth.profile)
        }
        #endif
    }
}

// MARK: - Account footer

private struct AccountFooter: View {
    let profile: UserProfile
    let refresh: () -> Void
    let plans: () -> Void
    let logOut: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PlanUsage(profile: profile, compact: true)

            HStack(spacing: 9) {
                ProfileBadge(profile: profile)
                Spacer(minLength: 0)
                Menu {
                    Text(profile.email)
                    Divider()
                    Button("Refresh Account", action: refresh)
                    Button("Plans & Pricing…", action: plans)
                    Divider()
                    Button("Log Out", action: logOut)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Account")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Divider() }
    }
}
