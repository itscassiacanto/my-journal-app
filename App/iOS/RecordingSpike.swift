import AVFAudio
import Foundation
import JournalDomain
import JournalMedia

@MainActor
final class RecordingSpike: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var status = "Idle"
    private let engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var asset: MediaAsset?
    private var didInstallTap = false

    func start(asset: MediaAsset, package: JournalPackage) throws {
        guard !isRecording else { return }
        try package.createIfNeeded()
        // A conservative admission gate. Runtime write errors are still handled below.
        try package.requireCapacity(64 * 1_024 * 1_024)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .spokenAudio, options: [.allowBluetooth])
        try session.setActive(true)
        let url = try package.url(forRelativePath: asset.relativePath)
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw RecordingError.noInputRoute }
        file = try AVAudioFile(forWriting: url, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        self.asset = asset
        input.installTap(onBus: 0, bufferSize: 4_096, format: format) { [weak self] buffer, _ in
            // This callback deliberately does only incremental disk I/O; never touch SwiftUI/Core Data here.
            do { try self?.file?.write(from: buffer) }
            catch { Task { @MainActor [weak self] in self?.fail(error) } }
        }
        didInstallTap = true
        engine.prepare(); try engine.start()
        NotificationCenter.default.addObserver(self, selector: #selector(interruption(_:)), name: AVAudioSession.interruptionNotification, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange(_:)), name: AVAudioSession.routeChangeNotification, object: session)
        isRecording = true; status = "Recording incrementally to staging"
    }

    func stop() throws -> MediaAsset {
        guard let asset else { throw RecordingError.notRecording }
        cleanupAudio()
        self.asset = nil; status = "Staging file closed; ready to hash and atomically finalize"
        return asset
    }

    @objc private func interruption(_ notification: Notification) {
        guard isRecording else { return }
        cleanupAudio()
        status = "Interrupted. Staging file remains for recovery; do not auto-resume."
    }
    @objc private func routeChange(_ notification: Notification) {
        guard isRecording else { return }
        cleanupAudio()
        status = "Audio route changed. Staging file remains for recovery; explicit restart required."
    }
    private func fail(_ error: Error) { cleanupAudio(); status = "Write failed; staging file retained: \(error.localizedDescription)" }
    private func cleanupAudio() {
        if didInstallTap { engine.inputNode.removeTap(onBus: 0); didInstallTap = false }
        engine.stop(); file = nil; isRecording = false
        NotificationCenter.default.removeObserver(self)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
enum RecordingError: LocalizedError { case noInputRoute, notRecording; var errorDescription: String? { self == .noInputRoute ? "No usable audio input route." : "No recording is active." } }
