import Foundation
import UniformTypeIdentifiers
import os.log

@MainActor
final class DownloaderViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case fetchingLink
        case longDownloadPrompt(VideoMetadata)
        case downloading(VideoMetadata, ProgressSnapshot?)
        case notifying(VideoMetadata)
        case success(VideoMetadata, URL)
        case error(String)
    }

    struct ActivityItem: Identifiable {
        let id = UUID()
        let url: URL
        let metadata: VideoMetadata
    }

    @Published private(set) var state: State = .idle
    @Published var activityItem: ActivityItem?

    private let downloader = VideoDownloader()
    private weak var extensionContext: NSExtensionContext?
    private let logger: Logger
    private var hasStarted = false
    private var sharedURL: URL?

    init(logger: Logger) {
        self.logger = logger
    }

    // MARK: - Entry Points

    func attach(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    func startProcessingIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        Task { await process() }
    }

    func cancel() {
        logger.debug("User cancelled session")
        extensionContext?.cancelRequest(withError: NSError(domain: "com.atticdm.Yeet", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
    }

    func userChoseWait() {
        guard case .longDownloadPrompt(let metadata) = state else { return }
        Task { await runImmediateDownload(using: metadata) }
    }

    func userChoseNotify() {
        guard let sharedURL, case .longDownloadPrompt(let metadata) = state else { return }
        state = .notifying(metadata)

        Task {
            do {
                try await BackgroundDownloadManager.shared.scheduleBackgroundDownload(metadata: metadata, originalURL: sharedURL)
                logger.debug("Scheduled background download")
                // give brief feedback then close extension
                try? await Task.sleep(nanoseconds: 600_000_000)
                extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } catch {
                logger.error("Failed to schedule background download: \(error.localizedDescription, privacy: .public)")
                state = .error("Could not schedule background download")
            }
        }
    }

    func activityCompleted(_ completed: Bool) {
        logger.debug("Share sheet completed: \(completed, privacy: .public)")
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    func dismissAfterError() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // MARK: - Core Flow

    private func process() async {
        state = .fetchingLink
        guard let context = extensionContext else {
            state = .error("Extension context missing")
            return
        }

        guard let incomingURL = await extractSharedURL(from: context) else {
            state = .error("No shareable link found")
            return
        }
        sharedURL = incomingURL
        logger.debug("Processing shared URL: \(incomingURL.absoluteString, privacy: .public)")

        do {
            let metadata = try await downloader.fetchMetadata(for: incomingURL)
            logger.debug("Metadata received: title=\(metadata.title, privacy: .public) size=\(metadata.fileSize ?? -1)")
            if shouldOfferBackgroundDownload(for: metadata) {
                state = .longDownloadPrompt(metadata)
            } else {
                await runImmediateDownload(using: metadata)
            }
        } catch {
            logger.error("Metadata fetch failed: \(error.localizedDescription, privacy: .public)")
            state = .error(error.localizedDescription)
        }
    }

    private func runImmediateDownload(using metadata: VideoMetadata) async {
        state = .downloading(metadata, nil)

        do {
            let fileURL = try await downloader.downloadVideo(using: metadata) { [weak self] snapshot in
                guard let self else { return }
                Task { @MainActor in
                    self.state = .downloading(metadata, snapshot)
                }
            }
            state = .success(metadata, fileURL)
            activityItem = ActivityItem(url: fileURL, metadata: metadata)
        } catch {
            logger.error("Download failed: \(error.localizedDescription, privacy: .public)")
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func shouldOfferBackgroundDownload(for metadata: VideoMetadata) -> Bool {
        guard let size = metadata.fileSize, size > 0 else { return false }
        let estimatedSeconds = Double(size) / AppConfig.assumedAverageThroughput
        return estimatedSeconds >= AppConfig.longDownloadThreshold
    }

    private func extractSharedURL(from context: NSExtensionContext) async -> URL? {
        for item in context.inputItems.compactMap({ $0 as? NSExtensionItem }) {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let url: URL = await loadItem(from: provider, as: UTType.url) {
                    return url
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let text: String = await loadItem(from: provider, as: UTType.plainText),
                   let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return url
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier),
                   let text: String = await loadItem(from: provider, as: UTType.text),
                   let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return url
                }
            }
        }
        return nil
    }

    private func loadItem<T>(from provider: NSItemProvider, as type: UTType) async -> T? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                if let error {
                    self.logger.error("Failed to load item for type \(type.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    continuation.resume(returning: nil)
                    return
                }
                if let value = item as? T {
                    continuation.resume(returning: value)
                    return
                }
                if let data = item as? Data, T.self == String.self, let text = String(data: data, encoding: .utf8) as? T {
                    continuation.resume(returning: text)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
}

// MARK: - Computed UI helpers

extension DownloaderViewModel {
    var title: String {
        switch state {
        case .longDownloadPrompt(let metadata), .downloading(let metadata, _), .success(let metadata, _), .notifying(let metadata):
            return metadata.title
        default:
            return "Preparing…"
        }
    }

    var thumbnailURL: URL? {
        switch state {
        case .longDownloadPrompt(let metadata), .downloading(let metadata, _), .success(let metadata, _), .notifying(let metadata):
            return metadata.thumbnail
        default:
            return nil
        }
    }

    var statusLine: String {
        switch state {
        case .idle: return "Preparing…"
        case .fetchingLink: return "Requesting link…"
        case .longDownloadPrompt: return "Video is large"
        case .downloading(_, let snapshot):
            guard let snapshot else { return "Downloading…" }
            if snapshot.expectedBytes > 0 {
                let received = ByteCountFormatter.string(fromByteCount: snapshot.receivedBytes, countStyle: .file)
                let total = ByteCountFormatter.string(fromByteCount: snapshot.expectedBytes, countStyle: .file)
                let percent = Int(snapshot.fractionCompleted * 100)
                return "Downloading \(received) of \(total) (\(percent)%)"
            }
            return "Downloading…"
        case .notifying: return "We’ll notify you when it’s ready"
        case .success: return "Ready to share"
        case .error(let message): return message
        }
    }

    var showCancelButton: Bool {
        switch state {
        case .downloading, .fetchingLink, .longDownloadPrompt:
            return true
        case .idle, .success, .notifying, .error:
            return false
        }
    }

    var canPromptWait: Bool {
        if case .longDownloadPrompt = state { return true }
        return false
    }

    var canPromptNotify: Bool {
        if case .longDownloadPrompt = state { return true }
        return false
    }

    var progressFraction: Double? {
        if case .downloading(_, let snapshot?) = state {
            return snapshot.fractionCompleted
        }
        return nil
    }

    var isError: Bool {
        if case .error = state { return true }
        return false
    }
}
