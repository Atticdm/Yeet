import SwiftUI

struct ShareView: View {
    @ObservedObject var viewModel: DownloaderViewModel

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
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            case .fetchingLink, .idle:
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
            default:
                EmptyView()
            }
        }
        .animation(.default, value: viewModel.state)
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.canPromptWait || viewModel.canPromptNotify {
                HStack(spacing: 12) {
                    Button(action: { viewModel.userChoseWait() }) {
                        Text("Wait")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button(action: { viewModel.userChoseNotify() }) {
                        Text("Notify When Ready")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if viewModel.showCancelButton {
                Button(role: .cancel) { viewModel.cancel() } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
            }

            if viewModel.isError {
                Button("Close") { viewModel.dismissAfterError() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .overlay(Image(systemName: "film.stack").foregroundColor(.secondary))
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
