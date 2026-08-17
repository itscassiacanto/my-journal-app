import CryptoKit
import Foundation
import JournalDomain

public enum JournalPackageError: Error, LocalizedError, Sendable {
    case unsafeRelativePath
    case insufficientCapacity(required: Int64, available: Int64)
    case missingSource
    public var errorDescription: String? {
        switch self {
        case .unsafeRelativePath: "Unsafe journal-relative path."
        case let .insufficientCapacity(required, available): "Need \(required) bytes; only \(available) are available."
        case .missingSource: "Source media is missing."
        }
    }
}

public struct JournalPackage: Sendable {
    public let rootURL: URL
    public init(rootURL: URL) { self.rootURL = rootURL }
    public var stagingURL: URL { rootURL.appendingPathComponent("Staging", isDirectory: true) }
    public var mediaURL: URL { rootURL.appendingPathComponent("Media", isDirectory: true) }
    public var derivedURL: URL { rootURL.appendingPathComponent("Derived", isDirectory: true) }
    public var databaseURL: URL { rootURL.appendingPathComponent("metadata.sqlite") }

    public func createIfNeeded() throws {
        let fm = FileManager.default
        for url in [rootURL, stagingURL, mediaURL, derivedURL] { try fm.createDirectory(at: url, withIntermediateDirectories: true) }
    }

    public func stagedAudioURL(for assetID: UUID) -> URL { stagingURL.appendingPathComponent("\(assetID.uuidString).m4a.partial") }
    public func finalAudioURL(for assetID: UUID) -> URL { mediaURL.appendingPathComponent(assetID.uuidString, isDirectory: true).appendingPathComponent("source.m4a") }

    public func relativePath(for url: URL) throws -> String {
        let root = rootURL.standardizedFileURL.path + "/"
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(root) else { throw JournalPackageError.unsafeRelativePath }
        return String(path.dropFirst(root.count))
    }

    public func url(forRelativePath path: String) throws -> URL {
        guard !path.hasPrefix("/"), !path.split(separator: "/").contains("..") else { throw JournalPackageError.unsafeRelativePath }
        return rootURL.appendingPathComponent(path)
    }

    public func availableCapacity() throws -> Int64 {
        let values = try rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values.volumeAvailableCapacityForImportantUsage ?? 0
    }

    public func requireCapacity(_ bytes: Int64, reserve: Int64 = 128 * 1_024 * 1_024) throws {
        let available = try availableCapacity()
        guard available >= bytes + reserve else { throw JournalPackageError.insufficientCapacity(required: bytes + reserve, available: available) }
    }

    public func finalize(stagedURL: URL, assetID: UUID) throws -> (relativePath: String, byteCount: Int64, sha256: String) {
        guard FileManager.default.fileExists(atPath: stagedURL.path) else { throw JournalPackageError.missingSource }
        let finalURL = finalAudioURL(for: assetID)
        try FileManager.default.createDirectory(at: finalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: stagedURL, to: finalURL)
        let size = try finalURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0
        return (try relativePath(for: finalURL), size, try Self.sha256(of: finalURL))
    }

    /// Reads fixed-size chunks; no whole-file media load occurs.
    public static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hash = SHA256()
        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty { hash.update(data: data) }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
