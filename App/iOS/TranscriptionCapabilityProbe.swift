import Foundation
import Speech

enum TranscriptionCapabilityProbe {
    static func report() async -> String {
        if #available(iOS 26.0, *) {
            let locales = (await SpeechTranscriber.supportedLocales).map(\.identifier).sorted().joined(separator: ", ")
            let installed = (await SpeechTranscriber.installedLocales).map(\.identifier).sorted().joined(separator: ", ")
            return "SpeechTranscriber available: \(SpeechTranscriber.isAvailable). Installed locales: \(installed.isEmpty ? "none" : installed). Downloadable locales: \(locales.isEmpty ? "none" : locales)."
        }
        return "Modern SpeechTranscriber requires iOS 26 or later. No cloud fallback; transcription remains unavailable on this device until the supported local path is validated."
    }
}
