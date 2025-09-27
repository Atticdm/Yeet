import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appContext: AppContext
    @State private var pendingShareItem: ShareSheetItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Welcome to Yeet")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Enable the Yeet Share Extension to forward videos in one tap: Share → Yeet → choose WhatsApp/Telegram → pick a contact.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                List {
                    Section(header: Text("Enable Yeet")) {
                        Label("Open the Share sheet", systemImage: "square.and.arrow.up")
                        Label("Scroll to the end → More", systemImage: "ellipsis.circle")
                        Label("Tap Edit → enable Yeet", systemImage: "checkmark.circle")
                    }

                    Section(header: Text("Daily flow")) {
                        Label("Share a video link", systemImage: "video")
                        Label("Choose Yeet", systemImage: "apps.iphone")
                        Label("Wait while we download", systemImage: "arrow.down.circle")
                        Label("Pick WhatsApp/Telegram contact", systemImage: "paperplane")
                    }
                }
                .listStyle(.insetGrouped)

                Spacer()
            }
            .padding()
            .navigationTitle("Yeet")
        }
        .onChange(of: appContext.pendingShareURL) { url in
            pendingShareItem = url.map { ShareSheetItem(url: $0) }
        }
        .sheet(item: $pendingShareItem) { item in
            ActivityViewController(activityItems: [item.url]) { _, _, _, _ in
                appContext.pendingShareURL = nil
            }
        }
    }
}

private struct ShareSheetItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let completion: UIActivityViewController.CompletionWithItemsHandler?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = completion
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
