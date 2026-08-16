# ADR 009: Technical risk register

- Status: active
- Date: 2026-08-16

| Rank | Risk | Why it matters | Required action / exit signal |
| --- | --- | --- | --- |
| P0 | Offline transcription capability/performance varies by OS, hardware, locale, and downloaded model. | Transcript availability/energy may make or break the intended experience. | Sprint 1 physical-device spike: offline 5/30/60-minute tests, locale matrix, memory/energy/thermal/time measurements; preserve an unavailable state. |
| P0 | Recording durability under interruption, route change, storage exhaustion, and termination. | Source audio loss is unacceptable. | Build recorder lifecycle tests and manual fault matrix; verify recoverable staging and launch reconciliation before shipping recording. |
| P0 | Archive portability/recovery format not specified early enough. | A private 100+ GB journal needs durable extraction/recovery independent of a backend. | Freeze package invariants (UUIDs, relative paths, hashes, versioned manifest) before source-media persistence. |
| P1 | Core Data schema migration at large-library scale. | Broken migration could strand journals. | Version schema from first release; retain migration fixtures; measure upgrade/rollback/backup process. |
| P1 | Files providers/external volumes have variable availability, performance, and atomicity. | Large exports can fail mid-copy or disappear. | Defer implementation; design resumable, verified staged transfer and test physical media/providers later. |
| P1 | Privacy and encryption/key-management product definition is unresolved. | Journal source data is sensitive; cloud/archive encryption affects format and recovery. | Define threat model, at-rest protection, export encryption, key recovery, and lock policy before any remote archive. |
| P1 | Storage growth from originals plus derived data. | 100+ GB users may run out of space unpredictably. | Establish media format/bitrate budgets, capacity reserve, derived-data eviction/rebuild policy, and archive UX. |
| P2 | Avatar art direction and animation quality. | It does not affect journal correctness. | Prototype only after capture/persistence; start 2D and validate accessibility. |
| P2 | Advanced search/AI metadata (embeddings, diarization, summaries). | Valuable but wholly derived and replaceable. | Add after a source-safe metadata pipeline exists; version/invalidate every output. |

## Recommended next step

Sprint 1 should create the workspace/packages and deliver a **recording durability + local transcription capability spike**, without yet treating transcript output as a required user-facing feature. The spike should end with measured evidence and a narrowed device/locale support promise.
