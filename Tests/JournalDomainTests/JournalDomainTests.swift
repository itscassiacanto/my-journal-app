import Foundation
import Testing
@testable import JournalDomain

@Test func mediaAssetRetainsSourceReferenceNotPayload() {
    let entryID = UUID()
    let asset = MediaAsset(entryID: entryID, kind: .audio, relativePath: "Media/asset/source.m4a", uti: "public.mpeg-4-audio", lifecycle: .recording)
    #expect(asset.entryID == entryID)
    #expect(asset.relativePath.hasPrefix("Media/"))
    #expect(asset.byteCount == 0)
}
