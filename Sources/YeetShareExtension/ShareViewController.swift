import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var downloader = VideoDownloader()
    private var statusText: String = "Preparing your video…"

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = UIHostingController(rootView: ShareView(status: statusText))
        addChild(root)
        root.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root.view)
        NSLayoutConstraint.activate([
            root.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.view.topAnchor.constraint(equalTo: view.topAnchor),
            root.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        root.didMove(toParent: self)

        Task { await self.handleShare() }
    }

    private func extractSharedURL() -> URL? {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else { return nil }
        let attachments = item.attachments ?? []
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                var resultURL: URL?
                let semaphore = DispatchSemaphore(value: 0)
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, _) in
                    defer { semaphore.signal() }
                    if let url = item as? URL { resultURL = url }
                }
                semaphore.wait()
                if let url = resultURL { return url }
            }
        }
        return nil
    }

    @MainActor
    private func presentShareSheet(fileURL: URL) {
        let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            guard let self else { return }
            Task { await self.finishAndCleanup(fileURL: fileURL) }
        }
        self.present(activity, animated: true)
    }

    private func updateStatus(_ text: String) {
        // For minimalism, recreate root VC with new text. In real app, route via state binding.
        for child in children { child.view.removeFromSuperview(); child.removeFromParent() }
        let root = UIHostingController(rootView: ShareView(status: text))
        addChild(root)
        root.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root.view)
        NSLayoutConstraint.activate([
            root.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.view.topAnchor.constraint(equalTo: view.topAnchor),
            root.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        root.didMove(toParent: self)
    }

    private func handleShare() async {
        guard let incomingURL = extractSharedURL() else {
            await finishWithError("No URL found in shared content")
            return
        }
        await MainActor.run { self.updateStatus("Processing link…") }

        do {
            let directURL = try await downloader.fetchDirectDownloadURL(from: incomingURL)
            await MainActor.run { self.updateStatus("Downloading…") }
            let localFile = try await downloader.downloadVideo(from: directURL)
            await MainActor.run { self.presentShareSheet(fileURL: localFile) }
        } catch {
            await finishWithError("Failed: \(error.localizedDescription)")
        }
    }

    private func finishAndCleanup(fileURL: URL?) async {
        await MainActor.run { self.updateStatus("Cleaning up…") }
        await downloader.cleanup(file: fileURL)
        await finish()
    }

    private func finish() async {
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    private func finishWithError(_ message: String) async {
        await MainActor.run { self.updateStatus(message) }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await finish()
    }
}

