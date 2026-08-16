# ADR 007: Archive, Files, and migration strategy

- Status: accepted for design; implementation deferred
- Date: 2026-08-16

## Decision

Treat an internal journal package as the unit of export, verification, backup, and later sync. Define a versioned, self-describing `.myjournal` package (or archive wrapping it) containing the manifest, metadata store/export, source files, derived files, and hashes. A manifest lists every file’s relative path, byte count, SHA-256, schema/package versions, and export provenance. Import always stages, verifies hashes/space/schema, and commits atomically; it never merges unverified paths into the active journal.

Apple device migration/restore should move the sandboxed app and its data for **iPhone → iPhone** and generally restore it onto **iPhone → iPad** when the app is universal, subject to the user’s selected backup/transfer path and available storage. That is helpful but not an archive contract. An independent export/import is mandatory for durable ownership, recovery, platform transition, and future Mac transfer. **iPhone → Mac is not an app-container migration mechanism**; it needs the package import/export path.

## Files and external storage

On iPhone/iPad, use `UIDocumentPickerViewController`/SwiftUI file import-export APIs for explicit user-directed import/export. The user’s Files provider can represent local storage, USB-C drives, external SSDs, network/NAS providers, and cloud providers; the app must not assume it is local, always mounted, fast, or writable. Coordinate access and balance security-scoped URL access. Copy source material into staging rather than holding external provider URLs as first-class journal assets.

On Mac, Finder/open-save panels and security-scoped bookmarks support archive locations and later archive management. The Mac app may implement resumable, verified copy jobs and repair tooling; it should not demand that iPhone perform enormous archive operations in the foreground.

## Network/NAS and large operations

Do not build a raw NAS protocol client in Sprint 1. A Files provider may offer NAS access, but provider behavior/atomicity/resume semantics vary. Later options are: user-mediated Files export, a local-network peer transfer protocol with explicit pairing/encryption/resume, or a separately designed archive adapter. All bulk copy must be chunked, cancellable, progress-reporting, restartable from a manifest checkpoint, and verified by hash—not by timestamps alone.

## Scope discipline

No Files picker, external drive, network transfer, migration UI, or archive format implementation belongs in Sprint 0. Sprint 1 must preserve relative asset paths, stable IDs, hashes, versioned schema, and non-BLOB source assets so this decision remains implementable.

## References

- [Files and directories](https://developer.apple.com/documentation/technologyoverviews/files-and-directories)
- [Security-scoped URLs](https://developer.apple.com/documentation/foundation/nsurl#1650444)
- [Document picker](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller)
