# ADR 004: Media package and audio recording lifecycle

- Status: accepted for Sprint 1 planning
- Date: 2026-08-16

## Journal package layout

The app-private journal root lives in Application Support, not Cache or a database BLOB:

```text
Journal-<uuid>/
  manifest.json                  # small, versioned; hashes and package metadata
  metadata.sqlite                # Core Data SQLite + sidecars
  Media/<asset-uuid>/source.m4a  # original source; future source.mov/source.heic
  Derived/<asset-uuid>/...       # transcript, waveform, thumbnail, indexes
  Staging/<recording-uuid>.m4a.partial
  Trash/                         # recoverable deletion until retention expires
```

Use opaque UUID path components, relative paths in the database, atomic rename from `Staging` to `Media`, and `NSFileCoordinator` whenever a document-provider/external URL is involved. Do not treat a temporary directory as durable recording storage.

## Recording decision

For the initial voice journal, use `AVAudioEngine` input capture with an `AVAudioFile` writer to an `.m4a`/AAC-LC destination (mono, speech-appropriate bitrate chosen after device quality tests). This supports incremental writes, one capture stream being safely forked to later live meters/transcription, and richer route/error control than `AVAudioRecorder`. Use `AVAudioPlayer` for straightforward asset playback; promote to `AVAudioEngine`/`AVAudioPlayerNode` only where scrubbing, audio processing, or synchronized analysis warrants it.

The render/tap callback is real-time-sensitive: it does no database work, hashing, UI work, or async blocking. It appends buffers to the file writer; a serial recorder actor/queue owns lifecycle state. Apple documents that input is received through `AVAudioEngine.inputNode` and taps can receive buffers off the main thread.

## Lifecycle and recovery

1. Check microphone permission, available capacity (with a conservative reserve), writable staging URL, and configure/activate `AVAudioSession` (`.record` or `.playAndRecord` after route tests).
2. Create a database `MediaAsset` in `recording` state and a staging file before starting the engine. Persist a lightweight recovery marker.
3. Write buffers incrementally. Update elapsed UI from render time, not file-size guesses. Flush/checkpoint metadata periodically on a non-real-time queue.
4. Observe audio-session interruption, route-change, media-services-reset, and app lifecycle notifications. Stop/finalize safely on interruption; resume only after an explicit, valid reactivation policy. A phone call, AirPods route switch, and media-services reset are separate cases.
5. On stop, drain/close file, calculate SHA-256 by streamed read, validate duration/readability, atomically move to final location, then commit the asset as `ready`. If finalization fails, keep the staging file and an actionable recovery state.
6. On next launch, reconcile incomplete markers/staging files; offer recovery or deletion only after inspection. Never silently discard a possibly valid recording.

## Background and storage limits

The audio background mode permits active recording but does not guarantee indefinite execution or survival of termination. The app must be foreground-tested and resilient to suspension/termination. Background tasks are appropriate for deferred hashing/transcription, not for promising continued capture after the audio session is gone.

Estimate remaining recording capacity before and during recording. Stop early with a clear warning before filesystem write failure; still handle `ENOSPC`, protection/unavailable-volume errors, and audio encoder errors. The original file is the priority: suspend derived jobs first and reserve capacity rather than sacrificing source capture.

## Future video/image

Capture with AVFoundation/Photos import into staging, hash via streaming read, move atomically, then commit metadata. Generate thumbnails/waveforms only under `Derived`. Imports copy into the package by default so availability and integrity do not depend on an external provider.

## References

- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Audio input node](https://developer.apple.com/documentation/avfaudio/avaudioengine/inputnode)
- [Installing an audio tap](https://developer.apple.com/documentation/avfaudio/avaudionode/installtap(onbus:buffersize:format:block:))
- [Audio-session interruptions](https://developer.apple.com/documentation/avfaudio/responding-to-audio-session-interruptions)
