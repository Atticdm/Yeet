import Foundation

enum VideoDownloaderError: LocalizedError {
    case invalidConfiguration
    case invalidURL
    case backendError(String)
    case invalidResponse
    case downloadFailed
    case failedToPrepareFile

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Backend configuration missing"
        case .invalidURL: return "Invalid URL"
        case .backendError(let message): return message
        case .invalidResponse: return "Invalid backend response"
        case .downloadFailed: return "Download failed"
        case .failedToPrepareFile: return "Could not prepare downloaded file"
        }
    }
}

struct VideoMetadata: Codable, Hashable {
    let downloadUrl: URL
    let title: String
    let fileSize: Int?
    let duration: Int?
    let thumbnail: URL?

    enum CodingKeys: String, CodingKey {
        case downloadUrl
        case title
        case fileSize
        case duration
        case thumbnail
    }
}

struct ProgressSnapshot: Equatable {
    let receivedBytes: Int64
    let expectedBytes: Int64

    var fractionCompleted: Double {
        guard expectedBytes > 0 else { return 0 }
        return min(1, max(0, Double(receivedBytes) / Double(expectedBytes)))
    }
}

actor VideoDownloader {
    private let session: URLSession
    private let fm = FileManager.default
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func fetchMetadata(for url: URL, cookies: [String: String] = [:]) async throws -> VideoMetadata {
        guard let base = AppConfig.backendBaseURL else { throw VideoDownloaderError.invalidConfiguration }
        let endpoint = base.appendingPathComponent(AppConfig.metadataPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")), isDirectory: false)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request payload with optional cookies
        let requestPayload = MetadataRequest(url: url.absoluteString, userCookiesJson: cookies.isEmpty ? nil : cookies)
        let payload = try encoder.encode(requestPayload)
        request.httpBody = payload

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VideoDownloaderError.invalidResponse }

        if http.statusCode == 200 {
            let metadata = try decoder.decode(VideoMetadata.self, from: data)
            return metadata
        }

        if let backendError = try? decoder.decode(BackendError.self, from: data) {
            // Include error code in the error message for better error handling
            let errorMessage = backendError.errorCode != nil ? 
                "\(backendError.error) (\(backendError.errorCode!))" : 
                backendError.error
            throw VideoDownloaderError.backendError(errorMessage)
        }
        throw VideoDownloaderError.invalidResponse
    }

    func downloadVideo(using metadata: VideoMetadata, progress progressHandler: @escaping (ProgressSnapshot) -> Void) async throws -> URL {
        let expectedBytes = metadata.fileSize.map { Int64($0) } ?? NSURLSessionTransferSizeUnknown
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = DownloadDelegate(
                expectedBytes: expectedBytes, 
                progressHandler: progressHandler,
                onFinish: { [weak self] (tempURL: URL) in
                    Task {
                        do {
                            let dest = try self?.persistDownloadedFile(from: tempURL, metadata: metadata)
                            progressHandler(ProgressSnapshot(receivedBytes: Int64(metadata.fileSize ?? 0), expectedBytes: Int64(metadata.fileSize ?? 0)))
                            continuation.resume(returning: dest ?? tempURL)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                },
                onFailure: { error in
                    continuation.resume(throwing: error ?? VideoDownloaderError.downloadFailed)
                }
            )
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            let task = session.downloadTask(with: metadata.downloadUrl)
            task.resume()
        }
    }

    func cleanup(file url: URL?) {
        guard let url else { return }
        try? fm.removeItem(at: url)
    }

    private func persistDownloadedFile(from tempURL: URL, metadata: VideoMetadata) throws -> URL {
        let caches = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let yeetCache = caches.appendingPathComponent("YeetTemp", isDirectory: true)
        try? fm.createDirectory(at: yeetCache, withIntermediateDirectories: true)

        let sanitized = sanitizeFileName(metadata.title.isEmpty ? tempURL.lastPathComponent : metadata.title)
        let sanitizedNSString = sanitized as NSString
        let ext = sanitizedNSString.pathExtension.isEmpty ? "mp4" : sanitizedNSString.pathExtension
        let baseRaw = sanitizedNSString.deletingPathExtension
        let base = baseRaw.isEmpty ? UUID().uuidString : baseRaw
        let destURL = yeetCache.appendingPathComponent("\(base).\(ext)")
        try? fm.removeItem(at: destURL)
        do {
            try fm.moveItem(at: tempURL, to: destURL)
            return destURL
        } catch {
            throw VideoDownloaderError.failedToPrepareFile
        }
    }
}

private extension VideoDownloader {
    struct MetadataRequest: Codable { 
        let url: String
        let userCookiesJson: [String: String]?
    }
    struct BackendError: Codable { 
        let error: String
        let errorCode: String?
    }

    func sanitizeFileName(_ name: String) -> String {
        let trimmed = name.components(separatedBy: "?").first ?? name
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|#%")
        let collapsed = trimmed.components(separatedBy: invalid).joined(separator: "-")
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @preconcurrency
    final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        private let expectedBytes: Int64
        private let progressHandler: (ProgressSnapshot) -> Void
        private let onFinish: ((URL) -> Void)?
        private let onFailure: ((Error?) -> Void)?

        init(expectedBytes: Int64, progressHandler: @escaping (ProgressSnapshot) -> Void, onFinish: ((URL) -> Void)? = nil, onFailure: ((Error?) -> Void)? = nil) {
            self.expectedBytes = expectedBytes
            self.progressHandler = progressHandler
            self.onFinish = onFinish
            self.onFailure = onFailure
        }

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            onFinish?(location)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error { onFailure?(error) }
        }

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            let expected = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : (expectedBytes > 0 ? expectedBytes : -1)
            if expected > 0 {
                progressHandler(ProgressSnapshot(receivedBytes: totalBytesWritten, expectedBytes: expected))
            }
        }
    }
}
