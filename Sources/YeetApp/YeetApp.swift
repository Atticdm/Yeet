import SwiftUI

@main
struct YeetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appContext = AppContext.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appContext)
        }
    }
}
