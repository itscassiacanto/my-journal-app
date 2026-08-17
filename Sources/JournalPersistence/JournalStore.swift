import CoreData
import Foundation
import JournalDomain
import JournalMedia

public enum JournalStoreError: Error, Sendable { case journalNotFound, entryNotFound, assetNotFound }

public final class JournalStore: @unchecked Sendable {
    public let container: NSPersistentContainer

    public init(databaseURL: URL, inMemory: Bool = false) throws {
        let model = Self.model()
        container = NSPersistentContainer(name: "JournalMetadata", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: databaseURL)
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        if inMemory { description.url = URL(fileURLWithPath: "/dev/null") }
        container.persistentStoreDescriptions = [description]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
    }

    public func createJournal(_ journal: Journal) throws {
        let item = NSEntityDescription.insertNewObject(forEntityName: "JournalRecord", into: container.viewContext)
        item.setValue(journal.id, forKey: "id"); item.setValue(journal.name, forKey: "name"); item.setValue(journal.createdAt, forKey: "createdAt"); item.setValue(journal.modifiedAt, forKey: "modifiedAt"); item.setValue(journal.formatVersion, forKey: "formatVersion")
        try container.viewContext.save()
    }

    public func createEntry(_ entry: Entry) throws {
        let journal = try object(entity: "JournalRecord", id: entry.journalID)
        let item = NSEntityDescription.insertNewObject(forEntityName: "EntryRecord", into: container.viewContext)
        item.setValue(entry.id, forKey: "id"); item.setValue(entry.authoredText, forKey: "authoredText"); item.setValue(entry.createdAt, forKey: "createdAt"); item.setValue(entry.modifiedAt, forKey: "modifiedAt"); item.setValue(journal, forKey: "journal")
        try container.viewContext.save()
    }

    public func createAsset(_ asset: MediaAsset) throws {
        let entry = try object(entity: "EntryRecord", id: asset.entryID)
        let item = NSEntityDescription.insertNewObject(forEntityName: "MediaAssetRecord", into: container.viewContext)
        item.setValue(asset.id, forKey: "id"); item.setValue(asset.kind.rawValue, forKey: "kind"); item.setValue(asset.relativePath, forKey: "relativePath"); item.setValue(asset.byteCount, forKey: "byteCount"); item.setValue(asset.sha256, forKey: "sha256"); item.setValue(asset.uti, forKey: "uti"); item.setValue(asset.lifecycle.rawValue, forKey: "lifecycle"); item.setValue(asset.createdAt, forKey: "createdAt"); item.setValue(entry, forKey: "entry")
        try container.viewContext.save()
    }

    public func markAssetReady(id: UUID, relativePath: String, byteCount: Int64, sha256: String) throws {
        let item = try object(entity: "MediaAssetRecord", id: id)
        item.setValue(relativePath, forKey: "relativePath"); item.setValue(byteCount, forKey: "byteCount"); item.setValue(sha256, forKey: "sha256"); item.setValue(MediaLifecycle.ready.rawValue, forKey: "lifecycle")
        try container.viewContext.save()
    }

    public func fetchAssets() throws -> [MediaAsset] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MediaAssetRecord")
        return try container.viewContext.fetch(request).compactMap { item in
            guard let id = item.value(forKey: "id") as? UUID, let entry = item.value(forKey: "entry") as? NSManagedObject, let entryID = entry.value(forKey: "id") as? UUID, let kind = MediaKind(rawValue: item.value(forKey: "kind") as? String ?? ""), let path = item.value(forKey: "relativePath") as? String, let uti = item.value(forKey: "uti") as? String, let lifecycle = MediaLifecycle(rawValue: item.value(forKey: "lifecycle") as? String ?? ""), let createdAt = item.value(forKey: "createdAt") as? Date else { return nil }
            return MediaAsset(id: id, entryID: entryID, kind: kind, relativePath: path, byteCount: item.value(forKey: "byteCount") as? Int64 ?? 0, sha256: item.value(forKey: "sha256") as? String, uti: uti, lifecycle: lifecycle, createdAt: createdAt)
        }
    }

    private func object(entity: String, id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: entity); request.fetchLimit = 1; request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let object = try container.viewContext.fetch(request).first else { throw JournalStoreError.assetNotFound }
        return object
    }

    private static func model() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let journal = entity("JournalRecord", attributes: [attribute("id", .UUIDAttributeType), attribute("name", .stringAttributeType), attribute("createdAt", .dateAttributeType), attribute("modifiedAt", .dateAttributeType), attribute("formatVersion", .integer16AttributeType)])
        let entry = entity("EntryRecord", attributes: [attribute("id", .UUIDAttributeType), attribute("authoredText", .stringAttributeType, optional: true), attribute("createdAt", .dateAttributeType), attribute("modifiedAt", .dateAttributeType)])
        let asset = entity("MediaAssetRecord", attributes: [attribute("id", .UUIDAttributeType), attribute("kind", .stringAttributeType), attribute("relativePath", .stringAttributeType), attribute("byteCount", .integer64AttributeType), attribute("sha256", .stringAttributeType, optional: true), attribute("uti", .stringAttributeType), attribute("lifecycle", .stringAttributeType), attribute("createdAt", .dateAttributeType)])
        let transcript = entity("TranscriptRecord", attributes: [attribute("id", .UUIDAttributeType), attribute("sourceSHA256", .stringAttributeType), attribute("localeIdentifier", .stringAttributeType), attribute("engineVersion", .stringAttributeType), attribute("text", .stringAttributeType), attribute("generatedAt", .dateAttributeType)])
        relationship("entries", from: journal, to: entry, inverse: "journal", toMany: true, deleteRule: .cascadeDeleteRule)
        relationship("assets", from: entry, to: asset, inverse: "entry", toMany: true, deleteRule: .nullifyDeleteRule)
        relationship("transcripts", from: asset, to: transcript, inverse: "asset", toMany: true, deleteRule: .cascadeDeleteRule)
        model.entities = [journal, entry, asset, transcript]; return model
    }
    private static func entity(_ name: String, attributes: [NSAttributeDescription]) -> NSEntityDescription { let entity = NSEntityDescription(); entity.name = name; entity.managedObjectClassName = "NSManagedObject"; entity.properties = attributes; return entity }
    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription { let attribute = NSAttributeDescription(); attribute.name = name; attribute.attributeType = type; attribute.isOptional = optional; return attribute }
    private static func relationship(_ name: String, from: NSEntityDescription, to: NSEntityDescription, inverse inverseName: String, toMany: Bool, deleteRule: NSDeleteRule) { let relationship = NSRelationshipDescription(); relationship.name = name; relationship.destinationEntity = to; relationship.minCount = 0; relationship.maxCount = toMany ? 0 : 1; relationship.isOptional = true; relationship.deleteRule = deleteRule; let inverse = NSRelationshipDescription(); inverse.name = inverseName; inverse.destinationEntity = from; inverse.minCount = 0; inverse.maxCount = toMany ? 1 : 0; inverse.isOptional = true; inverse.deleteRule = deleteRule; relationship.inverseRelationship = inverse; inverse.inverseRelationship = relationship; from.properties.append(relationship); to.properties.append(inverse) }
}
