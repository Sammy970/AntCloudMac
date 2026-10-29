import AppKit
import SwiftUI

/// The play-first pane: a drawn display showing the session state, the connection track and the one next action.
struct CloudPCPane: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.openURL) private var openURL
    @ObservedObject var session: SessionService
    let settings: StreamSettings
    let editSettings: () -> Void

    private let moonlightInstalled = MoonlightRunner.locate() != nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                DisplayHero(phase: session.phase)
                    .frame(width: 340)
                    .padding(.bottom, 28)

                VStack(spacing: 6) {
                    Text(session.phase.statusText)
                        .font(.title2.weight(.semibold))
                    Text(session.phase.detailText)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 22)

                ConnectionTrack(phase: session.phase)
                    .frame(maxWidth: 400)
                    .padding(.bottom, 28)

                actions
                    .padding(.bottom, 18)

                streamSummary

                if !moonlightInstalled {
                    MoonlightMissing()
                        .frame(maxWidth: 440)
                        .padding(.top, 28)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: session.phase)
        }
        .navigationTitle("Cloud PC")
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 10) {
            switch session.phase {
            case .idle:
                primary("Start Cloud PC", systemImage: "power", action: start)
                    .disabled(!moonlightInstalled)
            case .ready:
                primary("Launch Stream", systemImage: "play.fill") { session.launchStream(settings: settings) }
                HStack(spacing: 8) {
                    Button("Apply Settings to PC") { session.applySettings(settings) }
                    shutDown
                }
                .controlSize(.regular)
            case .streaming:
                shutDown.controlSize(.large)
            default:
                shutDown.controlSize(.large)
            }
        }
    }

    private func primary(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 220)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
    }

    private var shutDown: some View {
        Button(role: .destructive) { session.shutDown() } label: {
            Text(session.phase.isBusy ? "Cancel" : "Shut Down").foregroundStyle(.red)
        }
    }

    private func start() {
        guard let profile = auth.profile, profile.hasPaidPlan else {
            session.notice = .init(title: "Plan Required", message: "Please buy a plan to continue.")
            openURL(Config.pricingURL)
            return
        }
        session.start(settings: settings, nightPlan: profile.isNightPlan)
    }

    // MARK: Stream summary

    private var streamSummary: some View {
        HStack(spacing: 6) {
            Text(settings.summary)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Button("Change…", action: editSettings)
                .buttonStyle(.link)
        }
        .font(.callout)
    }
}

// MARK: - Display hero

/// A monitor whose screen shows the session state. The app's one illustration.
struct DisplayHero: View {
    let phase: SessionService.Phase

    var body: some View {
        VStack(spacing: 0) {
            screen
                .aspectRatio(16 / 10, contentMode: .fit)
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.11)], startPoint: .top, endPoint: .bottom))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.22), radius: 18, y: 10)

            // Stand: neck and foot.
            Rectangle()
                .fill(LinearGradient(colors: [Color(white: 0.62), Color(white: 0.78)], startPoint: .top, endPoint: .bottom))
                .frame(width: 54, height: 26)
            Capsule()
                .fill(LinearGradient(colors: [Color(white: 0.82), Color(white: 0.66)], startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 7)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phase.statusText)
    }

    private var screen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(background)
            content.transition(.opacity)
            // Glass reflection.
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .center))
        }
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var background: LinearGradient {
        switch phase {
        case .ready, .pairing:
            LinearGradient(colors: [Color.antBlue, Color(red: 0.18, green: 0.36, blue: 0.75)], startPoint: .top, endPoint: .bottom)
        case .streaming:
            LinearGradient(colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.02, green: 0.03, blue: 0.06)], startPoint: .top, endPoint: .bottom)
        case .idle:
            LinearGradient(colors: [Color(white: 0.09), Color(white: 0.04)], startPoint: .top, endPoint: .bottom)
        default:
            LinearGradient(colors: [Color(red: 0.07, green: 0.11, blue: 0.2), Color(red: 0.03, green: 0.05, blue: 0.1)], startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            Image(systemName: "power")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.white.opacity(0.22))
        case .connecting, .queued, .booting:
            ZStack {
                ScanBand()
                VStack(spacing: 8) {
                    if case .queued(let position?) = phase {
                        Text("#\(position)")
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text("in queue").font(.caption).foregroundStyle(.white.opacity(0.6))
                    } else {
                        Image(systemName: phase == .booting ? "cpu" : "antenna.radiowaves.left.and.right")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        case .ready:
            Image(systemName: "play.circle.fill")
                .font(.system(size: 54, weight: .regular))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.antBlue, .white)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        case .pairing:
            ZStack {
                ScanBand()
                Image(systemName: "link")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }
        case .streaming:
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    PulsingDot(color: .green)
                    Text("LIVE")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                }
                Text("Playing in Moonlight")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

/// A soft band of brand light sweeping down the screen while the PC is working.
private struct ScanBand: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4
            GeometryReader { geo in
                LinearGradient(colors: [.clear, Color.antBlue.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 0.45)
                    .offset(y: geo.size.height * (t * 1.45 - 0.45))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct PulsingDot: View {
    let color: Color
    @State private var on = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .background(Circle().fill(color.opacity(0.4)).scaleEffect(on ? 2.4 : 1).opacity(on ? 0 : 1))
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { on = true }
            }
    }
}

// MARK: - Connection track

/// Connect → Boot → Ready → Stream, with the current step highlighted.
struct ConnectionTrack: View {
    let phase: SessionService.Phase

    private static let steps = ["Connect", "Boot", "Ready", "Stream"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.steps.indices, id: \.self) { i in
                if i > 0 {
                    Capsule()
                        .fill(i <= phase.completedSteps ? Color.antBlue : Color.secondary.opacity(0.25))
                        .frame(height: 2)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 20)
                }
                step(i)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(min(phase.completedSteps + 1, 4)) of 4")
    }

    private func step(_ i: Int) -> some View {
        let done = i < phase.completedSteps
        let current = i == phase.currentStep
        return VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(done ? Color.antBlue : Color.clear)
                    .overlay(Circle().strokeBorder(done || current ? Color.antBlue : Color.secondary.opacity(0.35), lineWidth: 1.5))
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                } else if current {
                    PulsingDot(color: .antBlue)
                }
            }
            .frame(width: 18, height: 18)
            Text(Self.steps[i])
                .font(.caption)
                .foregroundStyle(done || current ? .primary : .secondary)
        }
        .fixedSize()
    }
}

extension SessionService.Phase {
    /// Steps of the connection track that are finished.
    var completedSteps: Int {
        switch self {
        case .idle, .connecting, .queued: 0
        case .booting: 1
        case .ready, .pairing: 3
        case .streaming: 4
        }
    }

    /// The step in progress, or nil when nothing is moving.
    var currentStep: Int? {
        switch self {
        case .connecting, .queued: 0
        case .booting: 1
        case .pairing: 3
        default: nil
        }
    }

    var detailText: String {
        switch self {
        case .idle: "Start it when you're ready to play."
        case .connecting: "Reaching the AntCloud servers."
        case .queued: "All servers are busy. Your PC starts as soon as one frees up."
        case .booting: "Windows is starting on your cloud PC."
        case .ready: "Launch the stream to start playing."
        case .pairing: "Pairing Moonlight with your cloud PC. No PIN needed."
        case .streaming: "Moonlight is showing your cloud PC in its own window."
        }
    }

    var busyLabel: String {
        switch self {
        case .queued: "Waiting in Queue"
        case .booting: "Starting"
        case .pairing: "Pairing"
        default: "Connecting"
        }
    }
}

extension StreamSettings {
    /// "1080p · 16:9 · 60 FPS · 20 Mbps · HEVC"
    var summary: String {
        let res = resolution == "2160" ? "4K" : "\(resolution)p"
        let mbps = (Int(bitrate) ?? 0) / 1000
        return [res, aspect.rawValue, "\(fps) FPS", "\(mbps) Mbps", hevc ? "HEVC" : "H.264"].joined(separator: " · ")
    }
}

// MARK: - Moonlight missing

private struct MoonlightMissing: View {
    private let command = "brew install --cask moonlight"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 6) {
                Text("Moonlight is required to stream").font(.callout.weight(.semibold))
                Text("Install it, then reopen AntCloud.").font(.callout).foregroundStyle(.secondary)
                HStack {
                    Text(command).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                    Spacer()
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(command, forType: .string)
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.orange.opacity(0.25)))
    }
}
