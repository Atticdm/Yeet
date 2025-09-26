import SwiftUI

struct ShareView: View {
    let status: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(status).foregroundColor(.secondary)
        }
        .padding()
    }
}

