# My Journal architecture decisions

Sprint 0 establishes boundaries and feasibility only; it implements no product feature.

| ADR | Decision |
| --- | --- |
| [001](001-architecture-overview.md) | SwiftUI clients over framework-agnostic Swift domain/application modules. |
| [002](002-platform-strategy.md) | iOS/iPadOS 17 and macOS 14 baseline; newer capabilities are conditional. |
| [003](003-persistence-and-domain-model.md) | Core Data stores indexed metadata; source media stays in the filesystem. |
| [004](004-media-recording-and-storage.md) | AVFoundation writes original media incrementally to journal-owned packages. |
| [005](005-transcription.md) | Local transcription is optional derived work, using SpeechAnalyzer where available. |
| [006](006-avatar.md) | A data-driven 2D SwiftUI avatar is the first implementation path. |
| [007](007-export-archive-and-migration.md) | A self-describing export package is required alongside Apple migration. |
| [008](008-cloud-boundary.md) | Cloud is an optional encrypted archive adapter, never a runtime dependency. |
| [009](009-risk-register.md) | Risks, owners, and pre-Sprint-1 experiments. |

## Non-negotiable invariants

1. A journal opens and remains usable with no account, network, or cloud service.
2. Original media is immutable source data. Transcripts, previews, search indexes, and AI metadata are replaceable derived data.
3. Database rows reference media by stable asset ID and relative path; they never store the large binary payload.
4. Every import/export and later cloud sync verifies content hashes and preserves provenance.
5. The shared conceptual model is platform-neutral; each platform may ship different workflows.

All recommendations are based on the repository state inspected on 2026-08-16 and current Apple documentation linked in the ADRs. They should be revisited at each major Xcode/OS release.
