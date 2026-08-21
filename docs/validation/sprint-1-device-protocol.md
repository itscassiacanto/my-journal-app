# Sprint 1 physical-device validation protocol

This document records the tests required before interpreting the foundation spike as a product guarantee. The repository cannot manufacture physical-device measurements; each row must be filled from an instrumented device run and attached to the Sprint 1 issue.

## Recording durability matrix

| Run | Device / OS | Route | Duration | Interruption / fault | Result | Recovery / source hash | Notes |
| --- | --- | --- | ---: | --- | --- | --- | --- |
| R-05 | Pending | Built-in mic | 5 min | None | Pending | Pending | |
| R-30 | Pending | Built-in mic | 30 min | None | Pending | Pending | |
| R-60 | Pending | Built-in mic | 60 min | None | Pending | Pending | |
| R-I1 | Pending | Bluetooth/headphones | 5 min | Phone/Siri/audio interruption | Pending | Pending | |
| R-R1 | Pending | Built-in -> Bluetooth | 5 min | Route change | Pending | Pending | |
| R-S1 | Pending | Built-in mic | 5 min | Capacity admission denied | Pending | N/A | |
| R-S2 | Pending | Built-in mic | Until failure | Near-full filesystem | Pending | Pending | |
| R-T1 | Pending | Built-in mic | 5 min | Force quit / relaunch | Pending | Pending | Platform-dependent; verify retained staging file. |

Pass criteria: the original source file is incrementally written, no complete audio file is loaded into memory, finalized media gets a streamed SHA-256, and interrupted/failed capture retains a discoverable staging file. No automatic resume is expected after interruption or termination.

## Transcription matrix

| Run | Device / OS | Locale | Model state | Source duration | Wall time | Peak memory | Battery/energy/thermal | Offline result | Notes |
| --- | --- | --- | --- | ---: | ---: | ---: | --- | --- | --- |
| T-05 | Pending | en-CA / MVP locale | Installed | 5 min | Pending | Pending | Pending | Pending | |
| T-30 | Pending | en-CA / MVP locale | Installed | 30 min | Pending | Pending | Pending | Pending | |
| T-60 | Pending | en-CA / MVP locale | Installed | 60 min | Pending | Pending | Pending | Pending | |
| T-L1 | Pending | MVP locale | Not installed | N/A | Pending | N/A | N/A | Pending | Validate clear unavailable/install state. |
| T-L2 | Pending | Unsupported locale | N/A | N/A | Pending | N/A | N/A | Pending | No network fallback. |

Record Instruments memory/energy traces and the exact `SpeechTranscriber` capability report. The post-recording path is acceptable only if it completes reliably offline without compromising recording, with measured cost suitable for the intended user expectation. Otherwise update ADR 005 before making transcription an MVP promise.
