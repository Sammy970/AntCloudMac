import Foundation

/// macOS stream driver: pairs and streams through the Moonlight CLI and optionally forwards the mic.
@MainActor
final class MoonlightDriver: StreamDriver {
    private let moonlight = MoonlightRunner()
    private var mic: MicForwarder?

    func run(host: String, settings: StreamSettings, session: SessionService) async throws {
        if settings.microphone {
            let mic = MicForwarder()
            do {
                try await mic.start(host: host)
                self.mic = mic
            } catch {
                session.notice = .init(title: "Microphone", message: error.localizedDescription)
            }
        }
        defer { stopMic() }

        let skippedPairing = MoonlightRunner.isPaired(host: host)
        if skippedPairing {
            Log.info("[moonlight] \(host) already paired, skipping pair")
        } else {
            try await pair(host: host, api: session.api)
        }
        try Task.checkCancellation()

        session.markStreaming()
        let args = settings.moonlightStreamArgs(host: host)
        Log.info("[moonlight] \(args.joined(separator: " "))")
        let started = Date.now
        var status = try await moonlight.stream(args)
        Log.info("[moonlight] stream exited with \(status)")

        // A stale saved pairing (e.g. the VM was re-provisioned) fails fast — pair and retry once.
        if skippedPairing, status != 0, Date.now.timeIntervalSince(started) < 15, !Task.isCancelled {
            Log.info("[moonlight] stream failed quickly, re-pairing")
            session.markPairing()
            try await pair(host: host, api: session.api)
            session.markStreaming()
            status = try await moonlight.stream(args)
            Log.info("[moonlight] stream exited with \(status)")
        }
    }

    func stop() {
        moonlight.terminate()
        stopMic()
    }

    private func stopMic() {
        mic?.stop()
        mic = nil
    }

    /// Starts `Moonlight pair` with a random PIN and, in parallel, submits that PIN to the
    /// backend until it reports Sunshine accepted it — the same handshake the Windows client uses.
    private func pair(host: String, api: APIClient) async throws {
        let pin = String(format: "%04d", Int.random(in: 1000...9999))
        let submitPin = Task {
            try await Task.sleep(for: .seconds(2))
            while !Task.isCancelled {
                if (try? await api.vmAuth(pin: pin)) == true { return }
                try await Task.sleep(for: .seconds(3))
            }
        }
        defer { submitPin.cancel() }
        Log.info("[moonlight] pair \(host)")
        let status = try await moonlight.pair(host: host, pin: pin)
        Log.info("[moonlight] pair exited with \(status) (non-zero is expected if already paired)")
    }
}
