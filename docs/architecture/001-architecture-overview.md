# ADR 001: Local-first modular Apple architecture

- Status: accepted for Sprint 1 planning
- Date: 2026-08-16

## Context

The repository currently contains only `README.md`; there is no Xcode project, target, package, dependency, or build configuration to preserve. My Journal is iPhone-first but needs a shared journal concept for iPad and Mac, including archives exceeding 100 GB.

## Decision

Create an Xcode workspace with platform app targets and local Swift packages:

```text
MyJournal.xcworkspace
  Apps/
    MyJournalIOS       (iPhone + iPad)
    MyJournalMac       (later archive/management client)
  Packages/
    JournalDomain      (value types, invariants, IDs, protocols; no UI/framework persistence)
    JournalPersistence (Core Data model, repositories, migrations)
    JournalMedia       (asset paths, hashing, recording/playback interfaces)
    JournalFeatures    (use cases/view models, transcription scheduling)
    JournalUI          (SwiftUI views and design system)
    JournalTestSupport (fixtures and temporary journal packages)
```

Use Swift 6 language mode with strict concurrency enabled for newly written code. Use SwiftUI for the application UI and Observation for UI state, but keep domain types and use cases independent from SwiftUI. AVFoundation, Speech, Core Data, Uniform Type Identifiers, and CryptoKit are Apple frameworks, not third-party dependencies.

Use dependency injection at the composition root: features receive repository/service protocols, not global singletons. Keep packages local until a genuine reuse need appears; introduce no third-party dependency in Sprint 1.

## Consequences

The Mac target can later gain archive, repair, and bulk-management workflows without forcing the iPhone UI into desktop parity. Application code can be tested with in-memory stores and temporary media directories. The additional package boundaries are justified by the persistence/media seam, not by speculative feature slicing.

Core Data remains an implementation detail of `JournalPersistence`; `JournalDomain` must not expose `NSManagedObject`.

## Testing architecture

- Unit tests: domain invariants, use cases, metadata mapping, file naming/hash validation.
- Integration tests: temporary Core Data store + temporary journal package; import/export round trips and crash/recovery cases.
- UI tests: critical recording lifecycle and journal-open flows with fake services.
- Performance tests: 60-minute recording, thousands of entries, and import/export fixtures. Do not place 100 GB fixtures in source control; generate representative sparse/segmented fixtures locally.
- Manual device matrix: oldest supported iPhone, current iPhone, iPad, and Mac before platform releases.

## References

- [SwiftData model containers and migration](https://developer.apple.com/documentation/swiftdata/modelcontainer)
- [Swift concurrency](https://developer.apple.com/documentation/swift/concurrency)
