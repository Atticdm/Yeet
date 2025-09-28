import SwiftUI

struct ShareView: View {
    @ObservedObject var viewModel: DownloaderViewModel
    @State private var showLoginView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            statusSection
            actionSection
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task { viewModel.startProcessingIfNeeded() }
        .sheet(item: $viewModel.activityItem) { item in
            ActivityViewController(activityItems: [item.url]) { _, completed, _, _ in
                viewModel.activityCompleted(completed)
            }
        }
        .sheet(isPresented: $showLoginView) {
            LoginView { cookies in
                showLoginView = false
                viewModel.retry(with: cookies)
            }
        }
        .onChange(of: viewModel.state) { newState in
            handleStateChange(newState)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            if let thumbnail = viewModel.thumbnailURL {
                AsyncImage(url: thumbnail) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderThumbnail
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderThumbnail
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                placeholderThumbnail
                    .frame(width: 64, height: 64)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(viewModel.statusLine)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Group {
            switch viewModel.state {
            case .downloading:
                if let fraction = viewModel.progressFraction {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity.combined(with: .scale))
                }
            case .fetchingLink, .idle:
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity.combined(with: .scale))
            case .loginRequired:
                HStack(spacing: 8) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.orange)
                    Text("Login required for this content")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale))
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.state)
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.canPromptWait || viewModel.canPromptNotify {
                HStack(spacing: 12) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.5)) {
                            viewModel.userChoseWait() 
                        }
                    }) {
                        Text("Wait")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: { 
                        withAnimation(.spring(response: 0.5)) {
                            viewModel.userChoseNotify() 
                        }
                    }) {
                        Text("Notify When Ready")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if viewModel.showCancelButton {
                Button(role: .cancel) { 
                    withAnimation(.spring(response: 0.5)) {
                        viewModel.cancel() 
                    }
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if viewModel.isError {
                errorView
                    .transition(.opacity.combined(with: .scale))
            }
            
            if case .loginRequired = viewModel.state {
                loginRequiredView
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.state)
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .overlay(Image(systemName: "film.stack").foregroundColor(.secondary))
    }
    
    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Something went wrong")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button("Retry") {
                    withAnimation(.spring(response: 0.5)) {
                        viewModel.retry()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("Close") {
                    withAnimation(.spring(response: 0.5)) {
                        viewModel.dismissAfterError()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    @ViewBuilder
    private var loginRequiredView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Login Required")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text("This content requires authentication. Please log in to continue.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Login") {
                    withAnimation(.spring(response: 0.5)) {
                        showLoginView = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Button("Cancel") {
                    withAnimation(.spring(response: 0.5)) {
                        viewModel.dismissAfterError()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func handleStateChange(_ newState: DownloaderViewModel.State) {
        switch newState {
        case .success:
            // Soft haptic feedback for success
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
        case .error:
            // Heavy haptic feedback for error
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        default:
            break
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

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
