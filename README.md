# My Journal

Private, local-first conversational memory journal for Apple platforms.

## Sprint 1 foundation

Open [MyJournal.xcodeproj](/Users/cassiamaiacanto/Documents/Github/my-journal-app/MyJournal.xcodeproj) in Xcode and run the `MyJournal` iPhone/iPad target. It is a technical foundation—not a finished journal UI.

- `JournalDomain`: portable Journal, Entry, MediaAsset, and Transcript types.
- `JournalPersistence`: Core Data/SQLite metadata store; no source-media BLOBs.
- `JournalMedia`: versioned local journal-package paths, streamed SHA-256, capacity checks, and staged/final media moves.
- `JournalFeatures`: metadata-before-media recording protocol.
- `App/iOS`: small SwiftUI spike UI, AVAudioEngine staged recording, and capability-gated local SpeechTranscriber reporting.

The on-device protocol and pending physical-device result matrix are in [docs/validation/sprint-1-device-protocol.md](/Users/cassiamaiacanto/Documents/Github/my-journal-app/docs/validation/sprint-1-device-protocol.md). Architecture decisions remain indexed in [docs/architecture/README.md](/Users/cassiamaiacanto/Documents/Github/my-journal-app/docs/architecture/README.md).

## Verification

```sh
swift test
xcodebuild -project MyJournal.xcodeproj -scheme MyJournal \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Physical-device recording and transcription measurements are intentionally not represented as completed until they are run and entered in the validation matrix.
