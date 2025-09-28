import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appContext: AppContext
    @State private var pendingShareItem: ShareSheetItem?
    @State private var showLoginView = false
    @State private var loggedInServices: [String] = []

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

                    Section(header: Text("Manage Accounts")) {
                        ForEach(AppConfig.supportedServices, id: \.self) { service in
                            AccountRow(
                                service: service,
                                isLoggedIn: loggedInServices.contains(service),
                                onLogin: { showLoginView = true },
                                onLogout: { logoutService(service) }
                            )
                        }
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
        .sheet(isPresented: $showLoginView) {
            LoginView { cookies in
                showLoginView = false
                refreshLoggedInServices()
            }
        }
        .onAppear {
            refreshLoggedInServices()
        }
    }
    
    private func refreshLoggedInServices() {
        loggedInServices = KeychainService.shared.listServices()
    }
    
    private func logoutService(_ service: String) {
        do {
            try KeychainService.shared.deleteCookies(for: service)
            refreshLoggedInServices()
        } catch {
            // Handle error silently for now
            print("Failed to logout from \(service): \(error)")
        }
    }
}

private struct ShareSheetItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct AccountRow: View {
    let service: String
    let isLoggedIn: Bool
    let onLogin: () -> Void
    let onLogout: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: serviceIcon)
                .foregroundColor(serviceColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceName)
                    .font(.headline)
                Text(isLoggedIn ? "Logged in" : "Not logged in")
                    .font(.caption)
                    .foregroundColor(isLoggedIn ? .green : .secondary)
            }
            
            Spacer()
            
            if isLoggedIn {
                Button("Logout") {
                    onLogout()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else {
                Button("Login") {
                    onLogin()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var serviceName: String {
        switch service {
        case "instagram": return "Instagram"
        case "youtube": return "YouTube"
        case "tiktok": return "TikTok"
        default: return service.capitalized
        }
    }
    
    private var serviceIcon: String {
        switch service {
        case "instagram": return "camera"
        case "youtube": return "play.rectangle"
        case "tiktok": return "music.note"
        default: return "person.circle"
        }
    }
    
    private var serviceColor: Color {
        switch service {
        case "instagram": return .pink
        case "youtube": return .red
        case "tiktok": return .black
        default: return .blue
        }
    }
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
