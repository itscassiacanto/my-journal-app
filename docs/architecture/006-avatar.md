# ADR 006: Avatar rendering approach

- Status: accepted for a later feature
- Date: 2026-08-16

## Decision

When an avatar is implemented, start with a **data-driven 2D SwiftUI avatar**: layered vector/raster artwork driven by a small state machine (`idle`, `listening`, `thinking`, `unavailable`) and deterministic animation parameters. Use SwiftUI `TimelineView`/animation for breathing and occasional blink/eye movement; drive listening reaction from a smoothed audio level supplied by the recorder. Respect Reduce Motion and provide a static fallback.

No avatar code, assets, SceneKit, SpriteKit, RealityKit, or lip-sync is added in Sprint 0.

## Rationale

The required presence is subtle, not a 3D conversational character. A 2D state machine has the smallest asset/performance/accessibility surface, is native to SwiftUI, scales well across iPhone/iPad/Mac, and does not bind the architecture to a rendering engine. SpriteKit is a credible second step only if the desired art direction needs timeline-based sprite animation unavailable in SwiftUI. SceneKit/RealityKit introduces 3D rigs, rendering, memory, asset-pipeline, and platform-test complexity that does not earn its cost for idle/listening behavior.

Optional future lip-sync should consume local playback/capture amplitude or phoneme/timestamp data from a `AvatarSignalProvider` protocol; it must never influence recording, transcription, or journal data correctness.

## References

- [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview)
- [Accessibility: Reduce Motion](https://developer.apple.com/documentation/swiftui/accessibilityreduce_motion)
