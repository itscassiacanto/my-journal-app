# ADR 005: On-device transcription as derived work

- Status: accepted with validation gate
- Date: 2026-08-16

## Decision

Use Apple Speech as the only planned initial transcription integration. Prefer the modern local `SpeechAnalyzer` + `SpeechTranscriber` path where the installed OS, device, locale, and downloaded assets report support. The `timeIndexedTranscriptionWithAlternatives` preset is appropriate for finalized journal audio because it retains audio time ranges; use a progressive preset only for optional live, non-authoritative display.

On baseline/unsupported devices, evaluate `SFSpeechRecognizer` only as a capability-gated fallback during Sprint 1 spike. It must be configured for on-device recognition when available and must not silently route journal audio to a network service. If a local path is unavailable, recording still succeeds and the UI records `transcription unavailable`; there is no third-party cloud fallback.

## Pipeline

Persist an immutable original audio asset first. Enqueue a low-priority derived job after recording finalizes (and preferably when charging/thermal/storage conditions allow). The worker streams/feeds audio in bounded buffers, persists checkpointable transcript segments, and only marks a transcript version ready after it is associated with the exact source SHA-256 and engine/model version.

The default is **after recording**, not concurrent transcription. This protects capture latency, battery, memory, and audio-session reliability for 5–60 minute sessions. A later live transcript may consume a bounded duplicate of the capture buffers, but it is optional UI and must be replaceable by the post-recording final pass.

## Capability, language, and resource policy

Do not publish a static supported-language list. At runtime, query `SpeechTranscriber.supportedLocales` (downloadable) and `installedLocales` (currently usable), then let the user choose/install a supported locale. Asset Inventory manages Apple-provided downloadable models and locale reservations; assets can be released later by the system. The app must show download size/progress/error where the API provides it and never assume an asset is already present.

Apple reports availability based on device hardware/capabilities and limits concurrent backing engines on iOS/visionOS to roughly two incompatible ongoing instances. Therefore, enforce one journal transcription job per device, no unbounded parallel queue, cancellation, thermal/low-power deferral, and a memory/battery performance measurement on the oldest supported device. Persisted source audio makes retries safe.

## Known limitations / validation gate

Quality, exact available locales, model storage footprint, model download conditions, diarization support, and real-time factor vary by OS/device/locale and cannot be assumed. Sprint 1 must run a documented spike on physical devices with 5-, 30-, and 60-minute recordings: measure wall time, peak memory, energy/thermal state, battery impact, model download/install behavior, offline behavior after install, and timestamp accuracy. This is P0 before making transcript completion an MVP promise.

## References

- [SpeechTranscriber](https://developer.apple.com/documentation/speech/speechtranscriber/)
- [SpeechTranscriber presets](https://developer.apple.com/documentation/speech/speechtranscriber/preset)
- [Speech asset inventory](https://developer.apple.com/documentation/speech/assetinventory)
- [SpeechAnalyzer module limits](https://developer.apple.com/documentation/speech/speechanalyzer/setmodules(_:))
