import Foundation
import Testing
@testable import JournalDomain
@testable import JournalMedia
@testable import JournalPersistence

@Suite(.serialized) struct JournalPersistenceIntegrationTests {
@Test func metadataAndSourceFileSurviveStoreReopen() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let package = JournalPackage(rootURL: root)
    try package.createIfNeeded()
    let journal = Journal(name: "Offline Journal")
    let entry = Entry(journalID: journal.id, authoredText: "Source text")
    let assetID = UUID()
    let staged = package.stagedAudioURL(for: assetID)
    try Data(repeating: 0x42, count: 2_048).write(to: staged)
    let store = try JournalStore(databaseURL: package.databaseURL)
    try store.createJournal(journal)
    try store.createEntry(entry)
    let recording = MediaAsset(id: assetID, entryID: entry.id, kind: .audio, relativePath: try package.relativePath(for: staged), uti: "public.mpeg-4-audio", lifecycle: .recording)
    try store.createAsset(recording)
    let final = try package.finalize(stagedURL: staged, assetID: assetID)
    try store.markAssetReady(id: assetID, relativePath: final.relativePath, byteCount: final.byteCount, sha256: final.sha256)
    let reopened = try JournalStore(databaseURL: package.databaseURL)
    let assets = try reopened.fetchAssets()
    #expect(assets.count == 1)
    #expect(assets[0].lifecycle == .ready)
    #expect(assets[0].sha256 == final.sha256)
    #expect(FileManager.default.fileExists(atPath: try package.url(forRelativePath: assets[0].relativePath).path))
}

@Test func packageRejectsTraversalPaths() throws {
    let package = JournalPackage(rootURL: FileManager.default.temporaryDirectory)
    #expect(throws: JournalPackageError.self) { try package.url(forRelativePath: "../outside.m4a") }
}
}
