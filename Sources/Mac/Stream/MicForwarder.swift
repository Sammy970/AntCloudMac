import AVFoundation
import Network

/// Captures the default microphone and sends raw 44.1 kHz / 16-bit / mono PCM over UDP
/// to the VM, matching the Windows client's NAudio WaveInEvent → UdpClient pipeline.
final class MicForwarder {
    private let engine = AVAudioEngine()
    private var connection: NWConnection?
    private var converter: AVAudioConverter?
    private let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44_100, channels: 1, interleaved: true)!

    func start(host: String, port: UInt16 = Config.micPort) async throws {
        guard await AVCaptureDevice.requestAccess(for: .audio) else {
            throw APIError(status: 0, message: "Microphone access was denied. Enable it in System Settings → Privacy & Security → Microphone.")
        }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .udp)
        connection.start(queue: .global(qos: .userInteractive))
        self.connection = connection

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inputFormat, to: outputFormat)

        input.installTap(onBus: 0, bufferSize: 4410, format: inputFormat) { [weak self] buffer, _ in
            self?.forward(buffer)
        }
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        connection?.cancel()
        connection = nil
    }

    private func forward(_ buffer: AVAudioPCMBuffer) {
        guard let converter, let connection else { return }
        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else { return }

        var consumed = false
        converter.convert(to: out, error: nil) { _, status in
            if consumed { status.pointee = .noDataNow; return nil }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        guard out.frameLength > 0, let samples = out.int16ChannelData?[0] else { return }
        let data = Data(bytes: samples, count: Int(out.frameLength) * 2)
        connection.send(content: data, completion: .idempotent)
    }
}
