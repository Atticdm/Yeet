import SwiftUI
import WebKit

struct LoginView: View {
    let onLoginComplete: ([String: String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedService = "instagram"
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let services = [
        ("instagram", "Instagram", "https://www.instagram.com/accounts/login/"),
        ("youtube", "YouTube", "https://accounts.google.com/signin"),
        ("tiktok", "TikTok", "https://www.tiktok.com/login")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Service selector
                Picker("Service", selection: $selectedService) {
                    ForEach(services, id: \.0) { service in
                        Text(service.1).tag(service.0)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedService) { _ in
                    // WebView will reload automatically
                }
                
                // WebView
                WebViewWrapper(
                    url: URL(string: services.first { $0.0 == selectedService }?.2 ?? "")!,
                    onLoginComplete: handleLoginComplete,
                    onError: handleError
                )
                .overlay(
                    Group {
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading login page...")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                        }
                    }
                )
            }
            .navigationTitle("Login to Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Login Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleLoginComplete(_ cookies: [String: String]) {
        do {
            try KeychainService.shared.saveCookies(cookies, for: selectedService)
            onLoginComplete(cookies)
        } catch {
            errorMessage = "Failed to save login credentials: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func handleError(_ error: String) {
        errorMessage = error
        showError = true
    }
}

// MARK: - WebView Wrapper

struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    let onLoginComplete: ([String: String]) -> Void
    let onError: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Could add loading state here if needed
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Check if we're on a success page or if cookies indicate successful login
            checkForSuccessfulLogin(webView)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onError("Failed to load page: \(error.localizedDescription)")
        }
        
        private func checkForSuccessfulLogin(_ webView: WKWebView) {
            // Extract cookies from the web view
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                DispatchQueue.main.async {
                    let cookieDict = Dictionary(uniqueKeysWithValues: cookies.map { ($0.name, $0.value) })
                    
                    // Check if we have session cookies (indicating successful login)
                    if self.hasSessionCookies(cookieDict) {
                        self.parent.onLoginComplete(cookieDict)
                    }
                }
            }
        }
        
        private func hasSessionCookies(_ cookies: [String: String]) -> Bool {
            // Look for common session cookie names
            let sessionCookieNames = ["sessionid", "csrftoken", "ds_user_id", "session", "auth_token", "access_token"]
            return sessionCookieNames.contains { cookies.keys.contains($0) }
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView { cookies in
            print("Login completed with cookies: \(cookies)")
        }
    }
}
