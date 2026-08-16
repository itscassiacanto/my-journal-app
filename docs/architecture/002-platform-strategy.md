# ADR 002: Platform and deployment strategy

- Status: accepted for Sprint 1 planning
- Date: 2026-08-16

## Decision

Set the initial deployment targets to **iOS/iPadOS 17.0** and **macOS 14.0**. Ship one universal iOS/iPadOS target, with idiomatic navigation/layout rather than promised feature parity. Add a separate macOS target only when archive/management workflows begin.

The baseline supports SwiftUI, Swift concurrency, Core Data, AVFoundation, Files integration, and current Speech-framework fallback APIs. New APIs are wrapped in availability-gated adapters. In particular, `SpeechAnalyzer` / `SpeechTranscriber` is not a baseline contract: it must be selected at runtime only on supported OS/hardware/locale combinations.

## Why not a shared UI target?

Share domain, persistence, media, and feature logic. Share individual SwiftUI components only where their interaction model is identical. iPhone is capture-first; the future Mac is archive/management-first. A common UI shell would couple two deliberately different products.

## Configuration

- Xcode-generated signing and entitlements per app target; no cloud entitlement in Sprint 1.
- `NSMicrophoneUsageDescription` is required before recording. Add speech-recognition usage text only when requesting the applicable Speech authorization/API.
- Enable Background Modes > Audio only for an explicit recording feature and verify background behavior on hardware; it is not a general execution guarantee.
- Use TestFlight/device testing for audio routes, interruptions, thermal state, and disk-full behavior; simulators are insufficient.

## Future compatibility

The deployment baseline is a product decision, not a data-format decision. The journal package format, Core Data model migrations, IDs, hashes, and manifest must remain readable by newer app versions and by the later Mac client.

## Open validation

Before code that adopts the new Speech APIs, record the exact Xcode SDK availability annotations and supported hardware/locale behavior in an implementation ADR. Apple exposes availability through the API itself, so support must be probed rather than hard-coded.

## References

- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [SpeechTranscriber availability](https://developer.apple.com/documentation/speech/speechtranscriber/isavailable)
