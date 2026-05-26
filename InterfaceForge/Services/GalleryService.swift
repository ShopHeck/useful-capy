import Foundation
import CloudKit

/// Community gallery: uses CloudKit public database so users can share, browse,
/// and fork designs from other InterfaceForge users.
@MainActor
final class GalleryService: ObservableObject {
    @Published var galleryItems: [GalleryItem] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "GalleryEntry"

    init(containerID: String = "iCloud.com.capy.interfaceforge") {
        container = CKContainer(identifier: containerID)
        database = container.publicCloudDatabase
    }

    // MARK: - Fetch gallery

    func fetchGallery(sortBy: GallerySortOrder = .recent, limit: Int = 50) async {
        isLoading = true
        loadError = nil

        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        switch sortBy {
        case .recent:
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .popular:
            query.sortDescriptors = [NSSortDescriptor(key: "forkCount", ascending: false)]
        }

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: limit)
            galleryItems = results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return GalleryItem(from: record)
            }
            isLoading = false
        } catch {
            loadError = "Couldn't load gallery: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Share to gallery

    func share(design: GeneratedDesign, authorName: String) async -> Bool {
        let record = CKRecord(recordType: recordType)
        record["prompt"] = design.prompt as CKRecordValue
        record["headline"] = design.headline as CKRecordValue
        record["subheadline"] = design.subheadline as CKRecordValue
        record["templateID"] = design.template.id as CKRecordValue
        record["templateTitle"] = design.template.title as CKRecordValue
        record["theme"] = design.configuration.theme.rawValue as CKRecordValue
        record["visualStyle"] = design.configuration.visualStyle.rawValue as CKRecordValue
        record["outputType"] = design.configuration.outputType.rawValue as CKRecordValue
        record["authorName"] = authorName as CKRecordValue
        record["forkCount"] = 0 as CKRecordValue

        if let data = try? JSONEncoder().encode(design) {
            record["designJSON"] = data as CKRecordValue
        }

        do {
            _ = try await database.save(record)
            return true
        } catch {
            loadError = "Share failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Fork (increment counter)

    func incrementForkCount(item: GalleryItem) async {
        let recordID = CKRecord.ID(recordName: item.recordName)
        do {
            let record = try await database.record(for: recordID)
            let current = record["forkCount"] as? Int ?? 0
            record["forkCount"] = (current + 1) as CKRecordValue
            _ = try await database.save(record)
        } catch {
            // Non-critical
        }
    }
}

// MARK: - Models

enum GallerySortOrder: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case popular = "Popular"
    var id: String { rawValue }
}

struct GalleryItem: Identifiable {
    let id: UUID
    let recordName: String
    let prompt: String
    let headline: String
    let templateTitle: String
    let theme: String
    let authorName: String
    let forkCount: Int
    let createdAt: Date
    let design: GeneratedDesign?

    init?(from record: CKRecord) {
        guard let prompt = record["prompt"] as? String,
              let headline = record["headline"] as? String else { return nil }

        self.id = UUID()
        self.recordName = record.recordID.recordName
        self.prompt = prompt
        self.headline = headline
        self.templateTitle = record["templateTitle"] as? String ?? "Component"
        self.theme = record["theme"] as? String ?? "Aurora"
        self.authorName = record["authorName"] as? String ?? "Anonymous"
        self.forkCount = record["forkCount"] as? Int ?? 0
        self.createdAt = record.creationDate ?? Date()

        if let data = record["designJSON"] as? Data,
           let decoded = try? JSONDecoder().decode(GeneratedDesign.self, from: data) {
            self.design = decoded
        } else {
            self.design = nil
        }
    }
}
