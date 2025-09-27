import Foundation
import UserNotifications

/// Coordinates large downloads shared between the extension and the host app using a background `URLSession`.
final class BackgroundDownloadManager: NSObject {
    static let shared = BackgroundDownloadManager()

    struct NotificationNames {
        static let downloadCompleted = Notification.Name("com.atticdm.Yeet.downloadCompleted")
    }

    private let storage = BackgroundDownloadStorage()
    private var appSession: URLSession?
    private var backgroundCompletionHandlers: [String: () -> Void] = [:]

    private override init() {}

    // MARK: App configuration

    func configureForApp() {
        appSession = URLSession(configuration: backgroundConfiguration(), delegate: self, delegateQueue: nil)
    }

    func handleEvents(for identifier: String, completionHandler: @escaping () -> Void) {
        backgroundCompletionHandlers[identifier] = completionHandler
        appSession = URLSession(configuration: backgroundConfiguration(), delegate: self, delegateQueue: nil)
    }

    // MARK: Scheduling

    @discardableResult
    func scheduleBackgroundDownload(metadata: VideoMetadata, originalURL: URL) async throws -> UUID {
        let record = BackgroundDownloadRecord(metadata: metadata, originalURL: originalURL)
        try storage.save(record: record)

        let session = URLSession(configuration: backgroundConfiguration(), delegate: nil, delegateQueue: nil)
        let task = session.downloadTask(with: metadata.downloadUrl)
        task.taskDescription = record.id.uuidString
        task.resume()
        session.finishTasksAndInvalidate()
        return record.id
    }

    func completedFileURL(for id: UUID) -> URL? {
        storage.completedFileURL(for: id)
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString) else { return }
        do {
            let finalURL = try storage.persistDownloadedFile(at: location, for: id)
            scheduleNotification(for: id)
            NotificationCenter.default.post(name: NotificationNames.downloadCompleted, object: nil, userInfo: ["id": id, "url": finalURL])
        } catch {
            storage.markFailed(id: id, error: error.localizedDescription)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let desc = task.taskDescription, let id = UUID(uuidString: desc), let error {
            storage.markFailed(id: id, error: error.localizedDescription)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let identifier = session.configuration.identifier, let handler = backgroundCompletionHandlers.removeValue(forKey: identifier) else { return }
        handler()
    }
}

// MARK: - Helpers

private extension BackgroundDownloadManager {
    func backgroundConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.background(withIdentifier: AppConfig.backgroundSessionIdentifier)
        config.sharedContainerIdentifier = AppConfig.appGroupIdentifier
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return config
    }

    func scheduleNotification(for id: UUID) {
        guard let record = storage.record(for: id) else { return }
        NotificationManager.shared.scheduleDownloadReadyNotification(for: record)
    }
}

// MARK: - Storage

struct BackgroundDownloadRecord: Codable {
    enum Status: Codable {
        case scheduled
        case completed(relativePath: String)
        case failed(message: String)
    }

    let id: UUID
    let metadata: VideoMetadata
    let originalURL: URL
    var status: Status
    let scheduledAt: Date

    init(id: UUID = UUID(), metadata: VideoMetadata, originalURL: URL, status: Status = .scheduled, scheduledAt: Date = Date()) {
        self.id = id
        self.metadata = metadata
        self.originalURL = originalURL
        self.status = status
        self.scheduledAt = scheduledAt
    }
}

private final class BackgroundDownloadStorage {
    private let defaults: UserDefaults?
    private let directory: URL?

    init() {
        defaults = UserDefaults(suiteName: AppConfig.appGroupIdentifier)
        directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupIdentifier)?.appendingPathComponent("Downloads", isDirectory: true)
        if let directory, !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private var recordsKey: String { "BackgroundDownloadRecords" }

    func save(record: BackgroundDownloadRecord) throws {
        var all = loadAll()
        all[record.id] = record
        try persist(all: all)
    }

    func record(for id: UUID) -> BackgroundDownloadRecord? {
        loadAll()[id]
    }

    func completedFileURL(for id: UUID) -> URL? {
        guard let record = loadAll()[id] else { return nil }
        if case .completed(let relativePath) = record.status, let directory {
            return directory.appendingPathComponent(relativePath)
        }
        return nil
    }

    func persistDownloadedFile(at location: URL, for id: UUID) throws -> URL {
        guard var record = loadAll()[id], let directory else { throw VideoDownloaderError.failedToPrepareFile }
        let fileExtension = record.metadata.downloadUrl.pathExtension.isEmpty ? "mp4" : record.metadata.downloadUrl.pathExtension
        let filename = "\(id.uuidString).\(fileExtension)"
        let destination = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: location, to: destination)
        record.status = .completed(relativePath: filename)
        try persistUpdated(record)
        return destination
    }

    func markFailed(id: UUID, error: String) {
        guard var record = loadAll()[id] else { return }
        record.status = .failed(message: error)
        try? persistUpdated(record)
    }

    private func persistUpdated(_ record: BackgroundDownloadRecord) throws {
        var all = loadAll()
        all[record.id] = record
        try persist(all: all)
    }

    private func loadAll() -> [UUID: BackgroundDownloadRecord] {
        guard let defaults, let data = defaults.data(forKey: recordsKey) else { return [:] }
        return (try? JSONDecoder().decode([UUID: BackgroundDownloadRecord].self, from: data)) ?? [:]
    }

    private func persist(all: [UUID: BackgroundDownloadRecord]) throws {
        guard let defaults else { throw VideoDownloaderError.failedToPrepareFile }
        let data = try JSONEncoder().encode(all)
        defaults.set(data, forKey: recordsKey)
    }
}
