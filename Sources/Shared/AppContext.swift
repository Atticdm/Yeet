import Foundation
import Combine

/// Global observable state shared between app & widgets/extensions where needed.
@MainActor
final class AppContext: ObservableObject {
    static let shared = AppContext()

    @Published var pendingShareURL: URL?

    private init() {}

    func presentShare(url: URL) {
        pendingShareURL = url
    }
}
