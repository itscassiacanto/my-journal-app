# ADR 008: Optional cloud archive boundary

- Status: accepted
- Date: 2026-08-16

## Decision

Cloud is not configured, implemented, entitled, or required in Sprint 0/1. The application owns the local journal package and exposes a future `ArchiveTransport` adapter boundary:

```text
Local Journal Package -> Export Snapshot / Change Manifest -> ArchiveTransport -> encrypted remote archive
```

The local repository and media store never read through a remote API. The app remains fully functional when signed out, offline, remote storage is unavailable, or an archive adapter fails. The adapter may upload/download verified immutable content objects and signed manifests, but it cannot mutate source media in place.

## Contract to preserve now

- A snapshot exporter produces a consistent manifest plus content-addressed/chunk-addressed files from the local journal.
- An importer verifies version, hashes, available space, and compatibility in staging before creating local records.
- Transport input/output contains encrypted bytes and opaque object identifiers; it does not receive live Core Data contexts or UI models.
- Credentials, account selection, encryption keys, retry policy, conflict policy, and remote retention live outside the domain/persistence packages.
- Sync state is derived operational metadata, never required to open the journal.

End-to-end encryption design, key recovery, multi-device conflict resolution, and provider choice remain later product/security decisions. Do not add CloudKit merely because SwiftData/Core Data can integrate with it; that would prematurely entangle local schema behavior with an unresolved archive product.
