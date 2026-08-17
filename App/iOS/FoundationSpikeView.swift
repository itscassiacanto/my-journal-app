import SwiftUI
import JournalDomain
import JournalFeatures
import JournalMedia
import JournalPersistence

@MainActor
final class FoundationSpikeModel: ObservableObject {
    @Published private(set) var status = "Preparing local journal…"
    @Published private(set) var journalPath = ""
    @Published private(set) var transcriptionReport = "Checking device…"
    let recorder = RecordingSpike()
    private var service: JournalFoundationService?
    private var journal: Journal?

    func prepare() {
        do {
            let root = try Self.defaultPackageURL()
            let package = JournalPackage(rootURL: root)
            let store = try JournalStore(databaseURL: package.databaseURL)
            let service = JournalFoundationService(package: package, store: store)
            self.service = service
            journal = try service.createOfflineJournal(named: "My Journal")
            journalPath = root.path
            status = "Offline journal is ready. Metadata uses SQLite; media remains in the package."
            Task { [weak self] in
                self?.transcriptionReport = await TranscriptionCapabilityProbe.report()
            }
        } catch { status = "Preparation failed: \(error.localizedDescription)" }
    }

    func startRecording() {
        guard let service, let journal else { prepare(); return }
        do {
            let entry = Entry(journalID: journal.id)
            try service.store.createEntry(entry)
            let asset = try service.prepareAudioRecording(in: entry)
            try recorder.start(asset: asset, package: service.package)
            status = "Recording to recoverable staging file."
        } catch { status = "Could not start recording: \(error.localizedDescription)" }
    }

    func stopRecording() {
        guard let service else { return }
        do {
            let asset = try recorder.stop()
            _ = try service.finalizeAudioRecording(asset)
            status = "Finalized original audio and hash."
        } catch { status = "Finalization preserved recovery state: \(error.localizedDescription)" }
    }

    private static func defaultPackageURL() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return base.appendingPathComponent("MyJournal", isDirectory: true).appendingPathComponent("Journal-local", isDirectory: true)
    }
}

struct FoundationSpikeView: View {
    @StateObject private var model = FoundationSpikeModel()
    var body: some View {
        NavigationStack {
            Form {
                Section("Local-first foundation") {
                    Text(model.status)
                    if !model.journalPath.isEmpty { Text(model.journalPath).font(.footnote).textSelection(.enabled) }
                    Button("Prepare offline journal") { model.prepare() }
                }
                Section("Recording durability spike") {
                    Text(model.recorder.status)
                    Button("Start staged recording") { model.startRecording() }.disabled(model.recorder.isRecording)
                    Button("Stop and finalize") { model.stopRecording() }.disabled(!model.recorder.isRecording)
                    Text("Use the Sprint 1 protocol for 5/30/60-minute, interruption, route-change, storage, and recovery runs.").font(.footnote)
                }
                Section("On-device transcription capability") { Text(model.transcriptionReport).font(.footnote) }
            }
            .navigationTitle("Foundation Spike")
            .onAppear { model.prepare() }
        }
    }
}
