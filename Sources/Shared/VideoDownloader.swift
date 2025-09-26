import Foundation

enum VideoDownloaderError: Error {
    case invalidURL
    case downloadFailed
}

actor VideoDownloader {
    private let session: URLSession
    private let fm = FileManager.default

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchDirectDownloadURL(from url: URL) async throws -> URL {
        // TODO: Replace with real backend call (POST /get-video-link)
        // For now: mock by returning the same URL if it's https.
        guard url.scheme?.hasPrefix("http") == true else { throw VideoDownloaderError.invalidURL }
        return url
    }

    func downloadVideo(from url: URL) async throws -> URL {
        let (tempURL, response) = try await session.download(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw VideoDownloaderError.downloadFailed }

        let caches = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let yeetCache = caches.appendingPathComponent("YeetTemp", isDirectory: true)
        try? fm.createDirectory(at: yeetCache, withIntermediateDirectories: true)

        let fileName = UUID().uuidString + ".mp4" // best‑effort; real impl could sniff MIME
        let destURL = yeetCache.appendingPathComponent(fileName)
        try? fm.removeItem(at: destURL)
        try fm.moveItem(at: tempURL, to: destURL)
        return destURL
    }

    func cleanup(file url: URL?) {
        guard let url else { return }
        try? fm.removeItem(at: url)
    }
}

