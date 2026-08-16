# ADR 003: Metadata database and conceptual domain model

- Status: accepted for Sprint 1 planning
- Date: 2026-08-16

## Decision

Use **Core Data with a SQLite persistent store** for small, queryable, relational metadata. Do not use SwiftData as the primary store for this archive-critical v1: Core Data provides the more established control surface for explicit SQLite configuration, persistent-history/batch maintenance, mature migration tooling, and direct coexistence with a large filesystem asset store. This is not a rejection of SwiftUI; SwiftUI consumes repository-provided observation/state.

Disable external binary storage for media by policy: no source audio/video/image `Data` attributes in the database. The SQLite store contains IDs, paths, hashes, dimensions/durations, and state only. Its size must stay comparatively small and feasible to back up/export separately.

## Conceptual model

All identities are UUIDs (stored in a stable textual/binary form); creation/update timestamps use UTC. Relationships use delete rules that protect source media: deleting an entry marks assets eligible for a recoverable garbage-collection process, rather than unlinking files inline.

| Entity | Essential fields and relationships |
| --- | --- |
| `Journal` | `id`, `name`, `createdAt`, `modifiedAt`, `formatVersion`; owns entries, tags, people, places, and journal settings. |
| `Entry` | `id`, `journalID`, `createdAt`, `modifiedAt`, optional authored text, ordering/time-zone data; links to `MediaAsset`, `Transcript`, tags, people, places, and `DerivedMetadata`. |
| `MediaAsset` | Base record: `id`, `entryID`, `kind`, `relativePath`, `byteCount`, `SHA-256`, MIME/UTI, created/captured timestamps, lifecycle state. |
| `AudioAsset` | Media subtype/detail: codec, sample rate, channel count, duration, recording route; retains the original audio file. |
| `VideoAsset` | Future detail: codec/container, duration, dimensions, frame rate; retains the original video file. |
| `ImageAsset` | Future detail: UTI, pixel dimensions, orientation, capture metadata policy; retains the original image file. |
| `Transcript` | Derived version linked to exactly one source media asset: `id`, locale, engine/version, status, plain text, timestamped segments, source hash, generatedAt. Multiple versions may exist. |
| `Tag` | `id`, `journalID`, normalized name, display name, color; many-to-many entries. |
| `Person` | `id`, `journalID`, display name, aliases; many-to-many entries/metadata assertions. |
| `Place` | `id`, `journalID`, display name, optional coordinates/place-provider identifier and accuracy; many-to-many entries. Precise location is opt-in sensitive data. |
| `DerivedMetadata` | `id`, `entryID` or `mediaAssetID`, `kind`, versioned payload, source hash, generator ID/version, generatedAt, status/confidence. |

`AudioAsset`, `VideoAsset`, and `ImageAsset` should be represented initially as a `MediaAsset` entity with one kind-specific detail entity or typed value object, not Core Data inheritance unless profiling establishes a benefit. This avoids fragile hierarchy migrations.

## Source versus derived data

**Source data:** original media file bytes, user-authored entry text, user-entered tags/people/places, capture timestamps, and user edits. Source is never overwritten by a transcription or AI pass.

**Derived data:** transcript text/segments, audio waveform, thumbnails, embeddings, summaries, topic/sentiment/extracted entities, OCR, search indexes, and duplicate detections. Each derived record must identify its input asset/version hash and generator version, and can be invalidated/rebuilt without harming the journal.

## Operational requirements

Use repository APIs and background model contexts/actors for I/O. Save metadata transactions explicitly around recording state transitions. Enable persistent history only when a concrete consumer (later sync, widgets, import monitor) needs it. Migration policy: lightweight migration for additive compatible changes; versioned mapping/custom migration plus journal backup for destructive or semantic changes. Exercise every migration with real historic fixtures.

## Rejected alternatives

- **Files only / JSON manifest:** easy initially, but poor indexed queries, relationship integrity, and concurrent mutation handling.
- **SwiftData primary store:** attractive for SwiftUI, but not selected for the archive foundation because its operational/migration behavior has less long-lived production maturity for this use case. It can be evaluated later behind repository protocols.
- **Media BLOBs in SQLite/Core Data:** unacceptable for 100+ GB source archives and streaming access.

## References

- [Core Data programming guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [Files and directories](https://developer.apple.com/documentation/technologyoverviews/files-and-directories)
- [SwiftData model storage](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches)
