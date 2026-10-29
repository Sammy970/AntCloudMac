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
                    .reveal(0)
                    .padding(.bottom, 28)

                VStack(spacing: 6) {
                    Text(session.phase.statusText)
                        .font(.title2.weight(.semibold))
                    Text(session.phase.detailText)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .id(session.phase.screenState)
                .transition(.opacity.combined(with: .offset(y: 6)))
                .reveal(0.08)
                .padding(.bottom, 22)

                ConnectionTrack(phase: session.phase)
                    .frame(maxWidth: 400)
                    .reveal(0.14)
                    .padding(.bottom, 28)

                actions
                    .reveal(0.2)
                    .padding(.bottom, 18)

                streamSummary
                    .reveal(0.26)

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
                        .secondaryGlassButton()
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
        .primaryGlassButton()
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
    }

    private var shutDown: some View {
        Button(role: .destructive) { session.shutDown() } label: {
            Text(session.phase.isBusy ? "Cancel" : "Shut Down").foregroundStyle(.red)
        }
        .secondaryGlassButton()
    }

    private func start() {
        guard let profile = auth.profile, profile.hasPaidPlan else {
            session.notice = .init(title: "Plan Required", message: "Please buy a plan to continue.")
            openURL(Config.pricingURL)
            return
        }
        Task { await session.startIfAllowed(settings: settings, nightPlan: profile.isNightPlan) }
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
