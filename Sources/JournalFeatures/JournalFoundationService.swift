import Foundation
import JournalDomain
import JournalMedia
import JournalPersistence

/// Coordinates the metadata-before-media protocol used by the recording spike.
public struct JournalFoundationService: Sendable {
    public let package: JournalPackage
    public let store: JournalStore
    public init(package: JournalPackage, store: JournalStore) { self.package = package; self.store = store }

    public func createOfflineJournal(named name: String) throws -> Journal {
        try package.createIfNeeded()
        let journal = Journal(name: name)
        try store.createJournal(journal)
        return journal
    }

    public func prepareAudioRecording(in entry: Entry, assetID: UUID = UUID()) throws -> MediaAsset {
        let stagedURL = package.stagedAudioURL(for: assetID)
        let asset = MediaAsset(id: assetID, entryID: entry.id, kind: .audio, relativePath: try package.relativePath(for: stagedURL), uti: "public.mpeg-4-audio", lifecycle: .recording)
        try store.createAsset(asset)
        return asset
    }

    public func finalizeAudioRecording(_ asset: MediaAsset) throws -> MediaAsset {
        let result = try package.finalize(stagedURL: try package.url(forRelativePath: asset.relativePath), assetID: asset.id)
        try store.markAssetReady(id: asset.id, relativePath: result.relativePath, byteCount: result.byteCount, sha256: result.sha256)
        return MediaAsset(id: asset.id, entryID: asset.entryID, kind: asset.kind, relativePath: result.relativePath, byteCount: result.byteCount, sha256: result.sha256, uti: asset.uti, lifecycle: .ready, createdAt: asset.createdAt)
    }
}
