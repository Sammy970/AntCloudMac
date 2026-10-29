import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.openURL) private var openURL
    @StateObject private var session: SessionService
    @State private var settings = StreamSettings.load()

    init(api: APIClient) {
        _session = StateObject(wrappedValue: SessionService(api: api, driver: MoonlightDriver()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            Divider()
            settingsForm
            Spacer(minLength: 0)
            statusCard
        }
        .padding(28)
        .onChange(of: settings) { $0.save() }
        .onAppear { session.onSessionExpired = { auth.logout() } }
        .alert(item: $session.notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message))
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, \(auth.profile?.firstName ?? "there")").font(.title2.bold())
                if let profile = auth.profile {
                    HStack(spacing: 12) {
                        Label(profile.currentPlan, systemImage: "creditcard")
                        if let minutes = profile.minutesLeft {
                            Label("\(minutes / 60)h \(minutes % 60)m left", systemImage: "clock")
                        }
                        if let days = profile.daysLeft {
                            Label("Renews in \(days)d", systemImage: "calendar")
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Menu {
                Button("Refresh account") { Task { await auth.reloadProfile() } }
                Button("Plans & pricing") { openURL(Config.pricingURL) }
                Divider()
                Button("Log out") {
                    session.shutDown()
                    auth.logout()
                }
            } label: {
                Image(systemName: "person.crop.circle").font(.title2)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    // MARK: Settings

    private var settingsForm: some View {
        Form {
            Picker("Resolution", selection: $settings.resolution) {
                Text("720p").tag("720")
                Text("1080p").tag("1080")
                Text("1440p").tag("1440")
                Text("4K").tag("2160")
            }
            Picker("Aspect ratio", selection: $settings.aspect) {
                ForEach(AspectRatio.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Frame rate", selection: $settings.fps) {
                Text("30 FPS").tag("30")
                Text("60 FPS").tag("60")
                Text("120 FPS").tag("120")
            }
            Picker("Bitrate", selection: $settings.bitrate) {
                ForEach(["5000", "10000", "20000", "30000", "40000", "50000"], id: \.self) {
                    Text("\(Int($0)! / 1000) Mbps").tag($0)
                }
            }
            Toggle("Fullscreen (capture system keys)", isOn: $settings.fullscreen)
            Toggle("HEVC (H.265)", isOn: $settings.hevc)
            Toggle("Forward microphone", isOn: $settings.microphone)
        }
        .disabled(session.phase == .pairing || session.phase == .streaming)
    }

    // MARK: Status / actions

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if session.phase.isBusy { ProgressView().controlSize(.small) }
                Text(session.phase.statusText).font(.headline)
            }
            HStack {
                switch session.phase {
                case .idle:
                    Button("Start Cloud PC") {
                        guard let profile = auth.profile, profile.hasPaidPlan else {
                            session.notice = .init(title: "Plan Required", message: "Please buy a plan to continue.")
                            openURL(Config.pricingURL)
                            return
                        }
                        session.start(settings: settings, nightPlan: profile.isNightPlan)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(MoonlightRunner.locate() == nil)
                case .ready:
                    Button("Launch Stream") { session.launchStream(settings: settings) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    Button("Apply Settings to VM") { session.applySettings(settings) }
                    shutDownButton
                default:
                    shutDownButton
                }
            }
            if MoonlightRunner.locate() == nil {
                Text("Moonlight is required for streaming. Install it with `brew install --cask moonlight`.")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var shutDownButton: some View {
        Button("Shut Down", role: .destructive) { session.shutDown() }
            .controlSize(.large)
    }
}
