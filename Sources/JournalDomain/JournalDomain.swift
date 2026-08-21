import Foundation

public struct Journal: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public let createdAt: Date
    public var modifiedAt: Date
    public let formatVersion: Int

    public init(id: UUID = UUID(), name: String, createdAt: Date = .now, modifiedAt: Date = .now, formatVersion: Int = 1) {
        self.id = id; self.name = name; self.createdAt = createdAt; self.modifiedAt = modifiedAt; self.formatVersion = formatVersion
    }
}

public struct Entry: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let journalID: UUID
    public var authoredText: String?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(id: UUID = UUID(), journalID: UUID, authoredText: String? = nil, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id; self.journalID = journalID; self.authoredText = authoredText; self.createdAt = createdAt; self.modifiedAt = modifiedAt
    }
}

public enum MediaKind: String, Codable, Sendable { case audio, video, image }
public enum MediaLifecycle: String, Codable, Sendable { case recording, staged, ready, recoverableFailure }

/// Metadata only. `relativePath` is always relative to the owning journal package.
public struct MediaAsset: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let entryID: UUID
    public let kind: MediaKind
    public var relativePath: String
    public var byteCount: Int64
    public var sha256: String?
    public var uti: String
    public var lifecycle: MediaLifecycle
    public let createdAt: Date

    public init(id: UUID = UUID(), entryID: UUID, kind: MediaKind, relativePath: String, byteCount: Int64 = 0, sha256: String? = nil, uti: String, lifecycle: MediaLifecycle, createdAt: Date = .now) {
        self.id = id; self.entryID = entryID; self.kind = kind; self.relativePath = relativePath; self.byteCount = byteCount; self.sha256 = sha256; self.uti = uti; self.lifecycle = lifecycle; self.createdAt = createdAt
    }
}

/// Derived data. It can be discarded/rebuilt without changing source audio.
public struct Transcript: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let mediaAssetID: UUID
    public let sourceSHA256: String
    public let localeIdentifier: String
    public let engineVersion: String
    public var text: String
    public let generatedAt: Date
}
