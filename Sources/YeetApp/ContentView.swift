import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Welcome to Yeet")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Enable the Yeet Share Extension to send videos directly from other apps. Share a video → choose Yeet → we prepare the file → choose WhatsApp/Telegram to send.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                List {
                    Section(header: Text("How to use")) {
                        Label("Share a video from Instagram/YouTube", systemImage: "square.and.arrow.up")
                        Label("Select Yeet in the share sheet", systemImage: "apps.iphone")
                        Label("We prepare the file", systemImage: "arrow.down.circle")
                        Label("Share to WhatsApp/Telegram", systemImage: "paperplane")
                    }
                }
                .listStyle(.insetGrouped)

                Spacer()
            }
            .padding()
            .navigationTitle("Yeet")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

