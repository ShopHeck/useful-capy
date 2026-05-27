import Foundation
import CloudKit

/// Lightweight CloudKit sync layer for design history.
/// Uses the user's private iCloud database to sync designs across devices.
/// Falls back gracefully when iCloud is unavailable — the app never blocks on sync.
@MainActor
final class CloudSyncService: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case unavailable(String)
        case error(String)
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "DesignEntry"
    private let zoneID: CKRecordZone.ID

    // Debounce rapid saves
    private var pendingSaveTask: Task<Void, Never>?

    init(containerID: String = "iCloud.com.capy.interfaceforge") {
        container = CKContainer(identifier: containerID)
        database = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: "InterfaceForgeZone", ownerName: CKCurrentUserDefaultName)
    }

    // MARK: - Zone setup

    func ensureZone() async {
        do {
            let zone = CKRecordZone(zoneID: zoneID)
            _ = try await database.save(zone)
        } catch let error as CKError where error.code == .serverRejectedRequest || error.code == .zoneNotFound {
            // Zone already exists or can't be created — both fine
        } catch {
            syncStatus = .unavailable("iCloud zone setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch

    func fetchAll() async -> [DesignCloudRecord] {
        syncStatus = .syncing
        do {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let (results, _) = try await database.records(matching: query, inZoneWith: zoneID, resultsLimit: 100)

            let records: [DesignCloudRecord] = results.compactMap { _, result in
                guard case .success(let record) = result else { return nil }
                return DesignCloudRecord(from: record)
            }

            syncStatus = .synced
            lastSyncDate = Date()
            return records
        } catch let error as CKError where error.code == .networkUnavailable || error.code == .networkFailure {
            syncStatus = .unavailable("No internet connection")
            return []
        } catch let error as CKError where error.code == .notAuthenticated {
            syncStatus = .unavailable("Sign in to iCloud in Settings to enable sync")
            return []
        } catch {
            syncStatus = .error("Sync fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Save

    func save(design: GeneratedDesign) {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // debounce 0.5s
            guard !Task.isCancelled else { return }
            await performSave(design: design)
        }
    }

    private func performSave(design: GeneratedDesign) async {
        let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: design.id.uuidString, zoneID: zoneID))
        record["prompt"] = design.prompt as CKRecordValue
        record["headline"] = design.headline as CKRecordValue
        record["subheadline"] = design.subheadline as CKRecordValue
        record["templateID"] = design.template.id as CKRecordValue
        record["templateTitle"] = design.template.title as CKRecordValue
        record["theme"] = design.configuration.theme.rawValue as CKRecordValue
        record["visualStyle"] = design.configuration.visualStyle.rawValue as CKRecordValue
        record["outputType"] = design.configuration.outputType.rawValue as CKRecordValue
        record["generationMode"] = design.generationMode.rawValue as CKRecordValue
        record["createdAt"] = design.createdAt as CKRecordValue

        // Store full design as JSON data for lossless round-trip
        if let data = try? JSONEncoder().encode(design) {
            record["designJSON"] = data as CKRecordValue
        }

        do {
            _ = try await database.save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Conflict: the server version wins for simplicity
        } catch {
            // Non-critical — local copy is the source of truth
        }
    }

    // MARK: - Delete

    func delete(designID: UUID) async {
        let recordID = CKRecord.ID(recordName: designID.uuidString, zoneID: zoneID)
        do {
            try await database.deleteRecord(withID: recordID)
        } catch {
            // Non-critical
        }
    }

    // MARK: - Account status

    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                return true
            case .noAccount:
                syncStatus = .unavailable("Sign in to iCloud to enable sync")
                return false
            case .restricted:
                syncStatus = .unavailable("iCloud is restricted on this device")
                return false
            default:
                syncStatus = .unavailable("iCloud account status unknown")
                return false
            }
        } catch {
            syncStatus = .unavailable("Could not check iCloud status")
            return false
        }
    }
}

// MARK: - Cloud record DTO

struct DesignCloudRecord: Identifiable {
    let id: UUID
    let prompt: String
    let headline: String
    let templateTitle: String
    let createdAt: Date
    let design: GeneratedDesign?

    init?(from record: CKRecord) {
        guard let prompt = record["prompt"] as? String,
              let headline = record["headline"] as? String else { return nil }

        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.prompt = prompt
        self.headline = headline
        self.templateTitle = record["templateTitle"] as? String ?? "Unknown"
        self.createdAt = record["createdAt"] as? Date ?? record.creationDate ?? Date()

        if let data = record["designJSON"] as? Data,
           let decoded = try? JSONDecoder().decode(GeneratedDesign.self, from: data) {
            self.design = decoded
        } else {
            self.design = nil
        }
    }
}
